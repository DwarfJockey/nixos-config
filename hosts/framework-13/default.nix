{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default

    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/boot-defaults.nix
    ../../modules/nixos/power.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/greeter.nix
    ../../modules/nixos/theming.nix
    ../../modules/nixos/persistence.nix
    ../../modules/nixos/firmware.nix
    ../../modules/nixos/fingerprint.nix
    ../../modules/nixos/keyring.nix
    ../../modules/nixos/apps.nix
    ../../modules/nixos/users.nix
    ../../home/robert.nix
  ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    gimp
    xwayland-satellite
  ];

  system.stateVersion = "25.05";
}
