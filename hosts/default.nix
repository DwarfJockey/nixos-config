{ pkgs, inputs, vars, ... }:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default

    ./hardware-configuration.nix
    ./disko.nix
    ../modules/nixos/boot.nix
    ../modules/nixos/nix.nix
    ../modules/nixos/networking.nix
    ../modules/nixos/audio.nix
    ../modules/nixos/boot-defaults.nix
    ../modules/nixos/power.nix
    ../modules/nixos/desktop.nix
    ../modules/nixos/greeter.nix
    ../modules/nixos/theming.nix
    ../modules/nixos/persistence.nix
    ../modules/nixos/hardware.nix
    ../modules/nixos/fingerprint.nix
    ../modules/nixos/keyring.nix
    ../modules/nixos/apps.nix
    ../modules/nixos/users.nix
    ../home
  ];

  time.timeZone = vars.timeZone;
  i18n.defaultLocale = vars.locale;

  environment.systemPackages = with pkgs; [
    git
    curl
    gimp
  ];

  system.stateVersion = vars.stateVersion;
}
