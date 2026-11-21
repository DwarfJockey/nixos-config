{ config, ... }:
let
  inherit (config) vars;
  secret = ../../secrets/kalshi-api.age;
in
{
  # API key id (line 1) + PEM private key, read by kalshi-balance. Declared only once
  # the file exists, so the config builds before the key is added (the bar widget
  # shows its error glyph until then). See agent_docs/secrets.md.
  flake.modules.nixos.pc =
    { lib, ... }:
    {
      age.secrets = lib.optionalAttrs (builtins.pathExists secret) {
        kalshi-api = {
          file = secret;
          owner = vars.username;
        };
      };
    };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    let
      balance = pkgs.writers.writePython3Bin "kalshi-balance" {
        libraries = [ pkgs.python3Packages.cryptography ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./_kalshi/kalshi_balance.py);
      # Build-time signing round-trip; a broken signer fails the build.
      checked = pkgs.runCommand "kalshi-balance-check" { } ''
        ${balance}/bin/kalshi-balance --check > $out
      '';
    in
    {
      home.packages = [ balance ];

      # Local Noctalia plugin; same install route as nix-monitor (desktop/noctalia.nix).
      # The `checked` reference forces the self-test into the build.
      xdg.dataFile."noctalia/plugins/kalshi".source = pkgs.runCommand "noctalia-plugin-kalshi" { } ''
        mkdir $out
        cp ${./_kalshi/plugin.toml} $out/plugin.toml
        substitute ${./_kalshi/kalshi.luau} $out/kalshi.luau \
          --replace-fail @BALANCE@ ${balance}/bin/kalshi-balance
        : ${checked}
      '';

      programs.noctalia.settings = {
        plugins.enabled = [ "local/kalshi" ];
        # Placed in the bottom bar by desktop/noctalia.nix.
        widget.kalshi.type = "local/kalshi:kalshi";
      };
    };
}
