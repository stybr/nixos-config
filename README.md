# nixos-config

## Introduction

- Flake-based, modular NixOS config for my personal infrastructure.
- Managed with [Clan](https://clan.lol).

## Machines

| Machine    | Role            | Status        |
|------------|-----------------|---------------|
| rlw-work   | laptop          | running       |
| rlw-center | HTPC, gaming PC | not installed |
| rlw-nuc    | server, homelab | not installed |

## Layout

- `flake.nix` — inputs, machines and Clan inventory (services like `sshd`)
- `hosts/<machine>/` — machine-specific config (hardware, disko, host-only secret definitions...)
- `modules/` — shared NixOS modules, imported per machine in `flake.nix`
- `home/` — home-manager config for `stybr`
- `sops/` — Clan secret admins (users) and machine age keys
- `vars/` — Clan vars (generated values and encrypted secrets)

## Everyday usage

- `nix flake update --flake ~/nixos-config` — update inputs, then deploy right away
- `clan machines update <machine>` — generate missing vars, build and deploy a machine
- `clan vars list <machine>` — list all vars of a machine
- `clan vars get <machine> <generator>/<file>` — show a var
- `clan vars set <machine> <generator>/<file>` — change a var
- `clan vars generate <machine>` — generate missing vars after adding a generator

## Recovery

- All secrets are encrypted in `vars/` and `sops/`.
- To decrypt them, a valid key in `~/.config/sops/age/keys.txt` is needed.
- Without the key, no secret can be recovered.
