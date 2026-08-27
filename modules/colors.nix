# Shared colour helpers for the manual Stylix bridges. Not a module: a plain
# function, imported by the Umbriel and Noctalia shell configs (Home Manager) and
# the greeter (NixOS), the same way modules/wallpaper.nix is.
{ lib }:

{
  # Umbriel colours are #RRGGBB or #RRGGBBAA, so alpha is a two-hex-digit suffix.
  withAlpha = color: alpha: "${color}${alpha}";

  # `fg` composited over `bg` at `alpha` (0.0-1.0), the way adw-gtk3 writes its own
  # colours: `alpha(currentColor, 0.15)`. A naive per-channel sRGB lerp — the same
  # arithmetic GTK's mix() does, so the result is what GTK actually renders rather
  # than a gamma-correct improvement on it. Takes and returns "#RRGGBB"; an alpha
  # suffix on either input is ignored.
  #
  # Use this only where a real 8-digit colour can't go — Noctalia's *palette* parses
  # alpha and then masks it off (`token & 0x00FFFFFF` in its
  # src/theme/fixed_palette.cpp), so a composite has to be precomputed to reach it.
  # Config-side `ColorSpec` keys do keep alpha, so prefer `withAlpha` there.
  over =
    fg: bg: alpha:
    let
      channel =
        offset:
        let
          value = hex: lib.fromHexString (builtins.substring offset 2 hex);
          # lib.toHexString emits uppercase and unpadded, hence the toLower and the
          # fixed width: a channel of 5 would otherwise render as "5", not "05".
          blended = builtins.floor ((value fg) * alpha + (value bg) * (1.0 - alpha) + 0.5);
        in
        lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString blended));
    in
    "#${channel 1}${channel 3}${channel 5}";
}
