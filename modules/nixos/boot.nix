{ pkgs, ... }:

{
  boot = {
    # Stable kernel, not linuxPackages_latest. This is a plain assignment on purpose:
    # nixos-hardware's framework-intel-core-ultra-series3 sets
    # `mkDefault pkgs.linuxPackages_latest`, but only below its 6.17 floor, which
    # pkgs.linux already clears — so pinning here costs nothing and keeps kernel
    # bumps deliberate. Panther Lake wants >= 6.17 for the platform and >= 6.8 for
    # the `xe` driver (hosts/hardware-configuration.nix); if graphics or audio
    # misbehave on new silicon, linuxPackages_latest is the first thing to try.
    kernelPackages = pkgs.linuxPackages;
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    plymouth = {
      enable = true;
      theme = "bgrt";
    };

    # Enable "Silent Boot"
    consoleLogLevel = 0;
    initrd = {
      systemd.enable = true;
      verbose = false;
    };
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "intel_pstate=active"
    ];
  };
}
