{ pkgs, ... }:

{
  # Stylix owns system-wide theming: a single base16 scheme drives colors, fonts,
  # cursor, and icons across every supported target (GTK, Qt, console, Ghostty,
  # nushell, starship, Zen, …). Home Manager is a NixOS module, so its Stylix
  # targets auto-inherit this config. Non-targets are left to their own theming:
  # Noctalia (built-in scheme), nixvim (default), Claude ("dark"), niri (default).
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
    polarity = "dark";
    # Optional with an explicit scheme; set so wallpaper-using targets stay
    # consistent. Noctalia still owns the live desktop wallpaper.
    image = ../../modules/home-manager/wallpapers/framework-pro-7.png;

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
