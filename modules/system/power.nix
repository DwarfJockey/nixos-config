{
  flake.modules.nixos.pc = {
    # Power & thermal management
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    services.thermald.enable = true;

    # PPD keeps the selected profile (performance, here) in its state dir; persisted so
    # the choice survives the ephemeral root instead of resetting to balanced.
    environment.persistence."/persist".directories = [ "/var/lib/power-profiles-daemon" ];

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
  };
}
