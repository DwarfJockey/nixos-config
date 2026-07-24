# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS flake configuration for a Framework 13 laptop (12th gen Intel). Single host (`framework-13`), single user (`robert`). Uses an ephemeral root filesystem (tmpfs) with impermanence for persistent state under `/persist`.

Repo: `github.com/DwarfJockey/nixos-config`. The `framework-13` host is tied to specific 12th-gen Intel Framework 13 hardware (disk device path in `disko.nix`, hardware quirks in `hardware-configuration.nix`); cloning to different hardware requires a new host entry.

## Build Commands

```bash
# Build and activate system configuration
sudo nixos-rebuild switch --flake .#framework-13

# Test without making it the boot default
sudo nixos-rebuild test --flake .#framework-13

# Build without activating (dry check; no sudo needed)
nixos-rebuild build --flake .#framework-13

# Check flake validity
nix flake check

# Update all flake inputs
nix flake update

# Update a single input
nix flake update <input-name>
```

## Architecture

**File layout:**
- `flake.nix` — Entry point. Defines inputs, passes all of them as `specialArgs` to modules.
- `hosts/framework-13/default.nix` — Thin host entry. Imports the modules below plus host-only bits (locale, top-level packages, stateVersion).
- `hosts/framework-13/{hardware-configuration,disko}.nix` — Disk layout, filesystems, kernel modules. Root is tmpfs; `/nix` and `/persist` are Btrfs subvolumes.
- `modules/nixos/{boot,nix,networking,bluetooth,audio,desktop,theming,persistence,firmware,fingerprint,backups,apps,users,boot-defaults}.nix` — System-level NixOS modules, one concern each. `boot-defaults` sets startup hardware levels (screen brightness 50%, keyboard backlight full-on at boot and after resume, audio volume 50%, battery charge limit 80%). `firmware` enables fwupd (LVFS firmware updates); `fingerprint` enables fprintd (fingerprint-or-password for sudo); `backups` runs btrbk taking hourly local Btrfs snapshots of `/persist` under `/persist/.snapshots` (snapshot-only, no offsite target).
- `modules/home-manager/{shell,editor,desktop}.nix` — Home Manager modules imported by `home/robert.nix`.
- `home/robert.nix` — Home Manager entry point (persistence, packages, Claude Code settings). Imported as a NixOS module, not standalone.
- `secrets/secrets.nix` + `secrets/*.age` — agenix recipients and encrypted secrets. Decrypted at boot via `/persist/etc/ssh/ssh_host_ed25519_key`.

**Key flake inputs:** nixpkgs (unstable), nixos-hardware, impermanence, home-manager, noctalia, nixvim, niri, zen-browser, firefox-addons, agenix, stylix.

## Key Patterns

**Impermanence:** Everything outside `/nix` and `/persist` is wiped on reboot. System persistence is declared in the host config (`environment.persistence."/persist"`). User persistence is in `home/robert.nix` (`home.persistence."/persist"`). When adding new stateful paths, they must be added to the appropriate persistence config.

**Theming:** Stylix (NixOS module, configured in `modules/nixos/theming.nix`) owns system-wide theming from a single base16 scheme — an inline "Over-Engineered Dark" palette (`base16Scheme` set as an attrset of `base00`..`base0F`), `polarity = "dark"` — driving colors, fonts, cursor (phinger-dark), icons (Papirus-Dark), and window opacity (`stylix.opacity.desktop`/`popups`). With `autoEnable` on, Stylix themes every installed native target (GTK, Qt, console/TTY, Ghostty, nushell, starship, Zen, …); Home Manager is a NixOS module, so its Stylix targets auto-inherit the system scheme (`desktop.nix` just sets `gtk.enable`/`qt.enable` and leaves Ghostty's theme/font to Stylix). A few things have no Stylix target. **Noctalia** is bridged manually: Stylix ships a `noctalia` target (`stylix.targets.noctalia`) that also writes `programs.noctalia`, but it points the wallpaper at the raw `stylix.image` (this repo wants the recolored+dimmed `themedWallpaper`) and doesn't bridge the bar opacity, so `desktop.nix` disables it (`stylix.targets.noctalia.enable = false`) and instead builds a `customPalettes.Stylix` palette from `config.lib.stylix.colors`, selecting it with `theme = { source = "custom"; custom_palette = "Stylix"; mode = "dark"; }`. Opacity is bridged the same way: `desktop.nix` reads `config.stylix.opacity` and applies `.desktop` to the Noctalia bar (`bar.main.background_opacity`) and `.popups` to the niri `^noctalia-` panels/popups layer-rule. **niri** is themed by niri-flake's own `stylix.targets.niri` (border active = base0D / inactive = base03, plus the niri cursor); `desktop.nix` overrides only the border width (`layout.border.width = 1`, thinner than niri's default 4) and otherwise leaves `border` colors/`focus-ring` target-driven. **Shadows** are split by surface type. niri owns shadows for **windows and the bar**, where the surface hugs its visible content: niri's three presets (`baseShadow`/`activeShadow`/`popupShadow` in `desktop.nix`) approximate Material-3 elevation Levels 1/3/5 — a single drop shadow each, since niri can't layer umbra/penumbra/ambient — applied to tiled/active/floating windows and the `^noctalia-bar` layer-rule. **Noctalia draws its own shadows for its popups/panels** (`shell.shadow.alpha = 0.55`, `shell.panel.shadow = true`; color from the palette's `mShadow` = base00): niri can't clip a layer-surface shadow to a *floating popup's* visible card (it shadows the whole surface including invisible margins), so the `^noctalia-` popup layer-rule carries no niri shadow — only opacity and corner-radius. The bar's own Noctalia shadows stay off (`bar.main.shadow`/`contact_shadow` = false), as does `dock.shadow`. The rest keep their own theming: **nixvim** (Stylix only targets vanilla `programs.neovim`; uses its default colorscheme) and **Claude Code** (`theme = "dark"`). To turn off a misbehaving target: `stylix.targets.<name>.enable = false`.

**Home Manager:** Integrated as a NixOS module via `home-manager.nixosModules.home-manager` in the flake. User config is imported with `home-manager.users.robert`.

**Desktop stack:** Niri (scrollable-tiling Wayland compositor) + Noctalia (bar/dock/control-center/lock), spawned by niri via `spawn-at-startup "noctalia"` and driven from keybinds with `noctalia msg <cmd>`. There is no graphical greeter — `greetd` autologins into `niri-session` (`modules/nixos/desktop.nix`). Keybindings are Vim-style (hjkl) with Super as the mod key.

**Wallpaper:** A source photo is vendored at `modules/home-manager/wallpapers/demon-city-shinjuku.jpg`, remapped onto the base16 palette (lutgen, luminosity-preserved) and dimmed toward `base00` (imagemagick) into `themedWallpaper` — a PNG built in the Nix store, so it tracks the scheme and survives the ephemeral root. Noctalia reads its path from `settings.wallpaper.default.path` (`desktop.nix`); cycling is disabled. Noctalia's *live* wallpaper lives in non-persisted runtime state (see *Noctalia settings* below), so a rebuild that changes the `themedWallpaper` store hash leaves the running shell on its stale/default path until reboot — a `home.activation.noctaliaWallpaper` hook re-asserts it via `noctalia msg wallpaper-set` after each switch.

**Editor:** Nixvim with LSP servers for Nix (nixd), Lua, Rust, TypeScript, Python, and Bash. No colorscheme is configured — nvim uses its default (`editor.nix`).

**niri config generation:** The niri config is built from niri-flake's typed `programs.niri.settings`, but that module doesn't expose everything the niri binary supports (e.g. `background-effect`/blur). Such features are appended as **raw KDL** to `config.programs.niri.finalConfig` inside the `validated-config-for` call in `desktop.nix`. Add niri features the typed module lacks there, not in `settings`.

**Noctalia settings (declarative vs runtime):** `programs.noctalia.settings` writes the declarative `~/.config/noctalia/config.toml` (persisted). The Noctalia GUI writes to `~/.local/state/noctalia/settings.toml`, which is **not** persisted (wiped on reboot). GUI changes must be ported back into `desktop.nix` to survive.

**Secrets:** agenix encrypts secrets to the host's SSH host key. Edit recipients in `secrets/secrets.nix`; create/edit a secret with `nix run github:ryantm/agenix -- -e <name>.age` from inside `secrets/`. Decryption happens early at boot — `age.identityPaths` in `modules/nixos/users.nix` points at `/persist/etc/ssh/ssh_host_ed25519_key`. Git's `user.name`/`user.email` are **not** in `shell.nix`; they come from the `git-identity` secret, decrypted to `/run/agenix/git-identity` and pulled in via `programs.git.includes`.

## Conventions

- Mutable users are disabled; user accounts are fully declarative
- State version: `25.05`
