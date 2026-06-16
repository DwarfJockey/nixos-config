# "Tomorrow" — Chris Kempson's base16 Tomorrow scheme
# (https://github.com/chriskempson/base16-tomorrow-scheme). The dark variant is
# Tomorrow Night, the light variant is Tomorrow. base0D blue is the UI primary;
# base08 red the tertiary/error. The terminal block carries the base16 ANSI
# mapping (normal black..white = base00..07, bright black..white = base08..0F),
# which the Neovim matugen template reconstructs into base00-base0F. Consumed by
# Noctalia via programs.noctalia.customPalettes (modules/home-manager/desktop.nix).
let
  d = rec {                          # dark   (base16 Tomorrow Night)
    base00 = "#1d1f21"; base01 = "#282a2e"; base02 = "#373b41"; base03 = "#969896";
    base04 = "#b4b7b4"; base05 = "#c5c8c6"; base06 = "#e0e0e0"; base07 = "#ffffff";
    base08 = "#cc6666"; base09 = "#de935f"; base0A = "#f0c674"; base0B = "#b5bd68";
    base0C = "#8abeb7"; base0D = "#81a2be"; base0E = "#b294bb"; base0F = "#a3685a";
  };
  l = rec {                          # light  (base16 Tomorrow)
    base00 = "#ffffff"; base01 = "#e0e0e0"; base02 = "#d6d6d6"; base03 = "#8e908c";
    base04 = "#969896"; base05 = "#4d4d4c"; base06 = "#282a2e"; base07 = "#1d1f21";
    base08 = "#c82829"; base09 = "#f5871f"; base0A = "#eab700"; base0B = "#718c00";
    base0C = "#3e999f"; base0D = "#4271ae"; base0E = "#8959a8"; base0F = "#a3685a";
  };
in
{
  dark = {
    mSurface          = d.base00;
    mOnSurface        = d.base05;
    mSurfaceVariant   = d.base01;
    mOnSurfaceVariant = d.base04;
    mPrimary          = d.base0D;   # blue
    mOnPrimary        = d.base00;
    mSecondary        = d.base0C;   # aqua
    mOnSecondary      = d.base00;
    mTertiary         = d.base08;   # red
    mOnTertiary       = d.base00;
    mError            = d.base08;
    mOnError          = d.base00;
    mOutline          = d.base03;
    mShadow           = "#000000";
    mHover            = d.base02;
    mOnHover          = d.base06;
    terminal = {
      background  = d.base00;
      foreground  = d.base05;
      cursor      = d.base08;       # warm accent cursor (matches prior design intent)
      cursorText  = d.base00;
      selectionBg = d.base02;
      selectionFg = d.base07;
      normal  = { black = d.base00; red = d.base01; green = d.base02; yellow = d.base03;
                  blue = d.base04; magenta = d.base05; cyan = d.base06; white = d.base07; };
      bright  = { black = d.base08; red = d.base09; green = d.base0A; yellow = d.base0B;
                  blue = d.base0C; magenta = d.base0D; cyan = d.base0E; white = d.base0F; };
    };
  };

  light = {
    mSurface          = l.base00;
    mOnSurface        = l.base06;
    mSurfaceVariant   = l.base01;
    mOnSurfaceVariant = l.base04;
    mPrimary          = l.base0D;   # blue (dark on-color for legible fill)
    mOnPrimary        = l.base07;
    mSecondary        = l.base0C;
    mOnSecondary      = l.base07;
    mTertiary         = l.base08;
    mOnTertiary       = l.base07;
    mError            = l.base08;
    mOnError          = l.base07;
    mOutline          = l.base03;
    mShadow           = "#000000";
    mHover            = l.base02;
    mOnHover          = l.base07;
    terminal = {
      background  = l.base00;
      foreground  = l.base05;
      cursor      = l.base08;
      cursorText  = l.base00;
      selectionBg = l.base03;       # base03 (not base02) so selection is visible on the near-white bg
      selectionFg = l.base07;
      normal  = { black = l.base00; red = l.base01; green = l.base02; yellow = l.base03;
                  blue = l.base04; magenta = l.base05; cyan = l.base06; white = l.base07; };
      bright  = { black = l.base08; red = l.base09; green = l.base0A; yellow = l.base0B;
                  blue = l.base0C; magenta = l.base0D; cyan = l.base0E; white = l.base0F; };
    };
  };
}
