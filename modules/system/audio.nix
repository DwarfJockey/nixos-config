{
  flake.modules.nixos.pc = {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # WirePlumber's saved volumes and default devices, restored at login.
  flake.modules.homeManager.pc.home.persistence."/persist".directories = [ ".local/state/wireplumber" ];
}
