{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      # KiCad (wxGTK) freezes on native Wayland; force XWayland.
      home.packages = [
        (pkgs.symlinkJoin {
          name = "kicad-x11";
          paths = [ pkgs.kicad ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for f in $out/bin/*; do wrapProgram "$f" --set GDK_BACKEND x11; done
          '';
        })
      ];
      home.persistence."/persist".directories = [
        ".config/kicad"
        ".local/share/kicad"
      ];
    };
}
