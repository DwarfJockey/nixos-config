# Shared colour definitions for the manual Stylix bridges. Not a module: a plain
# function, imported by the Umbriel and Noctalia shell configs (Home Manager) and
# the greeter (NixOS), the same way modules/wallpaper.nix is.
{ lib }:

let
  # `fg` composited over `bg` at `alpha` (0.0-1.0), the way adw-gtk3 writes its own
  # colours: `alpha(currentColor, 0.15)`. A naive per-channel sRGB lerp — the same
  # arithmetic GTK's mix() does, so the result is what GTK actually renders rather
  # than a gamma-correct improvement on it. Takes and returns "#RRGGBB"; an alpha
  # suffix on either input is ignored.
  #
  # Use this only where a real 8-digit colour can't go — Noctalia's *palette* parses
  # alpha and then masks it off (`token & 0x00FFFFFF` in its
  # src/theme/fixed_palette.cpp), so a composite has to be precomputed to reach it.
  # Config-side `ColorSpec` keys do keep alpha, so a plain "#RRGGBBAA" works there.
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
in
{
  inherit over;

  # The Noctalia colour roles, from a `config.lib.stylix.colors.withHashtag` set.
  # Both Noctalia surfaces in this repo render from this one mapping: the greeter
  # (modules/nixos/greeter.nix) takes these keys as-is, and the shell
  # (modules/home-manager/desktop/noctalia.nix) prefixes them into its own mFoo
  # spelling. It lives here because the greeter is system-scoped and cannot reach
  # into Home Manager for it.
  #
  # Three roles are composites rather than base16 slots, so the shell's chrome
  # matches the adw-gtk3 windows beside it: `outline` is adw's @borders
  # (mix(currentColor, @window_bg_color, 0.85)), where base03 reads far brighter
  # than every GTK hairline on screen; `hover` and `tertiary` are its neutral
  # lightening of the surface below (alpha(currentColor, 0.07-0.1)) rather than the
  # base0C teal Noctalia and Stylix's own target both put there. `on_hover` and
  # `on_tertiary` follow to base05: they are the label drawn *on* that fill, and
  # base00 over a dark fill would be black on black.
  palette = c: {
    surface = c.base00;
    on_surface = c.base05;
    surface_variant = c.base01;
    on_surface_variant = c.base04;
    # base09, the Framework orange, rather than Stylix's noctalia target's base0D:
    # the accent role moves, the base16 slots don't (base0D stays the terminal and
    # syntax blue). GTK apps keep their blue accent — Stylix hardcodes base0D in its
    # gtk.css template — so the shell and a window's own buttons differ on purpose.
    primary = c.base09;
    on_primary = c.base00;
    secondary = c.base0E;
    on_secondary = c.base00;
    tertiary = over c.base05 c.base01 0.08;
    on_tertiary = c.base05;
    error = c.base08;
    on_error = c.base00;
    outline = over c.base05 c.base00 0.15;
    shadow = c.base00;
    hover = over c.base05 c.base01 0.08;
    on_hover = c.base05;
  };
}
