{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Intermittent analog-audio fix. This board's analog codec (IDT 92HD95 —
  # internal speakers/headphone/mic) occasionally loses the HDA codec-wake race
  # after controller reset: it fails to assert its presence bit in time, the
  # driver latches only the HDMI codec (`hda codecs found, mask 4` instead of
  # `mask 5`), and the analog card never appears — leaving only "Dummy Output".
  # Happens on ~10% of boots regardless of driver (snd_hda_intel or SOF), so it's
  # a hardware/firmware timing issue, not a driver-selection one.
  #
  # This oneshot runs before greetd autologin (so the user's PipeWire sees the
  # corrected card from the start): if the analog codec didn't enumerate, it
  # rebinds the audio PCI device to re-run probing, retrying a few times since the
  # rebind can itself lose the race. Driver-agnostic — it reads the currently
  # bound driver from sysfs rather than hardcoding it.
  systemd.services.analog-codec-reprobe = {
    description = "Re-probe HDA analog codec (IDT 92HD95) if it missed enumeration";
    wantedBy = [ "multi-user.target" "post-resume.target" ];
    after = [ "sound.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.gnugrep pkgs.coreutils ];
    script = ''
      dev=0000:00:1f.3
      # Card creation is async during coldplug — wait up to ~5s for it.
      for i in $(seq 1 50); do [ -e /proc/asound/card0 ] && break; sleep 0.1; done
      for attempt in 1 2 3; do
        if grep -qil '92HD95' /proc/asound/card*/codec#* 2>/dev/null; then
          echo "analog codec present"; exit 0
        fi
        drv=$(basename "$(readlink /sys/bus/pci/devices/$dev/driver)")
        echo "analog codec missing (attempt $attempt) — rebinding $dev via $drv"
        echo "$dev" > /sys/bus/pci/drivers/$drv/unbind; sleep 1
        echo "$dev" > /sys/bus/pci/drivers/$drv/bind;   sleep 2
      done
      grep -qil '92HD95' /proc/asound/card*/codec#* 2>/dev/null
    '';
  };
}
