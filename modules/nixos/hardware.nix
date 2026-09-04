{ ... }:

# Peripheral hardware enablement. The generated disk/kernel side of the machine is
# hosts/hardware-configuration.nix; this is the part that is a choice.
{
  hardware.bluetooth.enable = true;

  # Firmware updates via LVFS. Framework ships BIOS/EC/retimer updates through
  # fwupd; apply them with `fwupdmgr refresh` then `fwupdmgr update`.
  services.fwupd.enable = true;
}
