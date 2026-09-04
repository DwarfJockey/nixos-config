{ pkgs, ... }:

{
  # Stylix owns system-wide theming: a single base16 scheme drives colors, fonts,
  # cursor, and icons across every supported target (GTK, Qt, console, Ghostty,
  # nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix
  # targets auto-inherit this config. nixvim is the one thing left to its own
  # theming (Stylix targets vanilla programs.neovim only). Everything else Stylix
  # can't reach is bridged by hand off this scheme: Umbriel (no target at all),
  # Claude Code (home/default.nix), the greeter (greeter.nix), and Noctalia — which
  # does have a target, disabled in desktop/noctalia.nix because it misses the
  # themed wallpaper and the bar opacity. See agent_docs/theming.md.
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

  # Polkit agent. niri-flake used to ship one (niri-flake-polkit.service, running
  # polkit-kde-agent) and it needed `UnsetEnvironment = "QT_STYLE_OVERRIDE"`
  # because Stylix's qt target exports QT_STYLE_OVERRIDE=kvantum — Kvantum is a
  # *widget* style with no QML module, and the agent fed that variable to its QML
  # engine as a Quick Controls style, so it segfaulted before drawing any dialog
  # and every GUI privilege prompt silently failed. When Umbriel replaced niri the
  # unit was dropped on the assumption that Noctalia registers its own agent
  # (`polkit_position` in desktop/noctalia.nix implies as much) — but in practice
  # (checked via `journalctl --user -u noctalia.service`, zero polkit-related
  # lines all boot, and `busctl --user list | grep -i polkit`, no agent owner)
  # nothing ever answers an interactive polkit request: `fprintd-enroll` and
  # `pkexec` both get an instant, promptless PermissionDenied. So the unit is
  # back, using mate-polkit instead of polkit-kde-agent specifically because it's
  # GTK — it never touches QT_STYLE_OVERRIDE, so the Kvantum crash can't recur.
  systemd.user.services.polkit-agent = {
    description = "Polkit authentication agent (mate-polkit)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
      Restart = "on-failure";
    };
  };
}
