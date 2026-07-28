{ pkgs, ... }:

let
  # port10 = Bluetooth radio (ACPI \_SB_.PC00.XHCI.RHUB.HS10.BTRT),
  # port9  = fingerprint reader. Both are internal USB2 devices on usb3.
  ports = [ "usb3-port9" "usb3-port10" ];
  toggle = val: pkgs.writeShellScript "usb-wedged-ports-${val}" ''
    for p in ${toString (map (n: "/sys/bus/usb/devices/usb3/*/${n}/disable") ports)}; do
      [ -w "$p" ] && echo ${val} > "$p" || true
    done
    exit 0
  '';
in
{
  # Power & thermal management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Firmware memory training costs ~86s on every COLD boot (measured: the
  # firmware phase dominates `systemd-analyze`, everything after it is <5s).
  # It runs before NixOS loads, so no config can shorten it — but resuming from
  # suspend (s2idle) skips training entirely. Make suspend the default
  # off-behavior for the lid and power key so cold boots stay rare.
  #
  # nixpkgs API note: the old discrete options (services.logind.lidSwitch /
  # powerKey / extraConfig) are renamed to services.logind.settings.Login.*.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    # No dock/clamshell use here; set to "ignore"/"lock" if ever driving an
    # external display with the lid closed.
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend"; # tap power = suspend, not poweroff
    HandlePowerKeyLongPress = "poweroff"; # long-press still hard powers off
  };

  # The internal USB2 ports for Bluetooth (port10) and the fingerprint reader
  # (port9) currently fail to enumerate and retry forever (~8s each), every retry
  # an in-flight usb_hub_wq hub_event. On suspend that blocks the s2idle task
  # freezer (Freezing remaining freezable tasks failed ... wq_busy=1), so suspend
  # aborts and resume comes back with an unresponsive screen. Disable the ports
  # only across the suspend transition and re-enable them on resume — don't kill
  # them permanently, in case a full power-drain later revives the hardware.
  systemd.services.suspend-quiesce-wedged-usb = {
    description = "Quiesce non-enumerating internal USB ports (BT/fingerprint) across suspend";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    # WantedBy only governs starting. StopWhenUnneeded makes systemd stop this
    # unit once sleep.target deactivates on resume, which is what fires ExecStop
    # (re-enable the ports) — without it the RemainAfterExit unit lingers and the
    # ports stay disabled after resume.
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${toggle "1"}";
      ExecStop = "${toggle "0"}";
    };
  };
}
