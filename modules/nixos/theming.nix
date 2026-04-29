{ config, pkgs, ... }:

let
  colors = config.lib.stylix.colors;

  recoloredCursors = pkgs.runCommand "phinger-cursors-recolored" {
    nativeBuildInputs = [ pkgs.lutgen pkgs.xcur2png pkgs.xcursorgen ];
  } ''
    src=${pkgs.phinger-cursors}/share/icons/phinger-cursors-dark
    out_theme=$out/share/icons/phinger-cursors-dark
    mkdir -p $out_theme/cursors
    cp $src/index.theme $out_theme/index.theme

    workdir=$(mktemp -d)
    for cursor_file in $src/cursors/*; do
      name=$(basename "$cursor_file")

      if [ -L "$cursor_file" ]; then
        cp -P "$cursor_file" "$out_theme/cursors/$name"
        continue
      fi

      framedir="$workdir/$name"
      mkdir -p "$framedir"
      ( cd "$framedir"
        xcur2png -d . "$cursor_file" -c config.in
        for png in *.png; do
          lutgen apply -o "recolored_$png" "$png" -- \
            "#${colors.base00}" "#${colors.base01}" "#${colors.base02}" "#${colors.base03}" \
            "#${colors.base04}" "#${colors.base05}" "#${colors.base06}" "#${colors.base07}" \
            "#${colors.base08}" "#${colors.base09}" "#${colors.base0A}" "#${colors.base0B}" \
            "#${colors.base0C}" "#${colors.base0D}" "#${colors.base0E}" "#${colors.base0F}"
          mv "recolored_$png" "$png"
        done
        xcursorgen config.in "$out_theme/cursors/$name"
      )
    done
  '';

  # Recolor structural icons (folders, mimetypes, devices, actions, etc.) to
  # the Stylix base16 palette. App icons keep their brand colors so logos stay
  # recognizable. Papirus-Dark's larger sizes are symlinked into Papirus, so
  # we have to walk both subthemes for the recolor to actually show up.
  recoloredPapirus = pkgs.runCommand "papirus-icon-theme-recolored" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p $out
    cp -r ${pkgs.papirus-icon-theme}/share $out/share
    chmod -R u+w $out/share/icons

    cd $out/share/icons

    find -L Papirus Papirus-Dark Papirus-Light -type f -name '*.svg' \
      \( -path '*/places/*' \
      -o -path '*/mimetypes/*' \
      -o -path '*/devices/*' \
      -o -path '*/actions/*' \
      -o -path '*/emblems/*' \
      -o -path '*/status/*' \
      -o -path '*/panel/*' \
      -o -path '*/symbolic/*' \
      -o -path '*/animations/*' \) \
      -print0 > $TMPDIR/svgs.null

    xargs -0 grep -ohiE '#[0-9a-f]{6}' < $TMPDIR/svgs.null \
      | tr 'A-F' 'a-f' | sort -u > $TMPDIR/papirus.colors

    python3 -c '
import sys
BASE16 = [
  "#${colors.base00}", "#${colors.base01}", "#${colors.base02}", "#${colors.base03}",
  "#${colors.base04}", "#${colors.base05}", "#${colors.base06}", "#${colors.base07}",
  "#${colors.base08}", "#${colors.base09}", "#${colors.base0A}", "#${colors.base0B}",
  "#${colors.base0C}", "#${colors.base0D}", "#${colors.base0E}", "#${colors.base0F}",
]
def rgb(h): return tuple(int(h[i:i+2],16) for i in (1,3,5))
def dist(a,b): return sum((x-y)**2 for x,y in zip(rgb(a),rgb(b)))
for src in sys.stdin.read().splitlines():
    src = src.strip().lower()
    if len(src) != 7 or not src.startswith("#"):
        continue
    dst = min(BASE16, key=lambda b: dist(src, b))
    print(f"s/{src}/{dst}/gi")
' < $TMPDIR/papirus.colors > $TMPDIR/recolor.sed

    xargs -0 sed -i -f $TMPDIR/recolor.sed < $TMPDIR/svgs.null
  '';
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    image =
      let c = config.lib.stylix.colors; in
      pkgs.runCommand "wallpaper.png" { buildInputs = [ pkgs.imagemagick ]; } ''
        magick -size 2880x1920 \
          gradient:"#${c.base00}"-"#${c.base01}" \
          \( -size 2880x1920 xc:none \
             -fill "#${c.base0B}18" \
             -draw "circle 2880,1920 1800,900" \
          \) -composite \
          \( -size 2880x1920 xc:none \
             -fill "#${c.base0D}12" \
             -draw "circle 0,0 800,800" \
          \) -composite \
          $out
      '';
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tomorrow-night.yaml";
    fonts = {
      serif = { package = pkgs.noto-fonts; name = "Noto Serif"; };
      sansSerif = { package = pkgs.adwaita-fonts; name = "Adwaita Sans"; };
      monospace = { package = pkgs.nerd-fonts.fira-code; name = "FiraCode Nerd Font"; };
      sizes = {
        applications = 11;
        terminal = 11;
      };
    };
    cursor = {
      package = recoloredCursors;
      name = "phinger-cursors-dark";
      size = 24;
    };
    icons = {
      enable = true;
      package = recoloredPapirus;
      dark = "Papirus-Dark";
      light = "Papirus";
    };
    targets = {
      console.enable = false;
      plymouth.enable = false;
    };
  };
}
