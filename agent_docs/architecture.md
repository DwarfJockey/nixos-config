# Architecture: the dendritic layout

**Dendritic pattern** ([mightyiam/dendritic](https://github.com/mightyiam/dendritic)). `flake.nix` is only inputs plus a `mkFlake` whose `imports` is every `.nix` file under `modules/` (`lib.filesystem.listFilesRecursive`, minus paths containing `/_`): **every such file is a flake-parts module**, imported automatically, and each one implements a single *feature* across every configuration it touches. A feature stores its lower-level modules in `flake.modules.nixos.pc` and/or `flake.modules.homeManager.pc` (flake-parts' `modules` option, enabled in `modules/flake-parts.nix`); every file merges into those same two names, and the host imports just those two. So one app's NixOS program, Home Manager config, session unit, extra user group and persisted directories all sit in one file — e.g. `modules/apps/1password.nix`. To add a feature, add a file; to drop one, delete it or rename it with a leading `_` (paths containing `/_` are not imported). There are no `enable` toggles and no imports lists to maintain.

Writing a feature file:
```nix
{ config, inputs, ... }:            # top-level (flake-parts) args
let inherit (config) vars; in        # shared values, read from the top-level config
{
  flake.modules.nixos.pc = { pkgs, ... }: {         # an ordinary NixOS module
    imports = [ inputs.foo.nixosModules.default ];  # third-party modules: in the feature that uses them
    users.users.${vars.username}.extraGroups = [ "foo" ];
  };
  flake.modules.homeManager.pc = { config, ... }: { # an ordinary HM module (`config` here is HM's)
    home.persistence."/persist".directories = [ ".config/foo" ];
  };
}
```
Lower-level modules get `inputs` and `vars` by **closure** over the top-level args, never through `specialArgs`/`extraSpecialArgs` (neither is set anywhere). The one cross-boundary read is Home Manager's own `osConfig` (`desktop/umbriel.nix` takes the patched compositor package from the NixOS half).

**File layout:**

- `flake.nix` — inputs only, plus the one-line `outputs`.
- `modules/flake-parts.nix` — enables `flake.modules`, sets `systems`.
- `modules/meta.nix` — the `vars` option and its values. See *Variables* below.
- `modules/hosts/framework-13-pro.nix` — defines `nixosConfigurations.${vars.hostname}` from `modules.nixos.pc` + `modules.nixos.framework-13-pro` + `modules.homeManager.pc` (under `home-manager.users.<username>`), plus host-only bits (`hostPlatform`, `nixos-hardware`, `stateVersion`). `modules/hosts/framework-13-pro/{hardware,disko}.nix` contribute to `modules.nixos.framework-13-pro`: kernel modules, tmpfs root, the `xe` GPU choice, the disk layout (root is tmpfs; `/nix` and `/persist` are Btrfs subvolumes). The attr name is `vars.hostname`, not the file name.
- `modules/system/` — machine-level features: `nix`, `boot`, `locale`, `networking`, `hardware` (Bluetooth, fwupd — the *chosen* hardware bits, as against the generated `hosts/framework-13-pro/hardware.nix`), `audio`, `power` (suspend/lid behaviour; persists power-profiles-daemon state so the chosen profile, `performance`, survives reboots), `boot-defaults` (screen brightness 50%, keyboard backlight at its lowest lit level (20/100) at boot and after resume, audio volume 100%), `users` (agenix + the user account), `home-manager` (the HM NixOS module + `home.stateVersion`), `impermanence` (the module plus the *core* persistence lists).
- `modules/desktop/` — the session: `umbriel` (NixOS module, satellite patch, portal, and the whole HM compositor config), `noctalia`, `greeter` (see *Login*), `theming` (Stylix), `polkit`, `keyring`, `fingerprint` (see *Fingerprint*), `touchpad`.
- `modules/shell/` — `nushell` (and its prompt/completion/CLI tools), `git` (+ `gh`), `editor` (nixvim).
- `modules/apps/` — one file per app: `zen`, `1password`, `discord`, `senpai`, `steam`, `claude-code`, `ghostty`, `nautilus`, `kicad`, `prusa-slicer`, `inkscape`, `plugdata`, `romvault`, `dwarf-fortress` (persistence only), `utilities` (config-less packages).
- `modules/_lib/` — not imported (the `/_`); plain functions, not modules. `wallpaper.nix` returns the themed wallpaper derivation, imported by both the Noctalia shell and the greeter (see *Wallpaper*). `colors.nix` is `{ over, palette }`, shared by the manual Stylix bridges: `over fg bg alpha` composites in sRGB the way adw-gtk3 writes its colours, for the places a real alpha channel can't reach (a literal `#RRGGBBAA` covers the places that keep an alpha channel); `palette` is the single Noctalia colour-role mapping — the greeter takes its keys as-is, the shell prefixes them into its own `mOnSurfaceVariant` spelling (see *Theming*). `tray-app.nix` builds the session user unit shared by Zen, 1Password and Vesktop (see *Session autostart*).
- Non-`.nix` assets sit beside the feature that uses them (`desktop/xwayland-satellite-size-hints.patch`, `apps/claude-logo.png`, `_lib/wallpapers/`); only `.nix` files are imported.
- `secrets/secrets.nix` + `secrets/*.age` — agenix recipients and encrypted secrets, outside `modules/` so they are never imported. Decrypted at boot via `/persist/etc/ssh/ssh_host_ed25519_key`.

**Key flake inputs:** flake-parts, nixpkgs (unstable), nixos-hardware, impermanence, disko, home-manager, noctalia, noctalia-plugins, noctalia-greeter, nixvim, umbriel, xdg-desktop-portal-umbriel, zen-browser, firefox-addons, nixcord, agenix, stylix. Everything follows the one `nixpkgs`; nothing pins a second tree.

**Variables:** `config.vars` is a top-level option declared and set in `modules/meta.nix` — every personal/host-specific value: `hostname`, `username`, `timeZone`, `locale`, `keyboardLayout`, `configDir`, `hashedPassword`, `git`, `stateVersion`. Feature files read it from their top-level args (`{ config, ... }: let inherit (config) vars; in …`) and close over it in the modules they define; it is never passed through `specialArgs`. **Nothing else in the repo should hardcode a username, hostname, or disk path** — grep for a literal before adding one. It is named `vars`, not `settings`, because `settings = { ... }` is already a heavily used module option in `noctalia.nix`, `umbriel.nix`, and `greeter.nix`.

`hashedPassword = null` and `git = null` select the agenix path (see *Secrets*). A value only one feature reads lives in that feature instead (the disk device and swap size in `hosts/framework-13-pro/disko.nix`, the IRC server in `apps/senpai.nix`). Optional apps have **no** toggle in `vars` — a feature is on because its file exists (see *Dendritic pattern*). An app that needs a user group adds it to `users.users.<username>.extraGroups` in its own file (`apps/1password.nix`, `apps/steam.nix`), because naming a group no module created is a build-time assertion failure — the group and its membership must come and go together.

