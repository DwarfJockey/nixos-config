# "Framework" — a graphite-anodized-aluminium palette with the signature
# Framework orange accent, built to blend with Framework Laptop 13 hardware.
# Consumed by Noctalia via programs.noctalia.customPalettes (modules/home-manager/desktop.nix).
{
  dark = {
    mSurface          = "#18191b";
    mOnSurface        = "#e6e7e9";
    mSurfaceVariant   = "#242629";
    mOnSurfaceVariant = "#a8abb0";
    mPrimary          = "#ff7447";
    mOnPrimary        = "#2a0d02";
    mSecondary        = "#bda7f0";
    mOnSecondary      = "#211a33";
    mTertiary         = "#9b9b9b";
    mOnTertiary       = "#1b1b1b";
    mError            = "#e5544b";
    mOnError          = "#2b0b09";
    mOutline          = "#34373b";
    mShadow           = "#000000";
    mHover            = "#2e3034";
    mOnHover          = "#e6e7e9";
    terminal = {
      background  = "#18191b";
      foreground  = "#e6e7e9";
      cursor      = "#fb5b2d";
      cursorText  = "#18191b";
      selectionBg = "#3a2a1f";
      selectionFg = "#f2f3f5";
      normal = {
        black   = "#2a2c2f";
        red     = "#e5544b";
        green   = "#9fb46f";
        yellow  = "#e0a458";
        blue    = "#6f9bb3";
        magenta = "#b58fc4";
        cyan    = "#6e9b9e";
        white   = "#c9ccd1";
      };
      bright = {
        black   = "#5a5d62";
        red     = "#f5786b";
        green   = "#b6c98a";
        yellow  = "#f0c07a";
        blue    = "#93b8cc";
        magenta = "#cdaedb";
        cyan    = "#8fbdbf";
        white   = "#f2f3f5";
      };
    };
  };

  light = {
    mSurface          = "#f3f3f2";
    mOnSurface        = "#1b1c1e";
    mSurfaceVariant   = "#e4e4e3";
    mOnSurfaceVariant = "#5a5d62";
    mPrimary          = "#cf4a14";
    mOnPrimary        = "#ffffff";
    mSecondary        = "#6e5a9c";
    mOnSecondary      = "#ffffff";
    mTertiary         = "#5c5c5c";
    mOnTertiary       = "#ffffff";
    mError            = "#c33a32";
    mOnError          = "#ffffff";
    mOutline          = "#c7c7c5";
    mShadow           = "#000000";
    mHover            = "#e4e4e3";
    mOnHover          = "#1b1c1e";
    terminal = {
      background  = "#f3f3f2";
      foreground  = "#1b1c1e";
      cursor      = "#cf4a14";
      cursorText  = "#f3f3f2";
      selectionBg = "#f0d6c6";
      selectionFg = "#1b1c1e";
      normal = {
        black   = "#2a2c2f";
        red     = "#c33a32";
        green   = "#5d7233";
        yellow  = "#9a6f1f";
        blue    = "#3c647d";
        magenta = "#6f4f86";
        cyan    = "#3c6f72";
        white   = "#c9ccd1";
      };
      bright = {
        black   = "#5a5d62";
        red     = "#e5544b";
        green   = "#9fb46f";
        yellow  = "#e0a458";
        blue    = "#6f9bb3";
        magenta = "#b58fc4";
        cyan    = "#6e9b9e";
        white   = "#1b1c1e";
      };
    };
  };
}
