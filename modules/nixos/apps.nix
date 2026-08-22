{ lib, pkgs, vars, ... }:

lib.mkMerge [
  # 1Password
  (lib.mkIf vars.apps.onePassword {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ vars.username ];
    };

    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        .zen-twilight-wrapped
      '';
      mode = "0755";
    };
  })

  # Steam
  (lib.mkIf vars.apps.steam {
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
  })
]
