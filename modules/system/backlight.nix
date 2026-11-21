{
  flake.modules.nixos.pc = {
    # Screen and keyboard backlight keep their last level. systemd-backlight@ already
    # saves every backlight/kbd LED at shutdown and restores it at boot; its state dir
    # just has to outlive the tmpfs root.
    environment.persistence."/persist".directories = [ "/var/lib/systemd/backlight" ];

    # The EC drops the keyboard backlight on suspend, and systemd-backlight only runs
    # at boot/shutdown, so carry the level across sleep by hand. Two drivers expose the
    # same EC LED (framework_laptop and cros_kbd_led_backlight); write both so neither
    # keeps a stale cached value.
    powerManagement.powerDownCommands = ''
      cat /sys/class/leds/framework_laptop::kbd_backlight/brightness > /run/kbd-backlight 2>/dev/null || true
    '';
    powerManagement.resumeCommands = ''
      if [ -s /run/kbd-backlight ]; then
        for led in framework_laptop::kbd_backlight chromeos::kbd_backlight; do
          cat /run/kbd-backlight > "/sys/class/leds/$led/brightness" 2>/dev/null || true
        done
      fi
    '';
  };
}
