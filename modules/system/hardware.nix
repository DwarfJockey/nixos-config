# Peripheral hardware enablement. The generated disk/kernel side of the machine is
# hosts/framework-13-pro/hardware.nix; this is the part that is a choice.
{
  flake.modules.nixos.pc = {
    hardware.bluetooth.enable = true;
    environment.persistence."/persist".directories = [ "/var/lib/bluetooth" ]; # pairings

    # Firmware updates via LVFS: fwupd is enabled by nixos-hardware. Framework ships
    # BIOS/EC/retimer updates through it; apply them with `fwupdmgr refresh` then
    # `fwupdmgr update`.
  };
}
