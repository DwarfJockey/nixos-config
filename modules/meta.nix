{ lib, ... }:

{
  # Every personal/host-specific value. Feature files read it from the top-level
  # config (`{ config, ... }: let inherit (config) vars; in …`) and close over it in
  # the NixOS / Home Manager modules they define, so nothing is threaded through
  # specialArgs. Edit the values below, then
  # `sudo nixos-rebuild switch --flake .#<hostname>`. See README.md for a fresh install.
  #
  # Optional apps have no toggle here: a feature is on because its file exists under
  # modules/apps/ — delete the file, or rename it with a leading `_` (paths containing
  # `/_` are not imported), to drop it. Values used by one feature only live in that
  # feature (the disk layout in hosts/, the IRC server in apps/senpai.nix).
  options.vars = lib.mkOption {
    type = lib.types.raw;
    description = "Personal and host-specific values shared by every feature module.";
  };

  config.vars = {
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

    # Credentials. `null` = use the agenix secrets in secrets/, which are encrypted to
    # *this* host's SSH key and cannot be decrypted on another machine. Set these to
    # plain values to skip agenix entirely (README: "Install on your own machine").
    hashedPassword = null; # `mkpasswd -m sha-512`
    git = null; # { name = "..."; email = "..."; }

    stateVersion = "25.05";
  };
}
