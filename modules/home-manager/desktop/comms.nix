{ inputs, ... }:

{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Discord: Vesktop patched with Vencord, configured declaratively by nixcord.
  # Vesktop only (no vanilla client). Autostart is handled by niri's
  # spawn-at-startup (niri.nix); the login session is persisted via
  # home.persistence (~/.config/vesktop) in home/robert.nix.
  programs.nixcord = {
    enable = true;
    discord.enable = false;
    vesktop.enable = true;
    config = {
      useQuickCss = true;
    };
    vesktopConfig = {
      minimizeToTray = true;
      tray = true;
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
