# nixos-config

NixOS flake configuration for a Framework 13 Pro (Intel Core Ultra Series 3 / Panther Lake) laptop: [Umbriel](https://github.com/noctalia-dev/umbriel) + [Noctalia](https://github.com/noctalia-dev/noctalia), themed end-to-end by [Stylix](https://github.com/nix-community/stylix), with an ephemeral root on tmpfs and persistent state under `/persist` via [impermanence](https://github.com/nix-community/impermanence). Disk layout is declarative via [disko](https://github.com/nix-community/disko).

Every personal value — username, hostname, timezone, disk, credentials — lives in **`vars`**, in [`modules/meta.nix`](./modules/meta.nix). Which apps you get is decided by which files exist under [`modules/apps/`](./modules/apps): the config follows the [dendritic pattern](https://github.com/mightyiam/dendritic), so every file under `modules/` is one feature, picked up automatically. Delete a file (or prefix its name with `_`) to drop that feature.

## Day-to-day

```bash
# Apply config changes
sudo nixos-rebuild switch --flake .#framework-13-pro

# Test without making it the boot default
sudo nixos-rebuild test --flake .#framework-13-pro

# Update all flake inputs
nix flake update

# Update a single input
nix flake update <input-name>

# Validate the flake
nix flake check
```

Substitute your own hostname for `framework-13-pro` once you've edited `vars`.

## Install on your own machine

### 1. Fork or clone, then edit `vars`

In `modules/meta.nix`:

```nix
  config.vars = {
    hostname = "my-laptop";
    username = "alice";

    timeZone       = "Europe/Berlin";
    locale         = "de_DE.UTF-8";
    keyboardLayout = "de";

    configDir  = "Projects/nixos-config";  # where you keep this repo, relative to $HOME

    hashedPassword = null;   # see step 3
    git            = null;   # see step 3

    stateVersion = "25.05";
  };
```

`null` for `hashedPassword` and `git` selects agenix (step 3). Set the disk device in `modules/hosts/framework-13-pro/disko.nix`. Then prune `modules/apps/` to the apps you want; each file is self-contained, so deleting one removes the app, its config, its session unit and its persisted state together.

### 2. Regenerate the hardware config

```bash
nixos-generate-config --root /mnt --no-filesystems --show-hardware-config
```

Copy the kernel-module lines it prints (`boot.initrd.availableKernelModules`, `boot.kernelModules`) into `modules/hosts/framework-13-pro/hardware.nix`, replacing the ones there. Keep that file's tmpfs root — it is the one part `nixos-generate-config` cannot produce, and impermanence depends on it:

```nix
      # Root on tmpfs (ephemeral / impermanence). Disk layout is in ./disko.nix.
      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "mode=755" "size=6G" ];   # size to taste; it is RAM
      };
```

The host's attribute name comes from `vars.hostname`, so the `framework-13-pro` file names can stay as they are (rename them if you like; nothing refers to the paths).

If you are not on a Framework 13 Pro, also see [Different hardware](#different-hardware) below.

### 3. Credentials — pick one

**Plaintext (simplest).** Set both in `vars` and `secrets/` is never read:

```bash
mkpasswd -m sha-512   # paste the hash into vars as hashedPassword
```

```nix
  hashedPassword = "$6$…";
  git = { name = "Alice Example"; email = "alice@example.com"; };
```

**agenix (keeps credentials out of the repo).** The `.age` files here are encrypted to *this* machine's SSH host key and cannot be decrypted on yours, so you must re-create them:

```bash
# Generate a host key at the path age reads at boot (modules/system/users.nix)
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

Leave `hashedPassword` and `git` as `null` in `vars` to use this path.

### 4. Partition and install

```bash
# Destructive — formats the device in modules/hosts/framework-13-pro/disko.nix
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --mode disko --flake .#my-laptop

sudo nixos-install --flake .#my-laptop --no-root-password
sudo reboot
```

Note the `--flake` form: `disko.nix` reads `vars` and is a flake-parts module, so it can no longer be passed to disko as a bare file path.

`--no-root-password` is fine — there is no root login by design (`mutableUsers = false`, sudo via the `wheel` group). Your user's password comes from step 3.

After first boot, anything not declared in some feature's `home.persistence` / `environment.persistence` list (the core ones are in `modules/system/impermanence.nix`) is wiped on every reboot — that's impermanence working as intended.

## Different hardware

`vars` covers identity, not silicon. On anything but a Framework 13 Pro, these are hand-edits:

| what | where |
|---|---|
| `nixos-hardware.nixosModules.framework-intel-core-ultra-series3` | `modules/hosts/framework-13-pro.nix` — swap for your machine's module, or drop it |
| `hardware.intelgpu.driver = "xe"` — Panther Lake is xe-only; older Intel wants `i915` | `modules/hosts/framework-13-pro/hardware.nix` |
| tmpfs root size (`6G`, sized against 16GB of RAM) | `modules/hosts/framework-13-pro/hardware.nix` |
| Kernel — the NixOS default; Panther Lake needs ≥ 6.17 and `xe` ≥ 6.8 (nixos-hardware falls back to latest below that) | `modules/system/boot.nix` |
| Display scale `output."eDP-1".scale = 2.0` (2880x1920 panel → 1440x960 logical) | `modules/desktop/umbriel.nix` |
| Lock-screen box geometry, in that same 1440x960 logical space and pinned to `eDP-1` | `modules/desktop/noctalia.nix` |
| Cursor size `24`, the HiDPI-doubled value that goes with scale 2 | `modules/desktop/theming.nix` |
| Disk device and swap size (`32G`; hibernate is off, so this is overflow, not a RAM image) | `modules/hosts/framework-13-pro/disko.nix` |
| Fingerprint reader — no reader? set its two `true`s to `false` (don't delete the file; it also carries a PAM fix) | `modules/desktop/fingerprint.nix` |

The backlight node is *not* in this table: it used to be hardcoded (`intel_backlight`) and
now discovers itself at runtime — `modules/system/boot-defaults.nix` takes the first
writable `/sys/class/backlight/*`.

## Architecture reference

For module layout and conventions see [CLAUDE.md](./CLAUDE.md); subsystem detail (desktop, theming, impermanence, secrets) is in [agent_docs/](./agent_docs).
