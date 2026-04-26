# nixos-config

NixOS flake configuration for a Framework 13 (12th-gen Intel) laptop. Single host (`framework-13`), single user (`robert`). Ephemeral root on tmpfs; persistent state lives under `/persist` via [impermanence](https://github.com/nix-community/impermanence). Disk layout is declarative via [disko](https://github.com/nix-community/disko).

## Day-to-day

```bash
# Apply config changes
sudo nixos-rebuild switch --flake .#framework-13

# Test without making it the boot default
sudo nixos-rebuild test --flake .#framework-13

# Update all flake inputs
nix flake update

# Update a single input
nix flake lock --update-input <input-name>

# Validate the flake
nix flake check
```

## Fresh install on the same hardware

For a bare-metal reinstall (or restoring after disk failure on the same Framework 13):

```bash
# 1. Boot a NixOS installer ISO and connect to the network.

# 2. Clone the repo:
git clone https://github.com/DwarfJockey/nixos-config /tmp/cfg
cd /tmp/cfg

# 3. Partition + format the target disk (writes to /dev/nvme0n1 — destructive!):
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --mode disko ./hosts/framework-13/disko.nix

# 4. Install the system:
sudo nixos-install --flake .#framework-13 --no-root-password

# 5. Reboot.
sudo reboot
```

The user account `robert` has a hashed password baked into `hosts/framework-13/default.nix`, so `--no-root-password` is fine — there's no root login by design (`mutableUsers = false`, sudo via the `wheel` group).

After first boot, anything not declared in `home/robert.nix`'s `home.persistence` block (or the system-level `environment.persistence` block in `default.nix`) is wiped on every reboot — that's impermanence working as intended.

## Different hardware

The `framework-13` host config targets a specific machine: 12th-gen Intel Framework 13, single 500 GB NVMe at `/dev/nvme0n1`. On different hardware you'll need to:

1. Generate a fresh `hardware-configuration.nix` (`nixos-generate-config --root /mnt --no-filesystems`).
2. Edit `hosts/framework-13/disko.nix` for the new disk layout, or create a new host directory.
3. Add a new `nixosConfigurations.<hostname>` entry to `flake.nix`.

## Architecture reference

For module layout, conventions, key flake inputs, and the wallpaper-recoloring pipeline, see [CLAUDE.md](./CLAUDE.md).
