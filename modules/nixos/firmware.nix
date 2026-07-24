{ ... }:

{
  # Firmware updates via LVFS. Framework ships BIOS/EC/retimer updates through
  # fwupd; apply them with `fwupdmgr refresh` then `fwupdmgr update`.
  services.fwupd.enable = true;
}
