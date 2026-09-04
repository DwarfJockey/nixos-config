# Edit this file, then `sudo nixos-rebuild switch --flake .#<hostname>`.
# Everything else in the repo reads from here. See README.md for a fresh install.
#
# `null` means off throughout.
{
  # Identity
  hostname = "framework-13-pro";
  username = "dwarfjockey";

  # Locale
  timeZone = "America/New_York";
  locale = "en_US.UTF-8";
  keyboardLayout = "us"; # greeter + compositor XKB layout

  # Where this repo is checked out, relative to $HOME.
  # Used by the nix-monitor bar widget's Update button.
  configDir = "Projects/nixos-config";

  # Disk. DESTRUCTIVE — disko formats this device during install.
  diskDevice = "/dev/nvme0n1";
  swapSize = "32G";

  # Credentials. `null` = use the agenix secrets in secrets/, which are encrypted to
  # *this* host's SSH key and cannot be decrypted on another machine. Set these to
  # plain values to skip agenix entirely (README: "Install on your own machine").
  hashedPassword = null; # `mkpasswd -m sha-512`
  git = null; # { name = "..."; email = "..."; }

  # IRC (senpai). null disables it.
  irc = {
    address = "robert-mccoy.com:6697";
    nickname = "dwarfjockey";
  };

  # Opinionated apps — flip off what you don't want.
  apps = {
    onePassword = true;
    steam = true;
    discord = true;
    fingerprint = true;
  };

  stateVersion = "25.05";
}
