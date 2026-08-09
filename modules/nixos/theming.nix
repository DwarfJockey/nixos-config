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
      scheme = "Over-Engineered Dark";
      author = "AI Color Theoretician (2026)";
      base00 = "050608";
      base01 = "0b0d12";
      base02 = "1c1f27";
      base03 = "464d5b";
      base04 = "80899b";
      base05 = "c8ceda";
      base06 = "e1e5ec";
      base07 = "f3f5f7";
      base08 = "e0707f";
      base09 = "dd7a46";
      base0A = "9ca021";
      base0B = "46b16d";
      base0C = "04afa5";
      base0D = "479eea";
      base0E = "a782e0";
      base0F = "d073b4";
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
}
