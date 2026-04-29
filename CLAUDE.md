# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS flake configuration for a Framework 13 laptop (12th gen Intel). Single host (`framework-13`), single user (`robert`). Uses an ephemeral root filesystem (tmpfs) with impermanence for persistent state under `/persist`.

Repo: `github.com/DwarfJockey/nixos-config`. The `framework-13` host is tied to specific 12th-gen Intel Framework 13 hardware (disk UUIDs in `hardware-configuration.nix`); cloning to different hardware requires a new host entry.

## Build Commands

```bash
# Build and activate system configuration
sudo nixos-rebuild switch --flake .#framework-13

# Test without making it the boot default
sudo nixos-rebuild test --flake .#framework-13

# Build without activating (dry check)
sudo nixos-rebuild build --flake .#framework-13

# Check flake validity
nix flake check

# Update all flake inputs
nix flake update

# Update a single input
nix flake lock --update-input <input-name>
```

## Architecture

**File layout:**
- `flake.nix` — Entry point. Defines inputs, passes all of them as `specialArgs` to modules.
- `hosts/framework-13/default.nix` — Thin host entry. Imports the modules below plus host-only bits (locale, top-level packages, stateVersion).
- `hosts/framework-13/{hardware-configuration,disko}.nix` — Disk layout, filesystems, kernel modules. Root is tmpfs; `/nix` and `/persist` are Btrfs subvolumes.
- `modules/nixos/{boot,nix,networking,audio,desktop,theming,persistence,apps,users}.nix` — System-level NixOS modules, one concern each.
- `modules/home-manager/{shell,editor,desktop}.nix` — Home Manager modules imported by `home/robert.nix`.
- `home/robert.nix` — Home Manager entry point (persistence, packages, Claude Code settings). Imported as a NixOS module, not standalone.
- `home/wallpapers/` — Source PNGs recolored at build time by `lutgen`.
- `secrets/secrets.nix` + `secrets/*.age` — agenix recipients and encrypted secrets. Decrypted at boot via `/etc/ssh/ssh_host_ed25519_key`.

**Key flake inputs:** nixpkgs (unstable), nixos-hardware, impermanence, home-manager, stylix, nixvim, niri, dms, dms-plugin-registry, nix-monitor, zen-browser, firefox-addons, agenix.

## Key Patterns

**Impermanence:** Everything outside `/nix` and `/persist` is wiped on reboot. System persistence is declared in the host config (`environment.persistence."/persist"`). User persistence is in `home/robert.nix` (`home.persistence."/persist"`). When adding new stateful paths, they must be added to the appropriate persistence config.

**Theming:** Stylix provides system-wide base16 theming. Individual app theme overrides go through `stylix.targets.<app>`.

**Home Manager:** Integrated as a NixOS module via `home-manager.nixosModules.home-manager` in the flake. User config is imported with `home-manager.users.robert`.

**Desktop stack:** Niri (scrollable-tiling Wayland compositor) + DankMaterialShell (panel/greeter). Keybindings are Vim-style (hjkl) with Super as the mod key.

**Wallpaper recoloring:** Source wallpapers live in `home/wallpapers/` in the project. At build time, `lutgen` recolors them with the Stylix base16 palette via `pkgs.runCommand`. Home Manager symlinks the output into `~/Pictures/Wallpapers/`, which DMS uses for wallpaper cycling. Recoloring only runs during `nixos-rebuild`, not on every boot.

**Editor:** Nixvim with LSP servers for Nix (nixd), Lua, Rust, TypeScript, Python, and Bash.

**Secrets:** agenix encrypts secrets to the host's SSH host key. Edit recipients in `secrets/secrets.nix`; create/edit a secret with `nix run github:ryantm/agenix -- -e <name>.age` from inside `secrets/`. Decryption happens early at boot — `age.identityPaths` in `modules/nixos/users.nix` points at `/etc/ssh/ssh_host_ed25519_key`, which lives in `/persist`.

## Conventions

- Section headers use Unicode box-drawing: `# ── Section Name ──────────────`
- 2-space indentation throughout
- Mutable users are disabled; user accounts are fully declarative
- State version: `25.05`
