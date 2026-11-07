# Verifying changes

- `nixos-rebuild build --flake .#framework-13-pro` — builds the system into `./result` without activating; no sudo. Run after every change.
- `sudo nixos-rebuild test --flake .#framework-13-pro` — activates without making it the boot default.
- `nix flake check --no-build` — evaluates every output. `warning: unknown flake output 'modules'` is expected (flake-parts' `flake.modules`).
- `nix eval .#nixosConfigurations.framework-13-pro.config.<option>` — read a single evaluated option; `.options.<option>.definitionsWithLocations` shows which files set it.

Regression test for a pure restructure: build and compare against the running system. A byte-identical store path is not expected when definitions move between files — list-valued options (`home.packages`, the persistence lists, `extraGroups`) concatenate in import order, which reorders their generated files and so changes hashes without changing content. Check instead that `nix store diff-closures /run/current-system ./result` is empty and that the generated unit/config files differ only in ordering.
