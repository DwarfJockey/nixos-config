# Themed wallpaper, shared by the Noctalia shell (home-manager) and the Noctalia
# greeter (NixOS). Not a NixOS/HM module — a plain function, imported and called
# from both. Identical arguments produce an identical derivation, so Nix builds
# it once and both consumers point at the same store path.
#
# The vendored photo is remapped onto the base16 palette (lutgen, with luminosity
# preserved so the photo's structure survives the hue shift) and then dimmed
# toward the theme background — a subtle, on-theme backdrop rather than a busy
# neon photo. Built in the Nix store like any other asset, so it survives the
# ephemeral root and keeps the niri overview backdrop filled.
#
# Colors come from the scheme, so the wallpaper tracks it. Dim is tunable:
#   -colorize 30%       blend 30% toward base00 (higher = darker/flatter)
#   -modulate 100,80,100  80% saturation (lower = greyer)
{
  pkgs,
  lib,
  # config.lib.stylix.colors — the bare baseXX attrs plus a .withHashtag set.
  colors,
}:

let
  wallpaperSrc = ./home-manager/wallpapers/acrylic-pour-magenta-cyan.jpg;
  base16Palette = with colors; [
    base00 base01 base02 base03 base04 base05 base06 base07
    base08 base09 base0A base0B base0C base0D base0E base0F
  ];
in
pkgs.runCommand "wallpaper-themed.png" { } ''
  ${pkgs.lutgen}/bin/lutgen apply -P -o recolored.png ${wallpaperSrc} -- \
    ${lib.concatStringsSep " " base16Palette}
  ${pkgs.imagemagick}/bin/magick recolored.png \
    -modulate 100,80,100 \
    -fill "${colors.withHashtag.base00}" -colorize 30% \
    $out
''
