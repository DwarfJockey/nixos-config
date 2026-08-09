{ ... }:

{
  networking = {
    hostName = "framework-13";
    networkmanager.enable = true;
  };

  # Network discovery (Nautilus) — resolve other hosts' .local names. No publish
  # block: that self-advertises this host, which nothing here consumes.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
