{
  # KiKit's template engine; CVE-2026-119716 only bites on untrusted templates.
  # Pinned to this version so the exception lapses once nixpkgs ships a fix.
  flake.modules.nixos.pc.nixpkgs.config.permittedInsecurePackages = [ "python3.14-pybars3-0.9.7" ];

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    let
      addons = with pkgs.kicadAddons; [
        kikit
        kikit-library
      ];
      # `addons` puts KiKit's Python backend on KiCad's Python path.
      kicad = pkgs.kicad.override { inherit addons; };

      # ponytail: nixpkgs' stock-data dir symlinks each top-level dir, so its
      # symlinkJoin can't merge the addons into scripting/ and silently drops
      # them. Rebuilt here with real dirs, same layout; delete once upstream
      # merges addons into a real scripting/ dir.
      stockData =
        pkgs.runCommand "kicad-stock-data-addons"
          {
            nativeBuildInputs = with pkgs; [
              lndir
              unzip
              jq
            ];
          }
          ''
            mkdir $out
            lndir -silent ${kicad.base}/share/kicad $out
            rm -r $out/template
            ln -s ${kicad.template_dir} $out/template
            for a in ${toString addons}; do
              unzip -q $a/addon.zip -d u
              id=$(jq -r .identifier u/metadata.json | tr . _)
              for d in u/*/; do
                mkdir -p $out/scripting/$(basename $d)
                mv $d $out/scripting/$(basename $d)/$id
              done
              rm -r u
            done
          '';
    in
    {
      # KiCad (wxGTK) freezes on native Wayland; force XWayland.
      home.packages = [
        (pkgs.symlinkJoin {
          name = "kicad-x11";
          paths = [ kicad ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for f in $out/bin/*; do
              wrapProgram "$f" --set GDK_BACKEND x11 --set NIX_KICAD10_STOCK_DATA_PATH ${stockData}
            done
          '';
        })
        pkgs.kikit
      ];
      home.persistence."/persist".directories = [
        ".config/kicad"
        ".local/share/kicad"
      ];
    };
}
