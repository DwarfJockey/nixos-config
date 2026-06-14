# "Framework" — graphite UI with the Framework orange primary and a lavender
# secondary. Neutrals follow a Delta Phi Star (ΔΦ*)-even ramp (even spacing in
# CIE L*^φ) that drifts toward the lavender accent as it lightens, so they carry
# a subtle lavender tint in both modes (no longer pure R=G=B). Accents still
# carry the saturated color. Terminal colors follow the base16 ANSI mapping
# (bright == normal except black/white). Consumed by Noctalia via
# programs.noctalia.customPalettes (modules/home-manager/desktop.nix).
let
  # ΔΦ*-even neutral ramps, dark/light background -> foreground.
  darkRamp  = [ "#191919" "#444347" "#63616B" "#7F7C8C" "#9894AA" "#B0ABC7" "#C7C0E4" "#DDD5FF" ];
  lightRamp = [ "#F4F2FA" "#DDDAE6" "#C6C1D1" "#ADA7BB" "#938BA3" "#766D88" "#554C69" "#2A2240" ];
  el = builtins.elemAt;
in
{
  dark = {
    # Neutrals from darkRamp (R7 #DDD5FF dropped here — it equals mPrimary).
    mSurface          = el darkRamp 0;   # #191919
    mOnSurface        = el darkRamp 5;   # #B0ABC7
    mSurfaceVariant   = el darkRamp 1;   # #444347
    mOnSurfaceVariant = el darkRamp 4;   # #9894AA
    mPrimary          = "#DDD5FF";
    mOnPrimary        = el darkRamp 0;
    mSecondary        = "#BDA7F0";
    mOnSecondary      = el darkRamp 0;
    mTertiary         = "#FF7447";
    mOnTertiary       = el darkRamp 0;
    mError            = "#E66A6A";
    mOnError          = el darkRamp 0;
    mOutline          = el darkRamp 3;   # #7F7C8C
    mShadow           = "#000000";
    mHover            = el darkRamp 2;   # #63616B
    mOnHover          = el darkRamp 6;   # #C7C0E4
    terminal = {
      background  = el darkRamp 0;
      foreground  = el darkRamp 5;
      cursor      = "#FF7447";
      cursorText  = el darkRamp 0;
      selectionBg = el darkRamp 5;
      selectionFg = el darkRamp 0;
      normal = {
        black   = el darkRamp 0;
        red     = el darkRamp 1;
        green   = el darkRamp 2;
        yellow  = el darkRamp 3;
        blue    = el darkRamp 4;
        magenta = el darkRamp 5;
        cyan    = el darkRamp 6;
        white   = el darkRamp 7;
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
    # Neutrals from lightRamp (L5 #766D88 dropped — keeps main text legible at L6).
    mSurface          = el lightRamp 0;  # #F4F2FA
    mOnSurface        = el lightRamp 6;  # #554C69
    mSurfaceVariant   = el lightRamp 1;  # #DDDAE6
    mOnSurfaceVariant = el lightRamp 4;  # #938BA3
    mPrimary          = "#6E4FC0";
    mOnPrimary        = el lightRamp 0;
    mSecondary        = "#6E4FC0";
    mOnSecondary      = el lightRamp 0;
    mTertiary         = "#D2541F";
    mOnTertiary       = el lightRamp 0;
    mError            = "#C5403A";
    mOnError          = el lightRamp 0;
    mOutline          = el lightRamp 3;  # #ADA7BB
    mShadow           = "#000000";
    mHover            = el lightRamp 2;  # #C6C1D1
    mOnHover          = el lightRamp 7;  # #2A2240
    terminal = {
      background  = el lightRamp 0;
      foreground  = el lightRamp 5;
      cursor      = "#D2541F";
      cursorText  = el lightRamp 0;
      selectionBg = el lightRamp 0;
      selectionFg = el lightRamp 5;
      normal = {
        black   = el lightRamp 0;
        red     = el lightRamp 1;
        green   = el lightRamp 2;
        yellow  = el lightRamp 3;
        blue    = el lightRamp 4;
        magenta = el lightRamp 5;
        cyan    = el lightRamp 6;
        white   = el lightRamp 7;
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
