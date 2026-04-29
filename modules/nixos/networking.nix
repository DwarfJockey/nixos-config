{ ... }:

{
  networking = {
    hostName = "framework-13";
    networkmanager.enable = true;
  };

  # ── Network discovery (Nautilus) ──────────────────────────────────────────
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
