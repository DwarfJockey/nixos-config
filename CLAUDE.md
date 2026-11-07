# nixos-config

NixOS flake for one Framework 13 Pro (Panther Lake) laptop: Umbriel compositor + Noctalia shell,
themed by Stylix, tmpfs root with impermanence (state under `/persist`). Host `framework-13-pro`,
user `dwarfjockey` — both from `vars` in `modules/meta.nix`.

## Commands
- Build (no sudo; check every change with it): `nixos-rebuild build --flake .#framework-13-pro`
- Apply: `sudo nixos-rebuild switch --flake .#framework-13-pro` (`test` instead of `switch` to not make it the boot default)
- Validate: `nix flake check --no-build` (the `unknown flake output 'modules'` warning is expected)
- Inputs: `nix flake update [<input>]`

## Layout — dendritic pattern
Every `.nix` file under `modules/` is a flake-parts module, imported automatically by `flake.nix`,
except paths containing `/_`. Each file is one *feature*: it writes its NixOS part to
`flake.modules.nixos.pc` and its Home Manager part to `flake.modules.homeManager.pc`, and the host
(`modules/hosts/framework-13-pro.nix`) imports those two. Template: `modules/apps/1password.nix`.
- `modules/system/` — machine: boot, nix, users + agenix, impermanence core, power, networking, …
- `modules/desktop/` — session: umbriel, noctalia, greeter, theming, polkit, keyring, fingerprint, touchpad
- `modules/shell/` — nushell, git, nixvim · `modules/apps/` — one file per app
- `modules/hosts/framework-13-pro/` — hardware + disko (host-only) · `modules/_lib/` — plain helper functions
- `secrets/` — agenix files (outside `modules/`, never imported)

## Conventions
- Add a feature = add a file; drop one = delete it or prefix it with `_`. No enable toggles, no import lists.
- Lower modules get `inputs`/`vars` by closure over the file's top-level args — never `specialArgs`.
  Third-party modules are imported inside the feature that uses them.
- Values several features share go in `vars`; never hardcode the username or hostname.
- An app persists its own state (`home.persistence` / `environment.persistence`) in its own file.
- An app needing a user group adds the group *and* the membership in its own file (a missing group is an eval assertion).
- Users are fully declarative (`mutableUsers = false`); `vars.stateVersion` feeds both `system.` and `home.stateVersion`.

## Gotchas
- **Persist directories, never single files**: file entries are bind mounts, and atomic `rename()` onto
  them fails silently (EBUSY).
- Tray apps (and Zen) must be user units built by `modules/_lib/tray-app.nix`, not Umbriel `autostart`.
- Noctalia GUI changes land in non-persisted state — port them into `modules/desktop/noctalia.nix`.
- nushell reads no `home.sessionVariables`; `modules/shell/nushell.nix` bridges them.
- Umbriel config keys are unstable; `validateConfig` checks them at build time. Check upstream `docs/user/`.
- Zen extensions are pinned by the `firefox-addons` input with auto-update off: Gecko updating past the
  pin and then being downgraded broke 1Password's IndexedDB. Bump with `nix flake update firefox-addons`.
- Don't set greetd `default_session`/`initial_session`; keep `desktop/fingerprint.nix` even without a reader.

## Deeper docs (read when touching that area)
- `agent_docs/architecture.md` — the dendritic layout in full, file by file, and `vars`
- `agent_docs/desktop.md` — Umbriel, Noctalia (settings, plugins, wallpaper), autostart/tray, login, fingerprint, touchpad
- `agent_docs/theming.md` — Stylix and the manual bridges (Noctalia, Umbriel, greeter, Claude Code, Zen)
- `agent_docs/impermanence.md` — what persists where, and why single files can't
- `agent_docs/claude-code.md` — Claude Code config dir, settings merge, notification hook
- `agent_docs/secrets.md` — agenix and reinstalling on other hardware
- `agent_docs/verifying.md` — checking that a refactor didn't change the system
