#!/usr/bin/env python3

"""game-library: backend launcheru pro jc141 hry."""

import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
from collections import deque
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

NUC_DIR = Path("/mnt/games")                     # hry na NUCu (NFS)
LOCAL_DIR = Path.home() / "Games" / "installed"  # stažené hry
PORT = 8765
VERSION = "0.1"
# fronta stahování (včetně právě stahované hry), aby přežila restart backendu
STATE_FILE = Path.home() / ".local" / "state" / "game-library" / "queue.json"
WEB_DIR = Path(__file__).resolve().parent / "web"  # frontend vedle tohoto souboru
CONTENT_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
}
# mountpointy dwarfs, nikdy nekopírovat (při hraní z NUCu je v game-root připojená celá hra)
RSYNC_EXCLUDES = ["/files/game-root/", "/files/.game-root-mnt/", "/files/.game-root-work/"]
# mountpointy jc141, v pořadí odpojování: nejdřív overlay, pak dwarfs pod ním
MOUNTPOINTS = ["files/game-root", "files/.game-root-mnt"]
# řádek průběhu rsync --info=progress2, např. "  1,234,567  12%   45.67MB/s    0:01:23"
PROGRESS_RE = re.compile(r"^\s*[\d,.]+\s+(\d+)%\s+(\S+/s)\s+(\d+:\d{2}:\d{2})")

download = None  # stav aktuálního stahování (dict), nebo None
download_proc = None  # proces rsync aktuálního stahování
download_lock = threading.RLock()  # RLock: funkce se zámkem mohou volat jiné funkce se zámkem
queue = []  # jména her čekajících na stažení (bez právě stahované)
# stavy, kdy stahování ještě neskončilo (nejde spustit další, nejde mazat)
ACTIVE_STATES = {"running", "paused", "cancelling"}
running = None  # spuštěná hra: {"name", "script", "proc"}, nebo None
size_cache = {}  # jméno hry → velikost; game-root.dwarfs se nemění, stačí zjistit jednou


def game_state(name):
    """installed = staženo celé, partial = nedokončené stahování, remote = jen na NUCu."""
    local = LOCAL_DIR / name
    if (local / ".complete").exists():
        return "installed"
    if local.exists():
        return "partial"
    return "remote"


def list_games():
    """Seznam her z NUCu i lokálních, každá se svým stavem."""
    names = set()
    for base in (NUC_DIR, LOCAL_DIR):
        try:
            # scandir zná typ položky přímo z výpisu adresáře, takže se NUCu
            # neptá zvlášť na každou složku (iterdir + is_dir = 120 dotazů po síti)
            names.update(
                entry.name for entry in os.scandir(base)
                if entry.name.endswith("-jc141") and entry.is_dir()
            )
        except OSError:
            pass  # NUC nedostupný nebo lokální složka ještě neexistuje

    names = sorted(names, key=str.lower)
    # velikosti paralelně: každý stat přes NFS čeká na síť, takhle se čeká jen jednou
    with ThreadPoolExecutor(max_workers=32) as pool:
        sizes = list(pool.map(game_size, names))
    settings = load_settings()  # jednou pro celý seznam, ne pro každou hru
    return [
        {"name": name, "state": game_state(name), "size": size, "status": game_status(name, settings)}
        for name, size in zip(names, sizes)
    ]


def valid_name(name):
    """Jen holé jméno složky, žádné cesty jako ../něco."""
    return "/" not in name and not name.startswith(".") and name.endswith("-jc141")


def find_game_dir(name):
    """Složka hry (lokální má přednost), nebo None pro neplatné/neexistující jméno."""
    if not valid_name(name):
        return None
    for base in (LOCAL_DIR, NUC_DIR):
        game_dir = base / name
        if game_dir.is_dir():
            return game_dir
    return None


def script_label(file):
    """Popisek ve výběru skriptu: start.*.sh → "Default", czech.sh → "Czech", td.6.sh → "Td 6"."""
    if file.startswith("start."):
        return "Default"
    label = file.removesuffix(".sh").replace(".", " ")
    return label[:1].upper() + label[1:]


def game_scripts(game_dir):
    """Spustitelné skripty hry; start.*.sh první, actions.sh nikdy."""
    files = sorted(p.name for p in game_dir.glob("*.sh") if p.name != "actions.sh")
    files.sort(key=lambda f: not f.startswith("start."))
    return [{"file": f, "label": script_label(f)} for f in files]


def game_detail(name):
    game_dir = find_game_dir(name)
    if game_dir is None:
        return None
    return {
        "name": name,
        "state": game_state(name),
        "scripts": game_scripts(game_dir),
        "mangohud": mangohud_enabled(name),
        "status": game_status(name),
    }


def dwarfs_size(game_dir):
    """Velikost hry = velikost game-root.dwarfs."""
    return (game_dir / "files" / "game-root.dwarfs").stat().st_size


def game_size(name):
    """Velikost game-root.dwarfs v bajtech (NUC má přednost), nebo None."""
    if name not in size_cache:
        for base in (NUC_DIR, LOCAL_DIR):
            try:
                size_cache[name] = dwarfs_size(base / name)
                break
            except OSError:
                pass
    return size_cache.get(name)  # None se necachuje, příště se zkusí znovu


def download_active():
    return bool(download) and download["state"] in ACTIVE_STATES


def save_queue():
    """Uloží frontu (právě stahovaná hra první) do souboru, ať přežije restart."""
    names = ([download["name"]] if download_active() else []) + queue
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(names))
    tmp.replace(STATE_FILE)  # atomicky: soubor je vždy celý starý, nebo celý nový


# --- nastavení her (MangoHud) ---

SETTINGS_FILE = STATE_FILE.with_name("settings.json")
settings_lock = threading.Lock()  # požadavky běží ve vláknech: číst-změnit-uložit vždy celé najednou


def load_settings():
    try:
        settings = json.loads(SETTINGS_FILE.read_text())
    except (OSError, ValueError):
        return {}  # zatím nic uloženého
    return settings if isinstance(settings, dict) else {}


def save_settings(settings):
    SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = SETTINGS_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(settings, indent=2))
    tmp.replace(SETTINGS_FILE)  # atomicky, stejně jako fronta


def mangohud_enabled(name):
    return name in load_settings().get("mangohud", [])


def store_mangohud(name, enabled):
    """Zapíše volbu MangoHudu pro hru (bez kontrol, používá i mazání hry)."""
    with settings_lock:
        settings = load_settings()
        names = set(settings.get("mangohud", []))
        if enabled:
            names.add(name)
        else:
            names.discard(name)
        settings["mangohud"] = sorted(names)
        save_settings(settings)


def set_mangohud(name, enabled):
    """Zapne/vypne MangoHud pro staženou hru. Vrací None, nebo text chyby."""
    if not valid_name(name) or game_state(name) != "installed":
        return "game is not downloaded"
    store_mangohud(name, enabled)
    return None


STATUSES = ("untested", "works", "issues", "broken")


def game_status(name, settings=None):
    """Jak je hra otestovaná; nic uloženého = untested."""
    settings = load_settings() if settings is None else settings
    statuses = settings.get("status")
    return statuses.get(name, "untested") if isinstance(statuses, dict) else "untested"


def set_status(name, status):
    """Označí hru (i nestaženou). Při smazání hry se stav nemaže: hodí se i po novém stažení."""
    if not valid_name(name) or find_game_dir(name) is None:
        return "game not found"
    if status not in STATUSES:
        return "unknown status"
    with settings_lock:
        settings = load_settings()
        statuses = settings.get("status")
        statuses = statuses if isinstance(statuses, dict) else {}
        if status == "untested":
            statuses.pop(name, None)  # výchozí stav se neukládá
        else:
            statuses[name] = status
        settings["status"] = statuses
        save_settings(settings)
    return None


def load_queue():
    """Po startu backendu obnoví frontu ze souboru a spustí první hru."""
    try:
        names = json.loads(STATE_FILE.read_text())
    except (OSError, ValueError):
        return  # žádná uložená fronta
    with download_lock:
        queue.extend(
            name for name in names
            if valid_name(name) and (NUC_DIR / name).is_dir() and game_state(name) != "installed"
        )
        start_next()


def space_needed():
    """Místo, které ještě potřebuje právě stahovaná hra a celá fronta."""
    needed = sum(game_size(name) or 0 for name in queue)
    if download_active():
        needed += (game_size(download["name"]) or 0) * (100 - download["percent"]) // 100
    return needed


def request_download(name):
    """Stáhne hru hned, nebo ji zařadí do fronty. Vrací None, nebo text chyby."""
    if not valid_name(name) or not (NUC_DIR / name).is_dir():
        return "game not found on NUC"
    with download_lock:
        if download_active() and download["name"] == name:
            return "game is already downloading"
        if name in queue:
            return "game is already queued"
        LOCAL_DIR.mkdir(parents=True, exist_ok=True)
        if space_needed() + (game_size(name) or 0) > shutil.disk_usage(LOCAL_DIR).free:
            return "not enough disk space"
        queue.append(name)
        if not download_active():
            start_next()
        save_queue()
    return None


def start_next():
    """Spustí první hru z fronty, pokud nic neběží."""
    global download
    with download_lock:
        while queue and not download_active():
            name = queue.pop(0)
            src = NUC_DIR / name
            if not src.is_dir():  # mezitím zmizela z NUCu: přeskočit
                download = {"name": name, "state": "error", "percent": 0, "error": "game not found on NUC"}
                continue
            LOCAL_DIR.mkdir(parents=True, exist_ok=True)
            download = {"name": name, "state": "running", "percent": 0, "speed": "", "eta": ""}
            # proces vytvořit hned tady (pod zámkem), ne až ve vlákně:
            # Pause/Cancel hned po spuštění tak vždy najdou správný proces
            proc = spawn_rsync(src, LOCAL_DIR / name)
            threading.Thread(target=run_download, args=(proc, LOCAL_DIR / name), daemon=True).start()
        save_queue()


def queue_remove(name):
    with download_lock:
        if name not in queue:
            return "game is not queued"
        queue.remove(name)
        save_queue()
    return None


def queue_move(name, to):
    """Posune hru ve frontě: to = -1 (nahoru), +1 (dolů), nebo "front" (na začátek)."""
    with download_lock:
        if name not in queue:
            return "game is not queued"
        index = queue.index(name)
        new_index = 0 if to == "front" else max(0, min(index + to, len(queue) - 1))
        queue.insert(new_index, queue.pop(index))
        save_queue()
    return None


def spawn_rsync(src, dst):
    global download_proc
    cmd = [
        "rsync", "--archive", "--partial", "--info=progress2", "--no-inc-recursive",
        # navázat na rozstahovaný soubor (jen dopsat konec) a pak ověřit celý soubor;
        # bez toho rsync u lokálních cest (NFS) kopíruje velký soubor znovu od nuly
        "--append-verify",
        *(f"--exclude={pattern}" for pattern in RSYNC_EXCLUDES),
        f"{src}/", f"{dst}/",
    ]
    # stderr do stdout: jedna roura, nemůže se zaseknout plný buffer druhé
    # process_group=0: rsync (a jeho podprocesy) ve vlastní skupině, signály jdou na všechny
    download_proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, process_group=0,
    )
    return download_proc


def run_download(proc, dst):
    """Ve vlákně: čte průběh rsync, po skončení vyhodnotí výsledek a pustí další z fronty."""
    last_lines = deque(maxlen=5)  # posledních pár řádků, které nejsou průběh = chybová hláška
    for line in proc.stdout:  # textový režim převádí rsyncová \r na konce řádků
        match = PROGRESS_RE.match(line)
        if match:
            download.update(percent=int(match[1]), speed=match[2], eta=match[3])
        elif line.strip():
            last_lines.append(line.strip())
    proc.wait()
    if download["state"] == "cancelling":
        download["state"] = "cancelled"
        error = delete_game(dst.name)  # zrušeno = zahodit rozstahovaná data
        if error:
            download["error"] = error
    elif proc.returncode == 0:
        (dst / ".complete").touch()
        download.update(state="done", percent=100)
    else:
        download.update(state="error", error="\n".join(last_lines))
    start_next()  # pokračovat frontou


def signal_download(*signals):
    """Pošle signály celé skupině procesů rsync (ignoruje, pokud už skončil)."""
    if download_proc is None:
        return
    for sig in signals:
        try:
            os.killpg(download_proc.pid, sig)
        except ProcessLookupError:
            pass


def pause_download():
    if not download or download["state"] != "running":
        return "no download is running"
    signal_download(signal.SIGSTOP)  # zmrazí rsync, data zůstanou rozdělaná
    download["state"] = "paused"
    return None


def resume_download():
    if not download or download["state"] != "paused":
        return "download is not paused"
    signal_download(signal.SIGCONT)
    download["state"] = "running"
    return None


def cancel_download():
    if not download or download["state"] not in ("running", "paused"):
        return "no download is running"
    download["state"] = "cancelling"
    # SIGCONT až po SIGTERM: zmrazený proces signál převezme až po rozmrazení
    signal_download(signal.SIGTERM, signal.SIGCONT)
    return None


def running_game():
    """Hra, která právě běží, nebo None (poll() vrací None, dokud proces žije)."""
    if running and running["proc"].poll() is None:
        return {"name": running["name"], "script": running["script"]}
    return None


# složky s libGL.so.1 (nastavuje default.nix); prázdné při vývoji mimo Nix balík
GL_PATH = os.environ.get("GAME_LIBRARY_GL_PATH", "")

UI_PATTERN = "[g]ame-library/chromium"  # okno launcheru pozná podle --user-data-dir


def close_ui():
    """Zavře okno launcheru, ať hra dostane obrazovku i ovladač."""
    subprocess.run(["pkill", "-f", UI_PATTERN])


def open_ui():
    """Znovu otevře okno launcheru (příkaz games z gaming.nix)."""
    try:
        subprocess.Popen(["games"], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:  # vývoj na notebooku bez příkazu games: nic neotevírat
        pass


def watch_game(proc):
    """Po spuštění hry zavře launcher, po jejím skončení ho zase otevře."""
    time.sleep(0.5)  # nejdřív nechat odejít odpověď na /api/play
    close_ui()
    proc.wait()
    open_ui()


def start_game(name, script):
    """Spustí skript stažené hry. Vrací None, nebo text chyby."""
    global running
    if not valid_name(name) or game_state(name) != "installed":
        return "game is not downloaded"
    game_dir = LOCAL_DIR / name
    if script not in [s["file"] for s in game_scripts(game_dir)]:
        return "unknown script"
    if running_game():
        return "another game is already running"
    cmd = ["bash", script]
    env = os.environ.copy()
    if mangohud_enabled(name):
        # wrapper mangohud: MANGOHUD=1 pro Vulkan (DXVK/VKD3D) + LD_PRELOAD pro OpenGL
        # (nativní hry, WineD3D); procesy bez grafiky (bash, dwarfs) knihovna nechá být
        cmd = ["mangohud", *cmd]
        if GL_PATH:
            # HUD se v OpenGL hrách kreslí přes libGL.so.1 (dlopen podle jména). Hry přes EGL
            # (i Wine) ji samy nenačtou a na NixOS není ve standardní cestě → MangoHud hlásí
            # "Failed to initialize OpenGL context" a hra se zasekne. Stejný libglvnd jako systém.
            old = env.get("LD_LIBRARY_PATH")
            env["LD_LIBRARY_PATH"] = GL_PATH + (f":{old}" if old else "")
    proc = subprocess.Popen(cmd, cwd=game_dir, env=env, start_new_session=True)
    running = {"name": name, "script": script, "proc": proc}
    threading.Thread(target=watch_game, args=(proc,), daemon=True).start()
    return None


def delete_game(name):
    """Smaže lokální kopii hry. Vrací None, nebo text chyby."""
    if not valid_name(name) or not (LOCAL_DIR / name).is_dir():
        return "game is not downloaded"
    game = running_game()
    if game and game["name"] == name:
        return "game is running"
    if download_active() and download["name"] == name:
        return "game is being downloaded"
    if name in queue:  # mazat rozstahovanou hru ve frontě = vyřadit ji i z fronty
        queue_remove(name)

    game_dir = (LOCAL_DIR / name).resolve()
    # pojistka: mazat jen přímou podsložku LOCAL_DIR
    if game_dir.parent != LOCAL_DIR.resolve():
        return "refusing to delete outside of the install directory"

    for mountpoint in MOUNTPOINTS:
        path = game_dir / mountpoint
        if path.is_mount():
            subprocess.run(["fusermount3", "-u", str(path)])
        if path.is_mount():
            return f"could not unmount {mountpoint}"

    try:
        (game_dir / ".complete").unlink(missing_ok=True)  # nejdřív: při chybě zůstane "partial"
        shutil.rmtree(game_dir)
    except OSError as error:
        return f"delete failed: {error}"
    store_mangohud(name, False)  # smazaná hra si nastavení nenechává
    return None


# --- systémové informace (záložka System) ---
# Vše se čte z /proc a /sys: jen pár malých souborů, jednou za 2 s a jen při otevřené záložce.

def read_text(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return None


def read_int(path):
    value = read_text(path)
    return int(value) if value and value.lstrip("-").isdigit() else None


def os_name():
    for line in (read_text("/etc/os-release") or "").splitlines():
        if line.startswith("PRETTY_NAME="):
            return line.split("=", 1)[1].strip('"')
    return None


def cpu_model():
    for line in (read_text("/proc/cpuinfo") or "").splitlines():
        if line.startswith("model name"):
            return line.split(":", 1)[1].strip()
    return None


cpu_previous = None  # poslední (celkem, nečinně) z /proc/stat, využití = rozdíl mezi dotazy


def cpu_usage():
    """Využití CPU v % od minulého dotazu (při prvním dotazu None)."""
    global cpu_previous
    fields = [int(x) for x in (read_text("/proc/stat") or "").splitlines()[0].split()[1:9]]
    total, idle = sum(fields), fields[3] + fields[4]  # idle + iowait
    usage = None
    if cpu_previous and total > cpu_previous[0]:
        usage = round(100 * (1 - (idle - cpu_previous[1]) / (total - cpu_previous[0])))
    cpu_previous = (total, idle)
    return usage


def hwmon_temps():
    """{název senzoru: °C}, např. k10temp/coretemp = CPU, amdgpu = GPU, nvme = disk."""
    temps = {}
    for hwmon in Path("/sys/class/hwmon").glob("hwmon*"):
        name, value = read_text(hwmon / "name"), read_int(hwmon / "temp1_input")
        if name and value is not None:
            temps.setdefault(name, round(value / 1000))
    return temps


gpu_names = {}  # PCI adresa → čitelný název z lspci (nemění se, stačí zjistit jednou)


def gpu_name(slot, device):
    if slot not in gpu_names:
        try:
            out = subprocess.run(["lspci", "-vmm", "-s", slot], capture_output=True, text=True, timeout=5).stdout
            fields = dict(line.split(":\t", 1) for line in out.splitlines() if ":\t" in line)
            gpu_names[slot] = f'{fields["Vendor"]} {fields["Device"]}'
        except (OSError, subprocess.TimeoutExpired, KeyError):
            # bez lspci aspoň PCI ID výrobce:zařízení (necachovat, příště to zkusit znovu)
            return f'PCI {read_text(device / "vendor")}:{read_text(device / "device")}'
    return gpu_names[slot]


def gpus(temps):
    result = []
    for card in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
        if "-" in card.name:  # card1-HDMI-A-1 apod. jsou výstupy, ne karty
            continue
        device = (card / "device").resolve()
        driver = (device / "driver").resolve().name
        vram_used, vram_total = read_int(device / "mem_info_vram_used"), read_int(device / "mem_info_vram_total")
        result.append({
            "name": gpu_name(device.name, device),
            "driver": driver,
            "busy": read_int(device / "gpu_busy_percent"),  # jen amdgpu
            "vram_used": vram_used,
            "vram_total": vram_total,
            "temp": temps.get(driver),  # hwmon senzor se jmenuje po ovladači (amdgpu)
        })
    return result


def memory():
    info = {}
    for line in (read_text("/proc/meminfo") or "").splitlines():
        key, value = line.split(":", 1)
        info[key] = int(value.split()[0]) * 1024  # kB → B
    return {"total": info.get("MemTotal"), "used": info.get("MemTotal", 0) - info.get("MemAvailable", 0)}


def network():
    """Rozhraní s výchozí trasou, jeho IP a rychlost linky."""
    iface = None
    for line in (read_text("/proc/net/route") or "").splitlines()[1:]:
        fields = line.split()
        if fields[1] == "00000000":  # cíl 0.0.0.0 = výchozí trasa
            iface = fields[0]
            break
    ip = None
    try:
        # UDP "connect" nic neposílá, jen zjistí, ze které adresy by se odesílalo
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("10.255.255.255", 1))
            ip = sock.getsockname()[0]
    except OSError:
        pass
    wireless = bool(iface) and Path(f"/sys/class/net/{iface}/wireless").exists()
    speed = read_int(f"/sys/class/net/{iface}/speed") if iface and not wireless else None
    return {"interface": iface, "ip": ip, "wireless": wireless, "speed": speed if speed and speed > 0 else None}


# Místo na NUCu přes NFS: kdyby NUC neodpovídal, statfs na "hard" mountu visí donekonečna.
# Proto ho zjišťuje jedno samostatné vlákno a dotazy berou jen poslední známou hodnotu.
nuc_usage = {"checked": 0, "total": None, "free": None}
nuc_checker = None


def check_nuc():
    while True:
        try:
            usage = shutil.disk_usage(NUC_DIR)
            nuc_usage.update(checked=time.time(), total=usage.total, free=usage.free)
        except OSError:
            pass
        time.sleep(10)


def start_nuc_checker():
    global nuc_checker
    if nuc_checker is None:
        nuc_checker = threading.Thread(target=check_nuc, daemon=True)
        nuc_checker.start()


def nuc_storage():
    start_nuc_checker()
    if nuc_usage["checked"] == 0:
        status = "checking"     # první kontrola ještě neproběhla
    elif time.time() - nuc_usage["checked"] > 30:
        status = "unavailable"  # dlouho bez odpovědi
    else:
        status = "ok"
    return {"status": status, "total": nuc_usage["total"], "free": nuc_usage["free"]}


def system_info():
    temps = hwmon_temps()
    disk = shutil.disk_usage(LOCAL_DIR if LOCAL_DIR.exists() else Path.home())
    installed = []
    try:
        installed = [e.name for e in os.scandir(LOCAL_DIR) if game_state(e.name) == "installed"]
    except OSError:
        pass
    with download_lock:
        queue_needed, queue_count = space_needed(), len(queue) + (1 if download_active() else 0)
    return {
        "storage": {
            "total": disk.total,
            "free": disk.free,
            "games": sum(game_size(name) or 0 for name in installed),
            "games_count": len(installed),
            "queue_needed": queue_needed,
            "queue_count": queue_count,
            "nuc": nuc_storage(),
        },
        "system": {
            "hostname": socket.gethostname(),
            "os": os_name(),
            "kernel": os.uname().release,
            "uptime": float((read_text("/proc/uptime") or "0").split()[0]),
        },
        "cpu": {
            "model": cpu_model(),
            "cores": os.cpu_count(),
            "usage": cpu_usage(),
            "load": round(os.getloadavg()[0], 2),
            "temp": temps.get("k10temp", temps.get("coretemp")),  # AMD / Intel
        },
        "gpus": gpus(temps),
        "memory": memory(),
        "network": network(),
        "launcher": {"version": VERSION, "running": running_game()},
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # nevypisovat každý požadavek (polling by zaplnil terminál)

    def do_GET(self):
        url = urlsplit(self.path)
        if url.path == "/api/games":
            self.send_json(list_games())
        elif url.path == "/api/game":
            name = parse_qs(url.query).get("name", [""])[0]
            detail = game_detail(name)
            if detail is None:
                self.send_error(404)
            else:
                self.send_json(detail)
        elif url.path == "/api/download":
            self.send_json({"current": download, "queue": queue})
        elif url.path == "/api/running":
            self.send_json(running_game())
        elif url.path == "/api/system":
            self.send_json(system_info())
        else:
            self.send_static(url.path)

    def do_POST(self):
        url = urlsplit(self.path)
        query = parse_qs(url.query)
        name = query.get("name", [""])[0]
        actions = {
            "/api/download": lambda: request_download(name),
            "/api/queue/remove": lambda: queue_remove(name),
            "/api/queue/up": lambda: queue_move(name, -1),
            "/api/queue/down": lambda: queue_move(name, +1),
            "/api/queue/front": lambda: queue_move(name, "front"),
            "/api/download/pause": pause_download,
            "/api/download/resume": resume_download,
            "/api/download/cancel": cancel_download,
            "/api/play": lambda: start_game(name, query.get("script", [""])[0]),
            "/api/delete": lambda: delete_game(name),
            "/api/mangohud": lambda: set_mangohud(name, query.get("enabled", [""])[0] == "1"),
            "/api/status": lambda: set_status(name, query.get("status", [""])[0]),
        }
        if url.path not in actions:
            self.send_error(404)
            return
        error = actions[url.path]()
        if error:
            self.send_json({"error": error}, status=409)
        else:
            self.send_json({"ok": True})

    def send_json(self, data, status=200):
        self.send_body(json.dumps(data).encode(), "application/json", status)

    def send_static(self, path):
        name = "index.html" if path == "/" else path.lstrip("/")
        file = (WEB_DIR / name).resolve()
        # pojistka: nikdy neposílat nic mimo složku web/
        if not file.is_relative_to(WEB_DIR) or not file.is_file():
            self.send_error(404)
            return
        content_type = CONTENT_TYPES.get(file.suffix, "application/octet-stream")
        self.send_body(file.read_bytes(), content_type)

    def send_body(self, body, content_type, status=200):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    # port obsadit jako první: běží-li už jiný backend, tenhle tady spadne dřív, než spustí rsync
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    load_queue()  # navázat na frontu z minulého běhu
    start_nuc_checker()  # ať je místo na NUCu známé hned při otevření záložky System
    print(f"game-library: http://127.0.0.1:{PORT}")
    # systemd zastavuje backend signálem SIGTERM; převést na normální ukončení,
    # ať proběhne finally a rozběhnutý rsync se korektně zastaví (nový backend na něj naváže)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        # rsync je ve vlastní skupině, Ctrl+C ho nezasáhne, tak ho ukončit ručně;
        # rozstahovaná data zůstanou a "Resume download" na ně naváže
        if download_proc and download_proc.poll() is None:
            signal_download(signal.SIGTERM, signal.SIGCONT)
