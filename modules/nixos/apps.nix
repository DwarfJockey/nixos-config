{ pkgs, ... }:

{
  # ── 1Password ────────────────────────────────────────────────────────────
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "robert" ];
  };

  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      .zen-twilight-wrapped
    '';
    mode = "0755";
  };

  # ── Steam ────────────────────────────────────────────────────────────────
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
}
