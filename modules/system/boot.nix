{
  flake.modules.nixos.pc = {
    boot = {
      # Kernel: the NixOS default (pkgs.linuxPackages). Panther Lake wants >= 6.17 for
      # the platform and >= 6.8 for the `xe` driver; nixos-hardware switches to
      # linuxPackages_latest by itself if the default ever falls below that floor.
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

      # Enable "Silent Boot". consoleLogLevel emits loglevel=; plymouth adds splash.
      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
