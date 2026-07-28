{ pkgs, inputs, ... }:

let
  niriPkg = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
in
{
  # Niri
  programs.niri = {
    enable = true;
    package = niriPkg;
  };

  # Login (greetd autologin)
  # Noctalia provides no greeter; log straight into a niri session. The disk is
  # not the security boundary on this host, so no password prompt at boot.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${niriPkg}/bin/niri-session";
      user = "robert";
    };
  };

  # XDG Portal
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Desktop services
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
