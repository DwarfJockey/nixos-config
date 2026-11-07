{ config, ... }:

let
  inherit (config) vars;
in
{
  flake.modules.homeManager.pc =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.gh ];
      home.persistence."/persist".directories = [ ".config/gh" ]; # gh auth

      # Git
      programs.git = {
        enable = true;
        # Identity comes from an agenix secret at runtime (secrets/git-identity.age,
        # registered in system/users.nix) so name/email never live in repo
        # source. git silently ignores the include if the path is absent. Setting
        # vars.git puts it in the repo instead and skips agenix — see meta.nix.
        includes = lib.optional (vars.git == null) { path = "/run/agenix/git-identity"; };
        settings.user = lib.mkIf (vars.git != null) vars.git;
        settings.credential."https://github.com".helper = "!gh auth git-credential";
      };
    };
}
