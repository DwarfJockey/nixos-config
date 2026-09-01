# nixos-config

NixOS flake configuration for a Framework 13 Pro (Intel Core Ultra Series 3 / Panther Lake) laptop: [Umbriel](https://github.com/noctalia-dev/umbriel) + [Noctalia](https://github.com/noctalia-dev/noctalia), themed end-to-end by [Stylix](https://github.com/nix-community/stylix), with an ephemeral root on tmpfs and persistent state under `/persist` via [impermanence](https://github.com/nix-community/impermanence). Disk layout is declarative via [disko](https://github.com/nix-community/disko).

Every personal value — username, hostname, timezone, disk, credentials, which apps to install — lives in **[`vars.nix`](./vars.nix)**. Nothing else needs editing to make this yours.

## Day-to-day

```bash
# Apply config changes
sudo nixos-rebuild switch --flake .#framework-13

# Test without making it the boot default
sudo nixos-rebuild test --flake .#framework-13

# Update all flake inputs
nix flake update

# Update a single input
nix flake update <input-name>

# Validate the flake
nix flake check
```

Substitute your own hostname for `framework-13` once you've edited `vars.nix`.

## Install on your own machine

### 1. Fork or clone, then edit `vars.nix`

```nix
{
  hostname = "my-laptop";
  username = "alice";

  timeZone       = "Europe/Berlin";
  locale         = "de_DE.UTF-8";
  keyboardLayout = "de";

  configDir  = "Projects/nixos-config";  # where you keep this repo, relative to $HOME
  diskDevice = "/dev/nvme0n1";           # DESTRUCTIVE — disko formats this
  swapSize   = "32G";

  hashedPassword = null;   # see step 3
  git            = null;   # see step 3
  irc            = null;   # senpai; null disables it

  apps = { onePassword = true; steam = true; discord = true; fingerprint = true; };

  stateVersion = "25.05";
}
```

`null` means off throughout — that's the idiom for `hashedPassword`, `git`, and `irc`.

### 2. Regenerate the hardware config

```bash
nixos-generate-config --root /mnt --no-filesystems --show-hardware-config \
  > hosts/hardware-configuration.nix
```

Then re-add the tmpfs root by hand — it is the one part `nixos-generate-config` cannot produce, and impermanence depends on it:

```nix
  # Root on tmpfs (ephemeral / impermanence). Disk layout is in ./disko.nix.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=755" "size=6G" ];   # size to taste; it is RAM
  };
```

If you are not on a Framework 13 Pro, also see [Different hardware](#different-hardware) below.

### 3. Credentials — pick one

**Plaintext (simplest).** Set both in `vars.nix` and `secrets/` is never read:

```bash
mkpasswd -m sha-512   # paste the hash into vars.nix as hashedPassword
```

```nix
  hashedPassword = "$6$…";
  git = { name = "Alice Example"; email = "alice@example.com"; };
```

**agenix (keeps credentials out of the repo).** The `.age` files here are encrypted to *this* machine's SSH host key and cannot be decrypted on yours, so you must re-create them:

```bash
# Generate a host key at the path age reads at boot (modules/nixos/users.nix)
mkdir -p /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key

# Put its public key in secrets/secrets.nix, replacing the existing one
cat /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub

# Re-create both secrets (user-password.age holds the output of `mkpasswd -m sha-512`;
# git-identity.age holds a gitconfig [user] block with name/email)
cd secrets
rm user-password.age git-identity.age
nix run github:ryantm/agenix -- -e user-password.age
nix run github:ryantm/agenix -- -e git-identity.age
```

Leave `hashedPassword` and `git` as `null` in `vars.nix` to use this path.

### 4. Partition and install

```bash
# Destructive — formats vars.diskDevice
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --mode disko --flake .#my-laptop

sudo nixos-install --flake .#my-laptop --no-root-password
sudo reboot
```

Note the `--flake` form: `disko.nix` reads `vars.nix`, so it can no longer be passed to disko as a bare file path.

`--no-root-password` is fine — there is no root login by design (`mutableUsers = false`, sudo via the `wheel` group). Your user's password comes from step 3.

After first boot, anything not declared in `home/default.nix`'s `home.persistence` block (or the system-level `environment.persistence` block in `modules/nixos/persistence.nix`) is wiped on every reboot — that's impermanence working as intended.

## Different hardware

`vars.nix` covers identity, not silicon. On anything but a Framework 13 Pro, these are hand-edits:

| what | where |
|---|---|
| `nixos-hardware.nixosModules.framework-intel-core-ultra-series3` | `flake.nix` — swap for your machine's module, or drop it |
| `hardware.intelgpu.driver = "xe"` — Panther Lake is xe-only; older Intel wants `i915` | `hosts/hardware-configuration.nix` |
| tmpfs root size (`6G`, sized against 16GB of RAM) | `hosts/hardware-configuration.nix` |
| Kernel pin `pkgs.linuxPackages` (Panther Lake needs ≥ 6.17, `xe` needs ≥ 6.8) | `modules/nixos/boot.nix` |
| Display scale `output."eDP-1".scale = 2.0` (2880x1920 panel → 1440x960 logical) | `modules/home-manager/desktop/umbriel.nix` |
| Lock-screen box geometry, in that same 1440x960 logical space and pinned to `eDP-1` | `modules/home-manager/desktop/noctalia.nix` |
| Cursor size `24`, the HiDPI-doubled value that goes with scale 2 | `modules/nixos/theming.nix` |
| `swapSize` (`32G`; hibernate is off, so this is overflow, not a RAM image) | `vars.nix` |

The backlight node and the AC adapter are *not* in this table: both used to be hardcoded
(`intel_backlight`, `ACAD`) and both now discover themselves at runtime —
`modules/nixos/boot-defaults.nix` takes the first writable `/sys/class/backlight/*`, and
`modules/nixos/power.nix` matches the power supply whose `type` reads `Mains`.

## Architecture reference

For module layout, conventions, key flake inputs, and the wallpaper-recoloring pipeline, see [CLAUDE.md](./CLAUDE.md).
