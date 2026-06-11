# "Framework" — a graphite-anodized-aluminium palette with the signature
# Framework orange accent, built to blend with Framework Laptop 13 hardware.
# Consumed by Noctalia via programs.noctalia.customPalettes (modules/home-manager/desktop.nix).
{
  dark = {
    mSurface          = "#000000";
    mOnSurface        = "#E8E4DF";
    mSurfaceVariant   = "#1f1f1f";
    mOnSurfaceVariant = "#9C9C9C";
    mPrimary          = "#FF7447";
    mOnPrimary        = "#000000";
    mSecondary        = "#BDA7F0";
    mOnSecondary      = "#000000";
    mTertiary         = "#BDA7F0";
    mOnTertiary       = "#000000";
    mError            = "#E25D5D";
    mOnError          = "#000000";
    mOutline          = "#BDA7F0";
    mShadow           = "#000000";
    mHover            = "#2B2B2B";
    mOnHover          = "#F3F0EC";
    terminal = {
      background  = "#000000";
      foreground  = "#E8E4DF";
      cursor      = "#FF7447";
      cursorText  = "#000000";
      selectionBg = "#2B2B2B";
      selectionFg = "#F3F0EC";
      normal = {
        black   = "#1f1f1f";
        red     = "#E25D5D";
        green   = "#9CC97F";
        yellow  = "#E5B567";
        blue    = "#8FB7E8";
        magenta = "#BDA7F0";
        cyan    = "#7FCFC4";
        white   = "#E8E4DF";
      };
      bright = {
        black   = "#5E5E5E";
        red     = "#F07A7A";
        green   = "#B3DB99";
        yellow  = "#F0C885";
        blue    = "#A9C9F0";
        magenta = "#D2C2F7";
        cyan    = "#9CDED5";
        white   = "#FBFAF8";
      };
    };
  };

  light = {
    mSurface          = "#FBFAF8";
    mOnSurface        = "#191919";
    mSurfaceVariant   = "#EDEAE6";
    mOnSurfaceVariant = "#5E5E5E";
    mPrimary          = "#E05222";
    mOnPrimary        = "#FBFAF8";
    mSecondary        = "#7B5FC4";
    mOnSecondary      = "#FBFAF8";
    mTertiary         = "#7B5FC4";
    mOnTertiary       = "#FBFAF8";
    mError            = "#C43B3B";
    mOnError          = "#FBFAF8";
    mOutline          = "#7B5FC4";
    mShadow           = "#C9C4BE";
    mHover            = "#ECE7E1";
    mOnHover          = "#191919";
    terminal = {
      background  = "#FBFAF8";
      foreground  = "#191919";
      cursor      = "#E05222";
      cursorText  = "#FBFAF8";
      selectionBg = "#ECE7E1";
      selectionFg = "#191919";
      normal = {
        black   = "#FBFAF8";
        red     = "#C43B3B";
        green   = "#5A8A3C";
        yellow  = "#B07F2A";
        blue    = "#3B6BB0";
        magenta = "#323232";
        cyan    = "#7B5FC4";
        white   = "#191919";
      };
      bright = {
        black   = "#9C9C9C";
        red     = "#C43B3B";
        green   = "#5A8A3C";
        yellow  = "#B07F2A";
        blue    = "#3B6BB0";
        magenta = "#7B5FC4";
        cyan    = "#2E8A7E";
        white   = "#000000";
      };
    };
  };
}
