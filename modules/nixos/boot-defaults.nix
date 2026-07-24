{ pkgs, ... }:

let
  # Screen brightness -> 50% of the panel's max. intel_backlight's brightness
  # node is root-writable sysfs, so this runs as a system service.
  setBrightness = pkgs.writeShellScript "brightness-default" ''
    dev=/sys/class/backlight/intel_backlight
    [ -w "$dev/brightness" ] || exit 0
    max=$(cat "$dev/max_brightness")
    echo $(( max / 2 )) > "$dev/brightness"
  '';

  # Keyboard backlight -> fully on. Two drivers expose the same EC backlight —
  # framework_laptop and cros_kbd_led_backlight — so write to both LED nodes:
  # each write drives the EC and updates that driver's cached value, so neither
  # re-asserts a stale 0 (e.g. after resume). Lower the 100 (0..100) to dim.
  setKbdBacklight = pkgs.writeShellScript "kbd-backlight-on" ''
    for led in framework_laptop::kbd_backlight chromeos::kbd_backlight; do
      echo 100 > "/sys/class/leds/$led/brightness" 2>/dev/null || true
    done
  '';

  # Battery charge limit -> 80%, to extend battery lifespan. The framework_laptop
  # module (nixos-hardware) exposes charge_control_end_threshold as root-writable
  # sysfs. The guard keeps this a no-op if the node/name ever changes.
  setChargeLimit = pkgs.writeShellScript "battery-charge-limit" ''
    f=/sys/class/power_supply/BAT1/charge_control_end_threshold
    [ -w "$f" ] && echo 80 > "$f" || true
  '';

  # Audio volume -> 50%. Lives in the user's PipeWire graph, so this runs as a
  # user service. The default sink can lag WirePlumber's start, so retry until
  # wpctl finds it.
  setVolume = pkgs.writeShellScript "volume-default" ''
    for _ in $(seq 1 20); do
      if ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5; then
        exit 0
      fi
      sleep 0.5
    done
  '';
in
{
  systemd.services.brightness-default = {
    description = "Set screen brightness to 50% at boot";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setBrightness;
    };
  };

  systemd.services.kbd-backlight-on = {
    description = "Turn the keyboard backlight on";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setKbdBacklight;
    };
  };

  systemd.services.battery-charge-limit = {
    description = "Limit battery charge to 80%";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setChargeLimit;
    };
  };

  # Re-assert the keyboard backlight after waking from sleep (the EC drops it
  # on suspend).
  powerManagement.resumeCommands = ''
    ${setKbdBacklight}
  '';

  systemd.user.services.volume-default = {
    description = "Set default audio volume to 50% at login";
    wantedBy = [ "default.target" ];
    after = [ "wireplumber.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setVolume;
    };
  };
}
