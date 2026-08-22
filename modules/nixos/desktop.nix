{ pkgs, inputs, ... }:

{
  # Umbriel. The module installs the package system-wide and registers it in
  # services.displayManager.sessionPackages, which is what puts `Umbriel` in the
  # greeter's session picker (plain systemPackages .desktop files aren't enough).
  # The compositor's own config is Home Manager's — modules/home-manager/desktop/umbriel.nix.
  programs.umbriel.enable = true;

  # Login (greetd + Noctalia Greeter)
  # The session slots are owned by modules/nixos/greeter.nix: it sets
  # default_session.command to noctalia-greeter-session, and nixpkgs' greetd
  # module defaults default_session.user to `greeter`. Do NOT set either here —
  # the greeter module reads default_session.user to own /var/lib/noctalia-greeter
  # and asserts that user exists, and a non-mkDefault command would shadow it.
  #
  # There is deliberately no `initial_session` (autologin). That was the previous
  # arrangement, and it made logind register the desktop as `Class=greeter`, which
  # logind treats as second-class: it refuses Lock/SetLockedHint on such a session,
  # so the compositor and Noctalia logged "Session does not support lock screen" on
  # every lock. Now the *greeter* is the greeter-class session, and the desktop
  # session it launches is a normal `Class=user` one.
  services.greetd.enable = true;

  # XDG Portal
  # xdg-desktop-portal-umbriel serves ScreenCast + Screenshot (screen sharing,
  # portal-aware screenshot tools). Its .portal file declares `UseIn=umbriel`,
  # matching the lowercase XDG_CURRENT_DESKTOP the compositor exports.
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      inputs.xdg-desktop-portal-umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    config.umbriel.default = [
      "umbriel"
      "gtk"
    ];
  };

  # Desktop services
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
