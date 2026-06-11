# "Framework" — a pure-neutral graphite UI with the Framework orange primary and
# a lavender secondary. Neutrals are R=G=B; accents carry all the color.
# Terminal colors follow the base16 ANSI mapping (bright == normal except
# black/white). Consumed wholesale by Noctalia via programs.noctalia.customPalettes
# (modules/home-manager/desktop.nix).
{
  dark = {
    mSurface          = "#141414";
    mOnSurface        = "#E4E4E4";
    mSurfaceVariant   = "#1f1f1f";
    mOnSurfaceVariant = "#B0B0B0";
    mPrimary          = "#FF7447";
    mOnPrimary        = "#1C1C1C";
    mSecondary        = "#DDD5FF";
    mOnSecondary      = "#121212";
    mTertiary         = "#BDA7F0";
    mOnTertiary       = "#121212";
    mError            = "#E66A6A";
    mOnError          = "#1C1C1C";
    mOutline          = "#6E6E6E";
    mShadow           = "#000000";
    mHover            = "#2B2B2B";
    mOnHover          = "#F2F2F2";
    terminal = {
      background  = "#141414";
      foreground  = "#E4E4E4";
      cursor      = "#FF7447";
      cursorText  = "#1C1C1C";
      selectionBg = "#3A3A3A";
      selectionFg = "#E4E4E4";
      normal = {
        black   = "#141414";
        red     = "#E66A6A";
        green   = "#9CC97F";
        yellow  = "#E5C07B";
        blue    = "#8FB1E8";
        magenta = "#BDA7F0";
        cyan    = "#7FC9C4";
        white   = "#E4E4E4";
      };
      bright = {
        black   = "#5E5E5E";
        red     = "#E66A6A";
        green   = "#9CC97F";
        yellow  = "#E5C07B";
        blue    = "#8FB1E8";
        magenta = "#BDA7F0";
        cyan    = "#7FC9C4";
        white   = "#F5F5F5";
      };
    };
  };

  light = {
    mSurface          = "#FAFAFA";
    mOnSurface        = "#1C1C1C";
    mSurfaceVariant   = "#ECECEC";
    mOnSurfaceVariant = "#5A5A5A";
    mPrimary          = "#D2541F";
    mOnPrimary        = "#FFFFFF";
    mSecondary        = "#6E4FC0";
    mOnSecondary      = "#FFFFFF";
    mTertiary         = "#6E4FC0";
    mOnTertiary       = "#FFFFFF";
    mError            = "#C5403A";
    mOnError          = "#FFFFFF";
    mOutline          = "#767676";
    mShadow           = "#000000";
    mHover            = "#E4E4E4";
    mOnHover          = "#1C1C1C";
    terminal = {
      background  = "#FAFAFA";
      foreground  = "#2A2A2A";
      cursor      = "#2A2A2A";
      cursorText  = "#FAFAFA";
      selectionBg = "#DADADA";
      selectionFg = "#2A2A2A";
      normal = {
        black   = "#FAFAFA";
        red     = "#C5403A";
        green   = "#4F8A3C";
        yellow  = "#B5841F";
        blue    = "#3A6BB5";
        magenta = "#6E4FC0";
        cyan    = "#2E8A82";
        white   = "#2A2A2A";
      };
      bright = {
        black   = "#A0A0A0";
        red     = "#C5403A";
        green   = "#4F8A3C";
        yellow  = "#B5841F";
        blue    = "#3A6BB5";
        magenta = "#6E4FC0";
        cyan    = "#2E8A82";
        white   = "#0F0F0F";
      };
    };
  };
}
