{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/theming.nix
    ../../modules/nixos/persistence.nix
    ../../modules/nixos/apps.nix
    ../../modules/nixos/users.nix
    ../../home/robert.nix
  ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    python3
    vim
    gimp
    samba
    xwayland-satellite
  ];

  security.sudo.wheelNeedsPassword = true;

  system.stateVersion = "25.05";
}
