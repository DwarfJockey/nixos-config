{ inputs, ... }:

{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Discord: Vesktop patched with Vencord, configured declaratively by nixcord.
  # Vesktop only (no vanilla client). Autostart is systemd.user.services.vesktop
  # (niri.nix — it has to be ordered after the tray watcher); the login session is
  # persisted via home.persistence (~/.config/vesktop) in home/robert.nix.
  #
  # Tray settings are deliberately not declared here. `vesktopConfig` merges into
  # `config` above and lands in ~/.config/vesktop/settings/settings.json — the
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

  # Senpai
  programs.senpai = {
    enable = true;
    config = {
      address = "robert-mccoy.com:6697";
      nickname = "dwarfjockey";
      username = "dwarfjockey";
      password-cmd = [ "cat" "/persist/home/robert/.config/senpai/password" ];
    };
  };
}
