{ inputs, ... }:

{
  # Root is tmpfs: everything outside /nix and /persist is wiped on reboot. The
  # impermanence module bind-mounts what is listed here back from /persist. This
  # file holds the core of both lists; each feature appends its own app's state
  # (environment.persistence / home.persistence) in its own file, and the module
  # system merges them.
  #
  # Directories, never single files: `files` entries are bind mounts, and rename()
  # onto a mount point is EBUSY, so anything written atomically never lands. The
  # NixOS `files` below are safe only because they are written once at install and
  # read-only afterwards.
  flake.modules.nixos.pc = {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/lib/AccountsService"
        "/var/log"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };

  flake.modules.homeManager.pc = {
    home.persistence."/persist".directories = [
      "Documents"
      "Downloads"
      "Pictures"
      "Projects"
      ".ssh"
    ];
  };
}
