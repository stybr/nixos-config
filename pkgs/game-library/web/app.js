const STATE_ICONS = { installed: "✔", partial: "⇣", remote: "☁" };
const PAGE_SIZE = 10;
const POLL_MS = 500;
const HIDE_DONE_MS = 3000;  // za jak dlouho schovat lištu po dokončení stahování
const HIDE_ERROR_MS = 5000; // ... a po chybě
const LETTER_MS = 700;      // jak dlouho ukazovat velké písmeno po skoku

const lists = {
  library: document.getElementById("games"),
  detail: document.getElementById("actions"),
};

let games = [];
let view = "library";                       // aktuální obrazovka: "library" | "detail"
const selected = { library: 0, detail: 0 }; // vybraná položka zvlášť pro každou obrazovku
let detailName = null;                      // hra otevřená v detailu
let detailActions = [];                     // položky detailu: { label, run }
let pollTimer = null;                       // běžící polling stahování
let hideTimer = null;                       // naplánované schování lišty stahování
let letterTimer = null;                     // naplánované schování velkého písmena
let polling = false;                        // právě běží dotaz na stav stahování
let lastDownload = null;                    // poslední známý stav stahování z backendu
let downloadQueue = [];                     // jména her ve frontě, v pořadí

const TABS = [
  { id: "installed", label: "Installed", empty: "No installed games", filter: (game) => game.state === "installed" },
  { id: "all", label: "All", empty: "No games found", filter: () => true },
  { id: "downloads", label: "Downloads", empty: "Nothing is downloading",
    filter: (game) => game.state === "partial" || isDownloading(game.name) || downloadQueue.includes(game.name) },
  { id: "system", label: "System", panel: true }, // informační panel místo seznamu her
];
const SYSTEM_POLL_MS = 2000;
const HINTS = {
  library: "✕ Select    L1/R1 Tab    L2/R2 Letter",
  downloads: "✕ Select    L1/R1 Tab    L2/R2 Section",
  detail: "✕ Select    ○ Back    L2/R2 Page",
  panel: "L1/R1 Tab    ↑↓ Scroll",
};

let tab = 0;              // index aktivní záložky v TABS
const tabSelection = {};  // záložka → jméno naposledy vybrané hry
let visibleGames = [];    // hry v aktivní záložce, ve stejném pořadí jako řádky seznamu
let systemTimer = null;   // obnovování záložky System

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) throw new Error(`${url}: ${response.status}`);
  return response.json();
}

// řádek je buď text, nebo dvojice [vlevo, vpravo]
function fillList(list, rows) {
  list.replaceChildren(
    ...rows.map((row) => {
      const item = document.createElement("li");
      for (const text of [row].flat()) {
        const part = document.createElement("span");
        part.textContent = text;
        item.append(part);
      }
      return item;
    }),
  );
}

function formatSize(bytes) {
  if (bytes == null) return "";
  if (bytes < 1e9) return `${Math.round(bytes / 1e6)} MB`;
  if (bytes < 1e12) return `${(bytes / 1e9).toFixed(1)} GB`;
  return `${(bytes / 1e12).toFixed(2)} TB`;
}

// řádky, které jdou vybrat (nadpisy písmen ne)
function itemsOf(name) {
  return lists[name].querySelectorAll(":scope > li:not(.header)");
}

function rowHeightPx() {
  return parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--row-height"));
}

// rozměry pro zarovnávání: všechny řádky mají stejnou výšku (--row-height)
function metrics(name) {
  const rowHeight = rowHeightPx();
  return {
    container: lists[name].closest("section"),
    rowHeight,
    listTop: lists[name].offsetTop,
    sticky: lists[name].querySelector(".header") ? rowHeight : 0, // přilepený nadpis = jeden řádek
  };
}

// Posune seznam tak, aby byl řádek celý vidět a nahoře (pod přilepeným nadpisem
// písmene) začínal vždy celý řádek. Stačí posouvat o násobky výšky řádku.
function scrollToItem(item, name, block) {
  const { container, rowHeight, listTop, sticky } = metrics(name);
  const itemTop = item.offsetTop;
  const itemBottom = itemTop + rowHeight;
  let top = container.scrollTop;
  if (block === "start" || itemTop < top + sticky) {
    top = itemTop - sticky; // řádek hned pod nadpis
  } else if (itemBottom > top + container.clientHeight) {
    // řádek vyjel dolů: posunout tak, aby byl vidět, a zaokrouhlit nahoru na celé řádky
    const needed = itemBottom - container.clientHeight;
    const rows = Math.ceil((needed + sticky - listTop) / rowHeight);
    top = listTop + rows * rowHeight - sticky;
  } else {
    return; // řádek je celý vidět, nehýbat
  }
  applyScroll(name, top);
}

// nastaví zarovnaný posun; ošetří konec seznamu a nadpis pod nadpisem
function applyScroll(name, top) {
  const { container, rowHeight, listTop, sticky } = metrics(name);
  // u konce seznamu nejde posunout tak daleko: vzít nejbližší zarovnanou pozici před koncem
  const max = container.scrollHeight - container.clientHeight;
  if (top > max) top = listTop + Math.floor((max + sticky - listTop) / rowHeight) * rowHeight - sticky;
  // pod přilepeným nadpisem nesmí být další nadpis (nahoře by viselo písmeno bez her):
  // posunout o řádek dál, ať nadpis sám vyjede nahoru; na konci seznamu o řádek zpět
  if (sticky && top > 0) {
    const under = lists[name].children[Math.round((top + sticky - listTop) / rowHeight)];
    if (under?.classList.contains("header")) top += top + rowHeight <= max ? rowHeight : -rowHeight;
  }
  container.scrollTop = Math.max(0, top);
}

// Výška knihovny na celé řádky: spodní lišta pak nikdy nepůlí název hry.
// Zbytek místa (méně než řádek) zůstane prázdný pod seznamem.
function fitLibrary() {
  const section = document.getElementById("library");
  if (section.hidden) return; // skrytá sekce nemá rozměry; přepočítá se v showView
  const rowHeight = rowHeightPx();
  const available = section.parentElement.getBoundingClientRect().bottom - section.getBoundingClientRect().top;
  section.style.height = `${Math.max(rowHeight, Math.floor(available / rowHeight) * rowHeight)}px`;
  // po změně výšky znovu zarovnat a nechat vybranou hru vidět
  applyScroll("library", Math.round(section.scrollTop / rowHeight) * rowHeight);
  select(selected.library, "library");
}

// block: "nearest" = posunout jen když je potřeba, "start" = dát řádek nahoru
function select(index, name = view, block = "nearest") {
  const items = itemsOf(name);
  if (items.length === 0) return;
  items[selected[name]]?.classList.remove("selected");
  selected[name] = Math.max(0, Math.min(index, items.length - 1));
  items[selected[name]].classList.add("selected");
  scrollToItem(items[selected[name]], name, block);
}

function showView(name) {
  view = name;
  for (const id of Object.keys(lists)) {
    document.getElementById(id).hidden = id !== name;
  }
  document.getElementById("tabs").hidden = name !== "library";
  document.getElementById("hints").textContent = name === "library" ? libraryHints() : HINTS[name];
  if (name === "library") fitLibrary();
  select(selected[name]);
}

function isDownloading(name) {
  return lastDownload?.name === name && ACTIVE_STATES.includes(lastDownload.state);
}

// řádek seznamu: [ikona + název, velikost / průběh stahování / pořadí ve frontě]
function rowFor(game) {
  if (isDownloading(game.name)) {
    const icon = lastDownload.state === "paused" ? "⏸" : "⇣";
    return [`${icon} ${game.name}`, `${lastDownload.percent} %`];
  }
  const queueIndex = downloadQueue.indexOf(game.name);
  if (queueIndex >= 0) return [`⋯ ${game.name}`, `Queued ${queueIndex + 1}`];
  return [`${STATE_ICONS[game.state]} ${game.name}`, formatSize(game.size)];
}

// pořadí v záložce Downloads: stahovaná, pak fronta, pak ostatní nedokončené
function downloadRank(name) {
  if (isDownloading(name)) return -1;
  const queueIndex = downloadQueue.indexOf(name);
  return queueIndex >= 0 ? queueIndex : downloadQueue.length;
}

function renderTabs() {
  const nav = document.getElementById("tabs");
  const downloads = games.filter(TABS[2].filter).length;
  nav.replaceChildren(
    ...[
      ["shoulder", "L1"],
      ...TABS.map((t, i) => [
        i === tab ? "tab active" : "tab",
        t.id === "downloads" && downloads ? `${t.label} (${downloads})` : t.label,
      ]),
      ["shoulder", "R1"],
    ].map(([className, text]) => {
      const span = document.createElement("span");
      span.className = className;
      span.textContent = text;
      return span;
    }),
  );
}

// nápověda tlačítek podle záložky (System nemá výběr, Downloads skáče po skupinách)
function libraryHints() {
  if (TABS[tab].panel) return HINTS.panel;
  return TABS[tab].id === "downloads" ? HINTS.downloads : HINTS.library;
}

// překreslí seznam aktivní záložky a vybere hru podle jména (když v záložce je)
function renderLibrary(preferName) {
  const panel = Boolean(TABS[tab].panel);
  lists.library.hidden = panel;
  document.getElementById("system").hidden = !panel;
  if (view === "library") document.getElementById("hints").textContent = libraryHints();
  if (panel) {
    visibleGames = [];
    renderTabs();
    document.getElementById("empty").hidden = true;
    if (!systemTimer) pollSystem();
    return;
  }
  clearTimeout(systemTimer);
  systemTimer = null;
  visibleGames = games.filter(TABS[tab].filter);
  if (TABS[tab].id === "downloads") {
    // sort je stabilní: hry se stejným pořadím zůstanou abecedně
    visibleGames.sort((a, b) => downloadRank(a.name) - downloadRank(b.name));
  }
  renderTabs();
  fillList(lists.library, visibleGames.map(rowFor));
  addGroupHeaders();
  const empty = document.getElementById("empty");
  empty.hidden = visibleGames.length > 0;
  empty.textContent = TABS[tab].empty;
  const index = visibleGames.findIndex((game) => game.name === preferName);
  selected.library = index >= 0 ? index : Math.min(selected.library, visibleGames.length - 1);
  select(selected.library, "library");
}

async function loadLibrary() {
  const current = visibleGames[selected.library]?.name;
  games = await fetchJson("/api/games");
  renderLibrary(current);
}

function switchTab(delta) {
  tabSelection[TABS[tab].id] = visibleGames[selected.library]?.name;
  tab = (tab + delta + TABS.length) % TABS.length;
  selected.library = 0;
  if (TABS[tab].panel) document.getElementById("library").scrollTop = 0; // panel vždy odshora
  renderLibrary(tabSelection[TABS[tab].id]);
}

// --- záložka System ---

function el(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text != null) element.textContent = text;
  return element;
}

function bar(used, total) {
  const percent = total ? Math.min(100, (used / total) * 100) : 0;
  const outer = el("div", "bar");
  const fill = el("div", percent > 90 ? "fill warn" : "fill"); // nad 90 % oranžově
  fill.style.width = `${percent}%`;
  outer.append(fill);
  return outer;
}

// karta: nadpis a položky v pořadí; položka je řádek [popisek, hodnota],
// {subtitle} = podnadpis, nebo {text, used, total} = souhrn s pruhem
function card(title, items) {
  const box = el("div", "card");
  box.append(el("h2", null, title));
  for (const item of items) {
    if (Array.isArray(item)) {
      const row = el("div", "row");
      row.append(el("span", null, item[0]), el("span", null, item[1] ?? "—"));
      box.append(row);
    } else if (item.subtitle) {
      box.append(el("h3", null, item.subtitle));
    } else {
      box.append(el("div", "summary", item.text), bar(item.used, item.total));
    }
  }
  return box;
}

// sloupec karet pod sebou; poslední karta se natáhne dolů (CSS), sloupce pak končí stejně
function column(...cards) {
  const box = el("div", "column");
  box.append(...cards);
  return box;
}

const unit = (value, suffix) => (value == null ? null : `${value}${suffix}`);

function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  return days ? `${days} d ${hours} h` : hours ? `${hours} h ${minutes} min` : `${minutes} min`;
}

function renderSystem(info) {
  const { storage, system, cpu, gpus, memory, network, launcher } = info;
  const nuc = storage.nuc;
  const nucText = { checking: "checking…", unavailable: "unavailable" }[nuc.status];
  const storageCard = card("Storage", [
    { subtitle: "This PC" },
    { text: `${formatSize(storage.free)} free of ${formatSize(storage.total)}`, used: storage.total - storage.free, total: storage.total },
    ["Games", storage.games_count ? `${formatSize(storage.games)} (${storage.games_count} installed)` : "none"],
    ["Queue", storage.queue_count
      ? `+${formatSize(storage.queue_needed)} for ${storage.queue_count} download${storage.queue_count > 1 ? "s" : ""}`
      : "empty"],
    { subtitle: "NUC" },
    nuc.status === "ok"
      ? { text: `${formatSize(nuc.free)} free of ${formatSize(nuc.total)}`, used: nuc.total - nuc.free, total: nuc.total }
      : ["Storage", nucText],
  ]);
  const networkCard = card("Network", [
    ["Interface", network.interface],
    ["IP", network.ip],
    ["Link", network.wireless ? "Wi-Fi" : unit(network.speed, " Mb/s")],
    ["NUC", nuc.status === "ok" ? "connected" : nucText],
  ]);
  const cpuCard = card("CPU", [
    ["Model", cpu.model],
    ["Usage", unit(cpu.usage, " %") ?? "…"],
    ["Load", `${cpu.load} / ${cpu.cores} threads`],
    ["Temperature", unit(cpu.temp, " °C")],
  ]);
  const gpuCards = gpus.map((gpu) => card("GPU", [
    ["Model", gpu.name],
    ["Driver", gpu.driver],
    ["Usage", unit(gpu.busy, " %")],
    ["VRAM", gpu.vram_total ? `${formatSize(gpu.vram_used)} / ${formatSize(gpu.vram_total)}` : null],
    ["Temperature", unit(gpu.temp, " °C")],
  ]));
  const memoryCard = card("Memory", [
    { text: `${formatSize(memory.used)} used of ${formatSize(memory.total)}`, used: memory.used, total: memory.total },
  ]);
  const systemCard = card("System", [
    ["Hostname", system.hostname],
    ["OS", system.os],
    ["Kernel", system.kernel],
    ["Uptime", formatUptime(system.uptime)],
  ]);
  const launcherCard = card("Launcher", [
    ["Running", launcher.running?.name ?? "nothing"],
    ["Version", launcher.version],
  ]);
  const cards = [
    column(storageCard, networkCard),               // úložiště a síť
    column(cpuCard, ...gpuCards, memoryCard),       // hardware
    column(systemCard, launcherCard),               // systém
  ];
  document.getElementById("system").replaceChildren(...cards);
}

// obnovuje se jen při otevřené záložce System (jinak se nic nenačítá)
async function pollSystem() {
  clearTimeout(systemTimer);
  systemTimer = setTimeout(pollSystem, SYSTEM_POLL_MS);
  try {
    renderSystem(await fetchJson("/api/system"));
  } catch (error) {
    console.error(error);
  }
  if (!TABS[tab].panel || view !== "library") {
    clearTimeout(systemTimer);
    systemTimer = null;
  }
}

// v panelu bez výběru posouvají šipky obsahem
function scrollPanel(direction) {
  document.getElementById("library").scrollBy({ top: direction * 2 * rowHeightPx() });
}

// --- skok podle písmen ---

// skupina řádku: v Downloads podle stavu stahování, jinde počáteční písmeno
function groupOf(game) {
  if (TABS[tab].id !== "downloads") return letterOf(game.name);
  if (isDownloading(game.name)) return "Downloading";
  if (downloadQueue.includes(game.name)) return "Queue";
  return "Incomplete";
}

// před první hru každé skupiny vloží nadpis (A, B, C… nebo Downloading, Queue, Incomplete)
function addGroupHeaders() {
  const items = [...lists.library.children];
  let previous = null;
  visibleGames.forEach((game, i) => {
    const letter = groupOf(game);
    if (letter === previous) return;
    const header = document.createElement("li");
    header.className = "header";
    header.textContent = letter;
    items[i].before(header);
    previous = letter;
  });
}

// počáteční písmeno hry; čísla a ostatní znaky spadnou pod "#"
function letterOf(name) {
  const first = name[0].toUpperCase();
  return /[A-Z]/.test(first) ? first : "#";
}

function showLetter(letter) {
  const box = document.getElementById("letter");
  box.textContent = letter;
  box.classList.toggle("word", letter.length > 1); // celé slovo (QUEUE) menším písmem
  box.hidden = false;
  clearTimeout(letterTimer);
  letterTimer = setTimeout(() => (box.hidden = true), LETTER_MS);
}

// delta +1: první hra dalšího písmena, -1: první hra předchozího písmena
function jumpLetter(delta) {
  if (visibleGames.length === 0) return;
  const letters = visibleGames.map(groupOf);
  const current = letters[selected.library];
  let index;
  if (delta > 0) {
    index = letters.findIndex((letter, i) => i > selected.library && letter !== current);
    if (index < 0) index = selected.library; // už jsme u posledního písmena
  } else {
    let start = selected.library;
    while (start > 0 && letters[start - 1] === current) start--; // začátek aktuálního písmena
    index = start;
    if (start > 0) {                                            // začátek předchozího písmena
      const previous = letters[start - 1];
      index = start - 1;
      while (index > 0 && letters[index - 1] === previous) index--;
    }
  }
  select(index, view, "start"); // nahoru, ať je vidět nadpis písmene
  showLetter(letters[index]);
}

// živé procento: přepíše jen řádek stahované hry, ne celý seznam
function updateDownloadRow() {
  const index = visibleGames.findIndex((game) => game.name === lastDownload?.name);
  if (index < 0) return;
  const [left, right] = rowFor(visibleGames[index]);
  const parts = itemsOf("library")[index].children;
  parts[0].textContent = left;
  parts[1].textContent = right;
}

// --- stahování ---

// stavy, kdy stahování ještě neskončilo (stejné jako ACTIVE_STATES v backendu)
const ACTIVE_STATES = ["running", "paused", "cancelling"];

function renderDownload(status) {
  clearTimeout(hideTimer);
  const bar = document.getElementById("download");
  bar.hidden = !status;
  if (!status) return;
  if (status.state === "done" || status.state === "cancelled") {
    hideTimer = setTimeout(() => renderDownload(null), HIDE_DONE_MS);
  }
  if (status.state === "error") hideTimer = setTimeout(() => renderDownload(null), HIDE_ERROR_MS);
  const queued = downloadQueue.length ? ` · ${downloadQueue.length} queued` : "";
  const texts = {
    running: `Downloading ${status.name}: ${status.percent} % · ${status.speed} · ${status.eta} left${queued}`,
    paused: `Paused ${status.name}: ${status.percent} %${queued}`,
    cancelling: `Cancelling ${status.name}…`,
    cancelled: `Cancelled: ${status.name}`,
    done: `Downloaded: ${status.name}`,
    error: `Error (${status.name}): ${status.error}`,
  };
  document.getElementById("download-text").textContent = texts[status.state];
  document.getElementById("download-progress").value = status.percent ?? 0;
}

async function pollDownload() {
  if (polling) return; // dotaz už běží, další by zdvojil smyčku
  polling = true;
  clearTimeout(pollTimer);
  try {
    const previous = lastDownload;
    const previousQueue = downloadQueue;
    ({ current: lastDownload, queue: downloadQueue } = await fetchJson("/api/download"));
    renderDownload(lastDownload);
    updateDownloadRow();
    if (ACTIVE_STATES.includes(lastDownload?.state)) {
      pollTimer = setTimeout(pollDownload, POLL_MS);
    }
    // změnila se stahovaná hra, její stav nebo fronta → obnovit knihovnu a dotčený detail
    const changed = previous?.name !== lastDownload?.name
      || previous?.state !== lastDownload?.state
      || previousQueue.join("\n") !== downloadQueue.join("\n");
    if (changed) {
      await loadLibrary();
      const affected = [previous?.name, lastDownload?.name, ...previousQueue, ...downloadQueue];
      if (view === "detail" && affected.includes(detailName)) await openDetail(detailName, true);
    }
  } finally {
    polling = false;
  }
}

async function startDownload(name) {
  const response = await fetch(`/api/download?name=${encodeURIComponent(name)}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    renderDownload({ name, state: "error", error });
    return;
  }
  await pollDownload();
}

// remove | up | down | front: úpravy fronty
async function queueAction(action, name) {
  const response = await fetch(`/api/queue/${action}?name=${encodeURIComponent(name)}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    showMessage(`Error: ${error}`);
    return;
  }
  await pollDownload();
}

// pause | resume | cancel aktuálního stahování
async function controlDownload(action) {
  const response = await fetch(`/api/download/${action}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    showMessage(`Error: ${error}`);
    return;
  }
  await pollDownload();
}

// --- hraní ---

function showMessage(text) {
  document.getElementById("message").textContent = text;
}

async function playGame(name, script) {
  const params = new URLSearchParams({ name, script });
  const response = await fetch(`/api/play?${params}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    showMessage(`Error: ${error}`);
    return;
  }
  showMessage(`Running: ${name}`);
}

async function setMangohud(name, enabled) {
  const params = new URLSearchParams({ name, enabled: enabled ? "1" : "0" });
  const response = await fetch(`/api/mangohud?${params}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    showMessage(`Error: ${error}`);
    return;
  }
  await openDetail(name, true); // překreslit popisek On/Off, výběr zůstane na přepínači
}

function confirmDelete(name) {
  document.getElementById("detail-title").textContent = `Delete ${name}?`;
  detailActions = [
    { label: "Cancel", run: () => openDetail(name) },
    { label: "Yes, delete", run: () => deleteGame(name) },
  ];
  fillList(lists.detail, detailActions.map((action) => action.label));
  selected.detail = 0;
  select(0);
}

async function deleteGame(name) {
  const response = await fetch(`/api/delete?name=${encodeURIComponent(name)}`, { method: "POST" });
  if (!response.ok) {
    const { error } = await response.json();
    await openDetail(name);
    showMessage(`Error: ${error}`);
    return;
  }
  await loadLibrary();
  showView("library");
}

// --- detail hry ---

function actionsFor(detail) {
  // tahle hra se právě stahuje → jen ovládání stahování
  if (lastDownload?.name === detail.name && ACTIVE_STATES.includes(lastDownload.state)) {
    if (lastDownload.state === "cancelling") return [];
    const toggle = lastDownload.state === "paused"
      ? { label: "Resume download", run: () => controlDownload("resume") }
      : { label: "Pause download", run: () => controlDownload("pause") };
    return [toggle, { label: "Cancel download", run: () => controlDownload("cancel") }];
  }

  // hra čeká ve frontě → posouvání a vyřazení
  const queueIndex = downloadQueue.indexOf(detail.name);
  if (queueIndex >= 0) {
    const actions = [];
    if (queueIndex > 0) {
      actions.push({ label: "Download next", run: () => queueAction("front", detail.name) });
      actions.push({ label: "Move up", run: () => queueAction("up", detail.name) });
    }
    if (queueIndex < downloadQueue.length - 1) {
      actions.push({ label: "Move down", run: () => queueAction("down", detail.name) });
    }
    actions.push({ label: "Remove from queue", run: () => queueAction("remove", detail.name) });
    return actions;
  }

  const actions = [];
  if (detail.state === "installed") {
    for (const script of detail.scripts) {
      actions.push({ label: script.label, run: () => playGame(detail.name, script.file) });
    }
    actions.push({
      label: `MangoHud: ${detail.mangohud ? "On" : "Off"}`,
      run: () => setMangohud(detail.name, !detail.mangohud),
    });
  } else {
    const busy = ACTIVE_STATES.includes(lastDownload?.state);
    const label = busy ? "Add to queue" : detail.state === "partial" ? "Resume download" : "Download";
    actions.push({ label, run: () => startDownload(detail.name) });
  }
  if (detail.state !== "remote") {
    actions.push({ label: "Delete", run: () => confirmDelete(detail.name) });
  }
  return actions;
}

// keepSelection: po obnovení (např. Move up) zůstat na stejné položce menu
async function openDetail(name, keepSelection = false) {
  const previousIndex = selected.detail;
  const detail = await fetchJson(`/api/game?name=${encodeURIComponent(name)}`);
  detailName = name;
  showMessage("");
  document.getElementById("detail-title").textContent = detail.name;
  detailActions = actionsFor(detail);
  fillList(lists.detail, detailActions.map((action) => action.label));
  selected.detail = keepSelection ? Math.min(previousIndex, detailActions.length - 1) : 0;
  showView("detail");
}

// --- ovládání ---

// repeat: akce z držení tlačítka (ne první stisk)
function handleAction(action, repeat = false) {
  const last = itemsOf(view).length - 1;
  switch (action) {
    case "up":
      if (view === "library" && TABS[tab].panel) scrollPanel(-1);
      // na začátku přeskočit na konec, ale jen samostatným stiskem:
      // při držení se seznam na kraji zastaví a nekrouží dokola
      else if (selected[view] === 0 && !repeat) select(last);
      else select(selected[view] - 1);
      break;
    case "down":
      if (view === "library" && TABS[tab].panel) scrollPanel(+1);
      else if (selected[view] === last && !repeat) select(0); // z konce na začátek
      else select(selected[view] + 1);
      break;
    case "pageUp":   select(selected[view] - PAGE_SIZE); break;
    case "pageDown": select(selected[view] + PAGE_SIZE); break;
    case "top":      select(0); break;
    case "bottom":   select(Infinity); break; // select() to ořízne na poslední položku
    // v detailu nejsou písmena: L2/R2 skáče o stránku
    case "prevLetter": view === "library" ? jumpLetter(-1) : select(selected[view] - PAGE_SIZE); break;
    case "nextLetter": view === "library" ? jumpLetter(+1) : select(selected[view] + PAGE_SIZE); break;
    case "prevTab": if (view === "library") switchTab(-1); break;
    case "nextTab": if (view === "library") switchTab(+1); break;
    case "confirm":
      if (view === "library") {
        const game = visibleGames[selected.library];
        if (game) openDetail(game.name);  // prázdná záložka: nic
      } else {
        detailActions[selected.detail]?.run();
      }
      break;
    case "back":
      if (view === "detail") showView("library");
      break;
  }
}

// klíč je event.key, s Ctrl jako "C-d"
const KEY_ACTIONS = {
  ArrowUp: "up",
  ArrowDown: "down",
  PageUp: "pageUp",
  PageDown: "pageDown",
  Enter: "confirm",
  Escape: "back",
  q: "prevTab",
  e: "nextTab",
  "[": "prevLetter",
  "]": "nextLetter",
  "{": "prevLetter", // vim: skok na předchozí/další odstavec
  "}": "nextLetter",
  // vim
  k: "up",
  j: "down",
  l: "confirm",
  h: "back",
  H: "prevTab",
  L: "nextTab",
  "C-u": "pageUp",
  "C-d": "pageDown",
  g: "top",
  G: "bottom",
};

document.addEventListener("keydown", (event) => {
  const key = event.ctrlKey ? `C-${event.key}` : event.key;
  const action = KEY_ACTIONS[key];
  if (!action) return;
  event.preventDefault();
  handleAction(action, event.repeat); // event.repeat = klávesa se drží
});

// --- ovladač ---

const GAMEPAD_BUTTONS = {
  0: "confirm", 1: "back", 12: "up", 13: "down",
  4: "prevTab", 5: "nextTab", 6: "prevLetter", 7: "nextLetter",
};
const STICK_THRESHOLD = 0.5;
const REPEAT_DELAY_MS = 400;
const REPEAT_INTERVAL_MS = 100;
const REPEATING = new Set(["up", "down", "pageUp", "pageDown", "prevLetter", "nextLetter"]);

const held = new Map(); // držená akce → čas, kdy se má zopakovat

function pressedActions(pad) {
  const actions = new Set();
  for (const [index, action] of Object.entries(GAMEPAD_BUTTONS)) {
    if (pad.buttons[index]?.pressed) actions.add(action);
  }
  const stickY = pad.axes[1] ?? 0;
  if (stickY < -STICK_THRESHOLD) actions.add("up");
  if (stickY > STICK_THRESHOLD) actions.add("down");
  return actions;
}

let focused = false; // false i na začátku: okno se otevírá po hře, ✕ může být ještě držené

function pollGamepads(now) {
  const pressed = new Set();
  for (const pad of navigator.getGamepads()) {
    if (pad) for (const action of pressedActions(pad)) pressed.add(action);
  }

  if (!document.hasFocus()) {
    focused = false; // aktivní je jiné okno (hra): ovladač nepatří nám
  } else if (!focused) {
    // okno se právě vrátilo do popředí: držená tlačítka ignorovat až do puštění
    // (✕ z ukončení hry by jinak hru hned spustilo znovu)
    focused = true;
    for (const action of pressed) held.set(action, Infinity);
  }

  if (focused) {
    // puštěná tlačítka zapomenout
    for (const action of held.keys()) {
      if (!pressed.has(action)) held.delete(action);
    }
    for (const action of pressed) {
      const repeatAt = held.get(action);
      if (repeatAt === undefined) {                 // právě stisknuto
        handleAction(action);
        held.set(action, now + REPEAT_DELAY_MS);
      } else if (REPEATING.has(action) && now >= repeatAt) { // drženo dost dlouho
        handleAction(action, true);
        held.set(action, now + REPEAT_INTERVAL_MS);
      }
    }
  }
  requestAnimationFrame(pollGamepads);
}

// volné místo pro seznam se mění s oknem i s lištou stahování → přepočítat výšku
new ResizeObserver(fitLibrary).observe(document.getElementById("screens"));

await loadLibrary();
showView("library");
pollDownload(); // po F5 navázat na případné běžící stahování
requestAnimationFrame(pollGamepads); // až po načtení knihovny, ať A nesahá do prázdného seznamu
