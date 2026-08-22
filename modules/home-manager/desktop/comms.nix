{ config, lib, inputs, vars, ... }:

{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Discord: Vesktop patched with Vencord, configured declaratively by nixcord.
  # Vesktop only (no vanilla client). Autostart is systemd.user.services.vesktop
  # (umbriel.nix — it has to be ordered after the tray watcher); the login session is
  # persisted via home.persistence (~/.config/vesktop) in home/default.nix.
  #
  # Tray settings are deliberately not declared here. `vesktopConfig` merges into
  # `config` above and lands in ~/.config/vesktop/settings/settings.json — the
  # *Vencord* file — so the minimizeToTray/tray keys that used to sit here never
  # reached Vesktop's main process, which reads ~/.config/vesktop/settings.json one
  # directory up. Both default to on in Vesktop anyway, and that file is persisted
  # and app-written; declaring it (programs.nixcord.vesktop.settings) would make it a
  # read-only store symlink and Vesktop could no longer save any of its own settings.
  programs.nixcord = lib.mkIf vars.apps.discord {
    enable = true;
    discord.enable = false;
    vesktop.enable = true;
    config = {
      useQuickCss = true;
    };
  };

  # Senpai (IRC). Server and nick come from vars.irc; set it to null to drop IRC.
  programs.senpai = lib.mkIf (vars.irc != null) {
    enable = true;
    config = {
      inherit (vars.irc) address nickname;
      username = vars.irc.nickname;
      # The password file is user-managed state, so it is read from the persisted
      # copy rather than declared here.
      password-cmd = [ "cat" "/persist${config.home.homeDirectory}/.config/senpai/password" ];
    };
  };
}
