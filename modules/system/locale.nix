{ config, ... }:

let
  inherit (config) vars;
in
{
  flake.modules.nixos.pc = {
    time.timeZone = vars.timeZone;
    i18n.defaultLocale = vars.locale;
  };
}
