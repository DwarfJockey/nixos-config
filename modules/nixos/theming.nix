{ pkgs, ... }:

{
  # Stylix owns system-wide theming: a single base16 scheme drives colors, fonts,
  # cursor, and icons across every supported target (GTK, Qt, console, Ghostty,
  # nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix
  # targets auto-inherit this config. Non-targets are left to their own theming:
  # Noctalia (built-in scheme), nixvim (default), Claude ("dark"), Umbriel (bridged
  # by hand in modules/home-manager/desktop/umbriel.nix — it has no Stylix target).
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
      base0E = "bda7f0"; # magenta — violet
      base0F = "a5643c"; # brown — burnt sienna
    };
    polarity = "dark";

    # Window opacity. `.desktop` is bridged into programs.noctalia's bar
    # background_opacity (desktop/noctalia.nix), since Stylix's noctalia-shell
    # target no-ops against this repo's programs.noctalia. `.popups` has no
    # consumer here — Umbriel layer rules carry blur but no opacity, so Noctalia
    # draws its own panel transparency. terminal/applications stay opaque (1.0).
    opacity = {
      desktop = 0.85; # bar / widgets
      popups = 0.90; # panels, launcher, control-center, notifications
    };

    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sansSerif = {
        package = pkgs.adwaita-fonts;
        name = "Adwaita Sans";
      };
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-monochrome-emoji;
        name = "Noto Emoji";
      };
      sizes.terminal = 11;
    };

    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
    };
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
  };

  # No polkit agent unit here on purpose. niri-flake shipped one
  # (niri-flake-polkit.service, running polkit-kde-agent), and it needed
  # `UnsetEnvironment = "QT_STYLE_OVERRIDE"` because Stylix's qt target exports
  # QT_STYLE_OVERRIDE=kvantum — Kvantum is a *widget* style with no QML module, and
  # the agent fed that variable to its QML engine as a Quick Controls style, so it
  # segfaulted before drawing any dialog and every GUI privilege prompt silently
  # failed. Umbriel brings no agent, and Noctalia registers its own (native, not
  # Qt), so both the unit and the workaround are gone. If a prompt ever stops
  # appearing, check `busctl --user list | grep -i polkit` for an agent owner
  # before assuming this needs restoring.
}
