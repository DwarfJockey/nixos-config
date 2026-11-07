{ config, ... }:

let
  inherit (config) vars;
  trayApp = import ../_lib/tray-app.nix;
in
{
  flake.modules.nixos.pc = {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ vars.username ];
    };
    # Created by the module above; naming it in extraGroups without the module is a
    # build-time assertion failure, so the two stay together.
    users.users.${vars.username}.extraGroups = [ "onepassword" ];

    # Browser integration: the desktop app only answers native-messaging calls from
    # binaries on its allowlist, and Zen's wrapped binary isn't on the built-in one.
    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        .zen-twilight-wrapped
      '';
      mode = "0755";
    };
  };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.persistence."/persist".directories = [
        ".config/1Password"
        ".local/share/1Password"
      ];

      # Tray app, started --silent (see _lib/tray-app.nix for why it is a unit).
      # System path, not pkgs._1password-gui: programs._1password-gui (above) owns
      # setuid wrappers tied to that exact package, and a second HM closure could drift.
      systemd.user.services."1password" = trayApp "1Password" "/run/current-system/sw/bin/1password --silent";

      # The Zen extension and the native-messaging host that connects it to the app.
      programs.zen-browser = {
        nativeMessagingHosts = [ pkgs._1password-gui ];
        profiles."03bokykz.Default Profile".extensions.packages = [
          pkgs.firefox-addons.onepassword-password-manager
        ];
      };
    };
}
