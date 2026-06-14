{ pkgs, ... }:

{
  # Fonts
  # System font set + fontconfig defaults. Colors and shell theming are owned by
  # Noctalia (see modules/home-manager/desktop.nix); this module only provides
  # the font stack that used to come from Stylix.
  fonts = {
    packages = [
      pkgs.noto-fonts
      pkgs.adwaita-fonts
      pkgs.nerd-fonts.fira-code
      pkgs.noto-fonts-monochrome-emoji
    ];

    fontconfig.defaultFonts = {
      serif     = [ "Noto Serif" ];
      sansSerif = [ "Adwaita Sans" ];
      monospace = [ "FiraCode Nerd Font" ];
      emoji     = [ "Noto Emoji" ];
    };
  };
}
