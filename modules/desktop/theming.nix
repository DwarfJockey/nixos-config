{ inputs, ... }:

{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      # Stylix owns system-wide theming: a single base16 scheme drives colors, fonts,
      # cursor, and icons across every supported target (GTK, Qt, console, Ghostty,
      # nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix
      # targets auto-inherit this config. nixvim is the one thing left to its own
      # theming (Stylix targets vanilla programs.neovim only). Everything else Stylix
      # can't reach is bridged by hand off this scheme: Umbriel (no target at all),
      # Claude Code (apps/claude-code.nix), the greeter (greeter.nix), and Noctalia — which
      # does have a target, disabled in noctalia.nix because it misses the
      # themed wallpaper and the bar opacity. See agent_docs/theming.md.
      # Plymouth uses the firmware BGRT boot logo (system/boot.nix) instead of the Stylix
      # themed splash, so this target would otherwise conflict on boot.plymouth.theme.
      stylix.targets.plymouth.enable = false;

      stylix = {
        enable = true;
        base16Scheme = {
          scheme = "Framework Anodized";
          author = "Robert McCoy (2026)";
          base00 = "000000"; # bg
          base01 = "241f31"; # lighter bg / line numbers
          base02 = "3d3846"; # selection
          base03 = "5e5c64"; # comments
          base04 = "9a9996"; # status text
          base05 = "c0bfbc"; # fg
          base06 = "deddda";
          base07 = "ffffff";
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
        # background_opacity (noctalia.nix), since Stylix's noctalia-shell
        # target no-ops against this repo's programs.noctalia. Panels draw their own
        # transparency; terminal/applications stay opaque (1.0).
        opacity.desktop = 0.85; # bar / widgets

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
    };

  # GTK / Qt — theme, icons, cursor, and fonts are owned by Stylix (above); these
  # just enable the Home Manager integrations. dconf and the gtk-3.0/gtk-4.0 dirs
  # hold the apps' own runtime settings (file chooser state, bookmarks).
  flake.modules.homeManager.pc = {
    gtk.enable = true;
    qt.enable = true;
    home.persistence."/persist".directories = [
      ".config/dconf"
      ".config/gtk-3.0"
      ".config/gtk-4.0"
    ];
  };
}
