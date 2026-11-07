{ config, ... }:

let
  inherit (config) vars;
in
{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          extraEnv = {
            GAMEMODERUN = "1";
          };
          extraArgs = "-system-composer";
        };
        remotePlay.openFirewall = true;
      };
      programs.gamemode.enable = true;
      # Created by programs.gamemode; see apps/1password.nix on why they stay together.
      users.users.${vars.username}.extraGroups = [ "gamemode" ];
    };

  flake.modules.homeManager.pc = {
    home.persistence."/persist".directories = [ ".local/share/Steam" ];

    # An Umbriel autostart, not a user unit: libayatana-appindicator watches
    # NameOwnerChanged and re-registers its tray icon whenever the watcher shows up,
    # so Steam doesn't need ordering after Noctalia (compare _lib/tray-app.nix).
    programs.umbriel.settings.general.autostart = [ "steam -silent" ];
  };
}
