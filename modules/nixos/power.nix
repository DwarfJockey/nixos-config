{ pkgs, ... }:

let
  # PPD doesn't auto-switch on AC/battery, so drive it from the AC-adapter state:
  # performance on mains, power-saver on battery. ACAD is the Framework's Mains
  # power_supply node.
  setPowerProfile = pkgs.writeShellScript "power-profile-auto" ''
    if [ "$(cat /sys/class/power_supply/ACAD/online 2>/dev/null)" = "1" ]; then
      ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance
    else
      ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver
    fi
  '';
in
{
  # Power & thermal management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # performance on AC, power-saver on battery. The oneshot does the D-Bus call
  # (ordered after PPD so the boot run doesn't race it); udev only kicks it on
  # plug/unplug with --no-block, which is safe inside a RUN+ rule.
  #
  # WantedBy PPD, not multi-user.target: upstream's PPD unit is now
  # `After=multi-user.target` + `WantedBy=graphical.target`, so hanging this
  # oneshot off multi-user.target (which forces Before=multi-user.target) plus
  # `After=power-profiles-daemon` formed an unbreakable ordering cycle. Binding
  # to PPD pulls us in and orders us right after it, wherever PPD starts.
  systemd.services.power-profile-auto = {
    description = "Set power profile from AC-adapter state";
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setPowerProfile;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ACAD", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart power-profile-auto.service"
  '';

  # UPower's default critical-battery action is HybridSleep, which writes a full
  # RAM image to swap and then suspends. Hibernation is deliberately disabled on
  # this host (no `resume=` on the kernel cmdline; hibernate was reverted in
  # 76a8ee0), so that image can never be restored — the write is pure waste and
  # the machine just s2idle-suspends at ~2% battery and drains to a cold boot
  # (lost work). PowerOff does a clean shutdown instead, which is the only action
  # that actually protects state without working hibernation.
  services.upower.criticalPowerAction = "PowerOff";

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

  # Removed: `suspend-quiesce-wedged-usb`, which disabled the internal USB2 ports
  # for Bluetooth (port10) and the fingerprint reader (port9) across suspend. They
  # used to fail to enumerate and retry forever, each retry an in-flight
  # usb_hub_wq hub_event that blocked the s2idle task freezer ("Freezing remaining
  # freezable tasks failed ... wq_busy=1"), aborting suspend and resuming to an
  # unresponsive screen. That no longer reproduces: both devices now enumerate
  # cleanly on every boot and resume, with no descriptor-read or enumerate errors
  # in the kernel log. If unresponsive resumes come back, check
  # `journalctl -b -k | grep -E 'unable to enumerate|Freezing.*failed'` first —
  # the workaround is in git history.
}
