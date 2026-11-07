{ inputs, ... }:

let
  trayApp = import ../_lib/tray-app.nix;
in
{
  flake.modules.homeManager.pc =
    { config, ... }:
    {
      imports = [ inputs.nixcord.homeModules.nixcord ];

      # Login session and Vesktop's own settings.
      home.persistence."/persist".directories = [ ".config/vesktop" ];

      # Discord: Vesktop patched with Vencord, configured declaratively by nixcord.
      # Vesktop only (no vanilla client).
      #
      # Tray settings are deliberately not declared here. `vesktopConfig` merges into
      # `config` below and lands in ~/.config/vesktop/settings/settings.json — the
      # *Vencord* file — so the minimizeToTray/tray keys that used to sit here never
      # reached Vesktop's main process, which reads ~/.config/vesktop/settings.json one
      # directory up. Both default to on in Vesktop anyway, and that file is persisted
      # and app-written; declaring it (programs.nixcord.vesktop.settings) would make it a
      # read-only store symlink and Vesktop could no longer save any of its own settings.
      programs.nixcord = {
        enable = true;
        discord.enable = false;
        vesktop.enable = true;
        config = {
          useQuickCss = true;
        };
      };

      # Tray app (see _lib/tray-app.nix). finalPackage is nixcord's Vencord-patched
      # build; vesktop.package is the plain input.
      systemd.user.services.vesktop = trayApp "Vesktop (Discord)" "${config.programs.nixcord.finalPackage.vesktop}/bin/vesktop --start-minimized";
    };
}
