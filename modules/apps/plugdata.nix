{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      # Settings, externals and patches live in ~/Documents/plugdata, already persisted.
      # The UI scale is plugdata's own `global_scale` (Settings > Advanced), kept in that
      # directory's .settings: JUCE derives the X11 scale from XSETTINGS or GNOME tools,
      # neither of which exists here, and ignores Xft.dpi, so it would otherwise run 1x.
      #
      # Standalone only: the VST3/LV2/CLAP targets fail to link (PluginEditor
      # references PlugDataWindow::closeAllPatches, which only the standalone
      # sources define). Drop this override once nixpkgs' plugdata builds again.
      home.packages = [
        (pkgs.plugdata.overrideAttrs {
          buildFlags = [ "plugdata_standalone" ];
          installPhase = ''
            runHook preInstall
            cd ..
            install -Dm755 Plugins/Standalone/plugdata -t $out/bin
            install -Dm444 Resources/Icons/plugdata_logo_linux.png $out/share/icons/hicolor/512x512/apps/plugdata.png
            install -Dm444 Resources/Installer/plugdata.desktop -t $out/share/applications
            runHook postInstall
          '';
        })
      ];
    };
}
