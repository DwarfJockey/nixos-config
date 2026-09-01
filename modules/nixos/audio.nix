{ ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Removed with the move to the Framework 13 Pro: `analog-codec-reprobe`, a oneshot
  # that rebound the audio PCI function at 0000:00:1f.3 when the 12th-gen board's IDT
  # 92HD95 analog codec lost the HDA codec-wake race after controller reset (~10% of
  # boots, leaving only "Dummy Output"). That codec does not exist on this chassis —
  # the Pro drives side-firing stereo through SOF — so the guard could never match and
  # the unit would have failed on every boot. It is in git history if a comparable
  # enumeration race ever shows up here.
}
