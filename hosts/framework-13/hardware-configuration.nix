{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root on tmpfs (ephemeral / impermanence)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=755" "size=12G" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/09559925-2eb5-4ef3-a721-f0cefd7dc0b9";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "ssd" "noatime" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/09559925-2eb5-4ef3-a721-f0cefd7dc0b9";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd" "ssd" "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E2A2-965F";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-partuuid/fef1e0d6-f8b3-4e6e-ba0d-0cfbf80b5cd4"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;
}
