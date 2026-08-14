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
- `modules/nixos/{boot,nix,networking,bluetooth,audio,desktop,greeter,theming,persistence,power,firmware,fingerprint,keyring,apps,users,boot-defaults}.nix` — System-level NixOS modules, one concern each. `boot-defaults` sets startup hardware levels (screen brightness 30%, keyboard backlight full-on at boot and after resume, audio volume 50%). `firmware` enables fwupd (LVFS firmware updates); `power` handles suspend/lid behaviour and AC-vs-battery power profiles; `keyring` sets up gnome-keyring; `greeter` configures Noctalia Greeter (see *Login* below); `fingerprint` enables fprintd (see *Fingerprint* below).
- `modules/home-manager/{shell,editor,desktop}.nix` plus `modules/home-manager/desktop/{niri,noctalia,browser,terminal,comms}.nix` — Home Manager modules imported by `home/robert.nix`. `desktop.nix` is a thin importer; the per-app config lives in `desktop/`.
- `modules/wallpaper.nix` — Not a module: a plain function returning the themed wallpaper derivation, imported by both the Noctalia shell (Home Manager) and the greeter (NixOS). See *Wallpaper* below.
- `home/robert.nix` — Home Manager entry point (persistence, packages, Claude Code settings). Imported as a NixOS module, not standalone.
- `secrets/secrets.nix` + `secrets/*.age` — agenix recipients and encrypted secrets. Decrypted at boot via `/persist/etc/ssh/ssh_host_ed25519_key`.

**Key flake inputs:** nixpkgs (unstable), nixos-hardware, impermanence, disko, home-manager, noctalia, noctalia-greeter, nixvim, niri, zen-browser, firefox-addons, nixcord, agenix, stylix.

## Key Patterns

**Impermanence:** Everything outside `/nix` and `/persist` is wiped on reboot. System persistence is declared in the host config (`environment.persistence."/persist"`). User persistence is in `home/robert.nix` (`home.persistence."/persist"`). When adding new stateful paths, they must be added to the appropriate persistence config.

**Persist directories, never single files.** `files` entries are implemented as systemd bind mounts (`systemctl list-units --type=mount`), and `rename()` onto a mount point returns `EBUSY` — so any program that saves atomically (temp file + rename, which is what GLib's `g_file_set_contents` and Claude Code both do) fails **silently** and the persisted copy never changes. `~/.local/share/recently-used.xbel` was in the user `files` list from the initial commit and its mtime never moved off its pre-install value; it has been removed. Persist the containing directory instead, or accept the state being session-scoped. The NixOS-level `files` entries (`/etc/machine-id`, the SSH host keys) are safe only because they are written once at install and read-only afterwards.

**Theming:** Stylix (`modules/nixos/theming.nix`) owns system-wide theming from a single inline base16 scheme ("Framework Anodized", `polarity = "dark"`) — colors, fonts, cursor, icons, and window opacity. With `autoEnable` on it themes every native target (GTK, Qt, Ghostty, Zen, …), and Home Manager's targets inherit the system scheme. Targets with no Stylix support are bridged manually in `modules/home-manager/desktop/`: **Noctalia** (custom palette + opacity, `noctalia.nix`), **niri** (target-driven, only border width overridden, `niri.nix`), and **shadows** (split between the two by surface type). The **greeter** gets the same base16 mapping again in `modules/nixos/greeter.nix`, since it is system-scoped and cannot read Home Manager values. To turn off a misbehaving target: `stylix.targets.<name>.enable = false`. **Full detail — the Noctalia bridge, niri overrides, and the shadow split — is in `agent_docs/theming.md`.**

One Stylix side effect is load-bearing: its Qt target exports `QT_STYLE_OVERRIDE=kvantum`, which polkit-kde-agent passes to its QML engine as a Quick Controls style. Kvantum ships no QML module, so the agent segfaulted on every GUI privilege prompt (polkit then denied with no dialog ever drawn). `theming.nix` drops that variable for the polkit unit only via `UnsetEnvironment`; setting `QT_QUICK_CONTROLS_STYLE` does **not** work, as the agent overrides it at runtime.

**Home Manager:** Integrated as a NixOS module via `home-manager.nixosModules.home-manager` in the flake. User config is imported with `home-manager.users.robert`.

**Session variables:** `home.sessionVariables` is written to `hm-session-vars.sh` (a POSIX script) and, for a subset, `~/.config/environment.d/10-home-manager.conf`. nushell is the login shell and sources **neither**, so those variables were silently absent from every interactive shell — `EDITOR` stayed at NixOS's `nano` rather than HM's `nvim`. `modules/home-manager/shell.nix` bridges them into `programs.nushell.environmentVariables`, skipping values containing `$` (POSIX expansions like `XDG_CONFIG_DIRS`, which nushell would take literally and which it already inherits correctly from the session). Declare user variables in `home.sessionVariables` and the bridge picks them up; variables a *GUI* app needs still have to reach the systemd user manager separately.

**Desktop stack:** Niri (scrollable-tiling Wayland compositor) + Noctalia (bar/dock/control-center/lock), driven from keybinds with `noctalia msg <cmd>`. Noctalia runs as a `systemd.user.services.noctalia` unit bound to `graphical-session.target` with a short `TimeoutStopSec` (it ignores SIGTERM, so as a niri `spawn-at-startup` scope it stalled shutdown for the full 90s stop timeout). Keybindings are Vim-style (hjkl) with Super as the mod key.

**Session autostart:** niri runs `spawn-at-startup` during its own startup and raises `graphical-session.target` *afterwards*, so a spawned app can never be ordered after a session service. **Tray apps therefore must be `systemd.user.services` with `After = [ "noctalia.service" ]`, never `spawn-at-startup`** (`modules/home-manager/desktop/niri.nix`). Noctalia hosts `org.kde.StatusNotifierWatcher` but only claims the name seconds into startup, and Electron asks `NameHasOwner` exactly once at tray-creation with no Wayland fallback and no retry — so 1Password and Vesktop used to come up running but permanently invisible (hidden by `--silent`/`--start-minimized`, no icon to restore from). `noctalia.service` is `Type = "dbus"` on that name so the unit only goes active once the watcher is live, which is what makes the `After=` meaningful. Apps that re-register on `NameOwnerChanged` (Steam, via libayatana-appindicator) or need no tray (Zen) can stay in `spawn-at-startup`.

**Login:** `greetd` runs **Noctalia Greeter** (`modules/nixos/greeter.nix`), which brings its own wlroots compositor and matches the Noctalia shell. There is deliberately **no autologin** — `modules/nixos/desktop.nix` only sets `services.greetd.enable`; the greeter module owns `default_session.command`, and nixpkgs defaults `default_session.user` to `greeter`. Do not set either in `desktop.nix`: the greeter module reads `default_session.user` to own `/var/lib/noctalia-greeter`, and adding an `initial_session` would both bypass the greeter and make logind register the desktop as `Class=greeter` (which breaks `Lock`/`SetLockedHint`, so niri and Noctalia log "Session does not support lock screen"). The greeter is **password-only**; sessions are discovered from `wayland-sessions` `.desktop` files via `XDG_DATA_DIRS`, and `settings.session.default` takes the picker *label* (`Niri`), not the `.desktop` id — list them with `noctalia-greeter sessions`.

**Fingerprint:** `services.fprintd.enable` makes nixpkgs default `security.pam.services.<name>.fprintAuth` to true for **every** PAM service, putting `pam_fprintd` first as `auth sufficient`. PAM auth is serialised, so any graphical caller that cannot render "place your finger" blocks for its full 30s timeout before `pam_unix` sees the typed password. `modules/nixos/fingerprint.nix` therefore keeps it for `sudo` but sets `login.fprintAuth = false` — the stack Noctalia's lock screen uses. Noctalia runs its own fprintd client alongside PAM, so swipe-to-unlock still works there. Enroll with `fprintd-enroll -f <finger>` as the user (**not** under `sudo`, which enrolls root); prints live in `/var/lib/fprint`, which is persisted.

**Wallpaper:** A source photo is vendored at `modules/home-manager/wallpapers/acrylic-pour-magenta-cyan.jpg`, remapped onto the base16 palette (lutgen, luminosity-preserved) and dimmed toward `base00` (imagemagick) into `themedWallpaper` — a PNG built in the Nix store, so it tracks the scheme and survives the ephemeral root. The derivation lives in `modules/wallpaper.nix` because both the Noctalia shell (Home Manager) and the greeter (NixOS) show it and the greeter cannot reach into Home Manager scope; identical arguments mean one build and one store path. Noctalia reads its path from `settings.wallpaper.default.path` (`modules/home-manager/desktop/noctalia.nix`); cycling is disabled. Noctalia's *live* wallpaper lives in non-persisted runtime state (see *Noctalia settings* below), so a rebuild that changes the `themedWallpaper` store hash leaves the running shell on its stale/default path until reboot — a `home.activation.noctaliaWallpaper` hook re-asserts it via `noctalia msg wallpaper-set` after each switch.

**Editor:** Nixvim with LSP servers for Nix (nixd), Lua, Rust, TypeScript, Python, and Bash. No colorscheme is configured — nvim uses its default (`editor.nix`).

**Claude Code:** All of it lives in `home/robert.nix`. Claude's *global* config (onboarding flags, project trust, MCP auth) is `$CLAUDE_CONFIG_DIR/.claude.json`, defaulting to `$HOME/.claude.json` — a sibling of the persisted `.claude` directory, so it was wiped on every reboot and the theme picker replayed on the first launch after boot. Adding it to `home.persistence` does **not** work — see *Impermanence* above on why single-file entries break atomic writes. Instead `home.sessionVariables.CLAUDE_CONFIG_DIR` points at `~/.claude`, so the file lands inside the already-bind-mounted directory; `settings.json` resolves to `$CLAUDE_CONFIG_DIR/settings.json` and does not move. `settings.json` stays a real file (so `/model`, `/effort` can write it) and `home.activation.claudeSettings` merges the declarative fields back over it on every switch *and* every boot. The theme is another manual Stylix bridge: `~/.claude/themes/base16.json` is generated with `base = "dark-ansi"`, which resolves unlisted colors through the terminal's ANSI palette (already base16 via Stylix), so only base09 and the diff *backgrounds* — the slots the 16 ANSI colors cannot reach — are overridden.

**niri config generation:** The niri config is built from niri-flake's typed `programs.niri.settings`, but that module doesn't expose everything the niri binary supports (e.g. `background-effect`/blur). Such features are appended as **raw KDL** to `config.programs.niri.finalConfig` inside the `validated-config-for` call in `desktop.nix`. Add niri features the typed module lacks there, not in `settings`.

**Noctalia settings (declarative vs runtime):** `programs.noctalia.settings` writes the declarative `~/.config/noctalia/config.toml` (persisted). The Noctalia GUI writes to `~/.local/state/noctalia/settings.toml`, which is **not** persisted (wiped on reboot). GUI changes must be ported back into `modules/home-manager/desktop/noctalia.nix` to survive. The greeter is the same story in reverse: its `greeter.toml` is a tmpfiles symlink into the store, rebuilt every boot from `programs.noctalia-greeter.settings`, so its mutable `sync.toml` is ignored — configure the greeter declaratively, not via shell "greeter sync".

**Noctalia plugins:** Install by symlinking the plugin directory into `~/.local/share/noctalia/plugins/<name>` with `xdg.dataFile` — that path is always scanned as the last (highest-precedence) plugin root, so no source config is needed and the scan follows symlinks. The plugin repo is pinned as a `flake = false` input (`noctalia-plugins` → `noctalia-dev/community-plugins`). Three separate keys, all in `noctalia.nix`: `settings.plugins.enabled` (discovery alone does **not** load a plugin), `settings.plugin_settings."<author>/<plugin>"` for plugin-level settings, and `settings.widget."<author>/<plugin>:<entry>"` for per-instance ones — that same full entry id is what goes in a `bar.*.{start,center,end}` zone, with no `type` key, since Noctalia resolves unknown widget types through the plugin registry. `settings.plugins.source = [ ]` is deliberate: with the key absent Noctalia seeds two built-in *git* sources and re-clones both (~16MB) into non-persisted `~/.local/state/noctalia` on **every boot**; an explicit empty array suppresses that (it probes the raw table for the array, so `[]` counts as configured and a missing key does not). The trade is an empty in-shell plugin browser. Note `programs.noctalia.validateConfig` runs in a sandbox with no plugin dir, so every plugin key emits an "unrecognized widget type" / "no loaded plugin with this id" **warning** during the build — warnings don't fail validation, so leave `validateConfig` on.

**Secrets:** agenix encrypts secrets to the host's SSH host key. Edit recipients in `secrets/secrets.nix`; create/edit a secret with `nix run github:ryantm/agenix -- -e <name>.age` from inside `secrets/`. Decryption happens early at boot — `age.identityPaths` in `modules/nixos/users.nix` points at `/persist/etc/ssh/ssh_host_ed25519_key`. Git's `user.name`/`user.email` are **not** in `shell.nix`; they come from the `git-identity` secret, decrypted to `/run/agenix/git-identity` and pulled in via `programs.git.includes`.

## Conventions

- Mutable users are disabled; user accounts are fully declarative
- State version: `25.05`
