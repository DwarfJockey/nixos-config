{ config, ... }:

let
  inherit (config) vars;
in
{
  flake.modules.nixos.pc = {
    networking = {
      hostName = vars.hostname;
      networkmanager.enable = true;
    };

    # Saved Wi-Fi networks.
    environment.persistence."/persist".directories = [ "/etc/NetworkManager/system-connections" ];

    # Network discovery (Nautilus) — resolve other hosts' .local names. No publish
    # block: that self-advertises this host, which nothing here consumes.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };
}
