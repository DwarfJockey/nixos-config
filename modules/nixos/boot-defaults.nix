{ pkgs, ... }:

let
  # Screen brightness -> 30% of the panel's max. intel_backlight's brightness
  # node is root-writable sysfs, so this runs as a system service.
  setBrightness = pkgs.writeShellScript "brightness-default" ''
    dev=/sys/class/backlight/intel_backlight
    [ -w "$dev/brightness" ] || exit 0
    max=$(cat "$dev/max_brightness")
    echo $(( max * 30 / 100 )) > "$dev/brightness"
  '';

  # Keyboard backlight -> lowest lit level (20/100). Two drivers expose the same
  # EC backlight — framework_laptop and cros_kbd_led_backlight — so write to both
  # LED nodes: each write drives the EC and updates that driver's cached value,
  # so neither re-asserts a stale 0 (e.g. after resume). Adjust 20 (0..100).
  setKbdBacklight = pkgs.writeShellScript "kbd-backlight-on" ''
    for led in framework_laptop::kbd_backlight chromeos::kbd_backlight; do
      echo 20 > "/sys/class/leds/$led/brightness" 2>/dev/null || true
    done
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
    description = "Set screen brightness to 30% at boot";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setBrightness;
    };
  };

  systemd.services.kbd-backlight-on = {
    description = "Set the keyboard backlight to its lowest lit level";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setKbdBacklight;
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
