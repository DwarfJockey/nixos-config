{ pkgs, inputs, ... }:

{
  # ── Niri ─────────────────────────────────────────────────────────────────
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  # Disable niri-flake's default polkit agent — DMS provides its own
  systemd.user.services.niri-flake-polkit.enable = false;

  # ── DankGreeter (display manager) ────────────────────────────────────────
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/robert";
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "robert";
  };

  # ── XDG Portal ───────────────────────────────────────────────────────────
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode regardless of Stylix settings.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Hardware acceleration (Intel 12th gen) ───────────────────────────────
  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver
    pkgs.libva-vdpau-driver
    pkgs.libvdpau-va-gl
  ];

  # ── Power & thermal management ───────────────────────────────────────────
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── Desktop services ─────────────────────────────────────────────────────
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
