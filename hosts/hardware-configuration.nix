{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "uas" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root on tmpfs (ephemeral / impermanence). Disk layout (boot/swap/nix/persist) is in ./disko.nix.
  # 6G of this machine's 16G: a ceiling rather than an allocation, but everything
  # outside /nix and /persist lives here and tmpfs pages compete for RAM.
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=755" "size=6G" ];
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # Panther Lake (Xe3) is driven by `xe`, not `i915` — but nixos-hardware's
  # framework-intel-core-ultra-series3 reaches the *generic* common/gpu/intel, which
  # still defaults to i915 (there is no panther-lake GPU module upstream), so the
  # driver is chosen here. That one option also puts the right module in
  # boot.initrd.kernelModules (hardware.intelgpu.loadInInitrd, on by default) and
  # fills hardware.graphics.extraPackages with intel-media-driver +
  # intel-compute-runtime + vpl-gpu-rt — hence no hand-written package list.
  hardware.graphics.enable = true;
  hardware.intelgpu = {
    driver = "xe";
    vaapiDriver = "intel-media-driver";
  };
}
