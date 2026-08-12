{ pkgs, ... }:

{
  # Stylix owns system-wide theming: a single base16 scheme drives colors, fonts,
  # cursor, and icons across every supported target (GTK, Qt, console, Ghostty,
  # nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix
  # targets auto-inherit this config. Non-targets are left to their own theming:
  # Noctalia (built-in scheme), nixvim (default), Claude ("dark"), niri (default).
  # Plymouth uses the firmware BGRT boot logo (boot.nix) instead of the Stylix
  # themed splash, so this target would otherwise conflict on boot.plymouth.theme.
  stylix.targets.plymouth.enable = false;

  stylix = {
    enable = true;
    base16Scheme = {
      scheme = "Framework Anodized";
      author = "Robert McCoy (2026)";
      base00 = "1c1b1a"; # bg — dark keycap grey
      base01 = "262523"; # lighter bg / line numbers
      base02 = "35332f"; # selection
      base03 = "5e5952"; # comments
      base04 = "8c877f"; # status text
      base05 = "c8c3ba"; # fg — anodized aluminum
      base06 = "dfdbd3";
      base07 = "f2efe9";
      base08 = "e0503c"; # red — rust
      base09 = "ff5f1f"; # orange — Framework accent
      base0A = "e8a33d"; # yellow — amber
      base0B = "a3b565"; # green — moss
      base0C = "6fb3a8"; # cyan — muted teal
      base0D = "6e9bc4"; # blue — steel
      base0E = "c4879e"; # magenta — dusty rose
      base0F = "a5643c"; # brown — burnt sienna
    };
    polarity = "dark";

    # Window opacity. Bridged into programs.noctalia / niri layer-rules in
    # desktop.nix, since Stylix's noctalia-shell target no-ops against this
    # repo's programs.noctalia. terminal/applications stay opaque (1.0 default).
    opacity = {
      desktop = 0.85; # bar / widgets
      popups  = 0.90; # panels, launcher, control-center, notifications
    };

    fonts = {
      serif     = { package = pkgs.noto-fonts;                  name = "Noto Serif"; };
      sansSerif = { package = pkgs.adwaita-fonts;               name = "Adwaita Sans"; };
      monospace = { package = pkgs.nerd-fonts.fira-code;        name = "FiraCode Nerd Font"; };
      emoji     = { package = pkgs.noto-fonts-monochrome-emoji; name = "Noto Emoji"; };
      sizes.terminal = 11;
    };

    cursor = { package = pkgs.phinger-cursors; name = "phinger-cursors-dark"; size = 24; };
    icons  = {
      enable  = true;
      package = pkgs.papirus-icon-theme;
      dark    = "Papirus-Dark";
      light   = "Papirus-Light";
    };
  };

  # Keep Stylix's Qt style away from the polkit agent.
  #
  # Stylix's qt target (platform "qtct", the only value it supports) sets
  # `qt.style.name = "kvantum"`, which exports QT_STYLE_OVERRIDE=kvantum. That is
  # right for QWidget apps — libkvantum.so is installed and gets the base16 theme.
  # But Kvantum is a *widget* style and ships no QML module, and polkit-kde-agent
  # feeds QT_STYLE_OVERRIDE straight to its QML engine as a Quick Controls style.
  # It then does `import kvantum`, fails to build the dialog, and segfaults:
  #
  #   QQmlApplicationEngine failed to load component
  #   qrc:/qml/QuickAuthDialog.qml: module "kvantum" is not installed
  #   niri-flake-polkit.service: Main process exited, code=killed, status=11/SEGV
  #
  # So every GUI privilege prompt died before drawing — polkitd logged "FAILED to
  # authenticate" with no dialog, which is why `fprintd-enroll` returned
  # PermissionDenied instead of prompting.
  #
  # Setting QT_QUICK_CONTROLS_STYLE does NOT help: the agent inherits it and
  # overrides it with QT_STYLE_OVERRIDE at runtime anyway (measured — the service
  # had QT_QUICK_CONTROLS_STYLE=Fusion in its environment and still crashed).
  # Dropping the variable for this one unit is what actually works, confirmed by
  # running the agent by hand with it unset: the dialog rendered and authorization
  # succeeded. Cost is that the password dialog uses Qt's default style instead of
  # Kvantum; every other Qt app keeps the Stylix theme.
  systemd.user.services.niri-flake-polkit.serviceConfig.UnsetEnvironment = "QT_STYLE_OVERRIDE";
}
