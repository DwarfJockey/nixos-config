{ pkgs, ... }:

{
  # Power & thermal management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Always performance, on AC and battery alike. PPD's state dir isn't persisted, so
  # it would come back up on balanced every boot; this oneshot re-applies it.
  #
  # WantedBy PPD, not multi-user.target: upstream's PPD unit is now
  # `After=multi-user.target` + `WantedBy=graphical.target`, so hanging this
  # oneshot off multi-user.target (which forces Before=multi-user.target) plus
  # `After=power-profiles-daemon` formed an unbreakable ordering cycle. Binding
  # to PPD pulls us in and orders us right after it, wherever PPD starts.
  systemd.services.power-profile-performance = {
    description = "Set the performance power profile";
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  # UPower's default critical-battery action is HybridSleep, which writes a full
  # RAM image to swap and then suspends. Hibernation is deliberately disabled on
  # this host (no `resume=` on the kernel cmdline; hibernate was reverted in
  # 76a8ee0), so that image can never be restored — the write is pure waste and
  # the machine just s2idle-suspends at ~2% battery and drains to a cold boot
  # (lost work). PowerOff does a clean shutdown instead, which is the only action
  # that actually protects state without working hibernation.
  services.upower.criticalPowerAction = "PowerOff";

  # Suspend, not poweroff, for the power key. The lid already suspends by logind
  # default (HandleLidSwitchExternalPower follows HandleLidSwitch when unset); set
  # HandleLidSwitchExternalPower = "ignore" if ever driving an external display
  # with the lid closed.
  services.logind.settings.Login = {
    HandlePowerKey = "suspend"; # tap power = suspend, not poweroff
    HandlePowerKeyLongPress = "poweroff"; # long-press still hard powers off
  };
}
