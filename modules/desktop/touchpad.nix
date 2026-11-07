{
  # Two-finger press = right click. Umbriel applies only `tap` and `natural_scroll` to
  # touchpads and never calls libinput_device_config_click_set_method(), so libinput's
  # *default* click method is what the clickpad gets — button-areas everywhere except
  # Apple touchpads and a few model-quirked devices. This puts the clickpad in that set:
  # press anywhere with 1/2/3 fingers = left/right/middle. The bottom-right software
  # button area goes away with it.
  #
  # MatchUdevType alone is deliberately broad, and self-limiting: libinput returns
  # CLICK_METHOD_NONE for any touchpad that is not a clickpad, quirk or not, so this is a
  # no-op on hardware with real buttons — which is why it needs no "Different hardware"
  # row in README. /etc is store-backed, so there is nothing to persist.
  #
  # ponytail: borrows ModelChromebook for its click-method side effect — it is a model
  # label, not a click-method knob. Upgrade path: `click_method` under [input.touchpad]
  # upstream (~6 lines: a field in umbriel's Config::Input::Touchpad, one `t.text(...)` in
  # config.cpp:718, one libinput call beside the tap call in server_events.cpp:241), then
  # delete this.
  flake.modules.nixos.pc = {
    environment.etc."libinput/local-overrides.quirks".text = ''
      [Clickfinger on clickpads]
      MatchUdevType=touchpad
      ModelChromebook=1
    '';
  };
}
