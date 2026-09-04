{ pkgs, inputs, ... }:

{
  # nixpkgs-unstable gained its own programs.umbriel module (2026-08); it declares
  # the same option as inputs.umbriel.nixosModules.default, and NixOS treats a
  # twice-declared option as an eval error. Keep the flake's module — it ships in
  # lockstep with the git package this repo builds and with the Home Manager module
  # that writes the config — and drop nixpkgs' copy. Revisit if the input ever loses
  # its NixOS module, or if tracking nixpkgs' packaged umbriel (for the binary cache)
  # becomes worth the version lag.
  disabledModules = [ "programs/wayland/umbriel.nix" ];

  # Umbriel. The module installs the package system-wide and registers it in
  # services.displayManager.sessionPackages, which is what puts `Umbriel` in the
  # greeter's session picker (plain systemPackages .desktop files aren't enough).
  # The compositor's own config is Home Manager's — modules/home-manager/desktop/umbriel.nix.
  programs.umbriel.enable = true;

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
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Clickfinger on clickpads]
    MatchUdevType=touchpad
    ModelChromebook=1
  '';

  # Login (greetd + Noctalia Greeter)
  # The session slots are owned by modules/nixos/greeter.nix: it sets
  # default_session.command to noctalia-greeter-session, and nixpkgs' greetd
  # module defaults default_session.user to `greeter`. Do NOT set either here —
  # the greeter module reads default_session.user to own /var/lib/noctalia-greeter
  # and asserts that user exists, and a non-mkDefault command would shadow it.
  #
  # There is deliberately no `initial_session` (autologin). That was the previous
  # arrangement, and it made logind register the desktop as `Class=greeter`, which
  # logind treats as second-class: it refuses Lock/SetLockedHint on such a session,
  # so the compositor and Noctalia logged "Session does not support lock screen" on
  # every lock. Now the *greeter* is the greeter-class session, and the desktop
  # session it launches is a normal `Class=user` one.
  services.greetd.enable = true;

  # XDG Portal
  # xdg-desktop-portal-umbriel serves ScreenCast + Screenshot (screen sharing,
  # portal-aware screenshot tools). Its .portal file declares `UseIn=umbriel`,
  # matching the lowercase XDG_CURRENT_DESKTOP the compositor exports.
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      inputs.xdg-desktop-portal-umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    config.umbriel.default = [
      "umbriel"
      "gtk"
    ];
  };

  # Desktop services
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # "Open in Ghostty" in Nautilus' right-click menu — on a selected folder, on the
  # folder background, and on a plain file (which opens that file's parent). Ghostty
  # *bundles* the extension that draws it, share/nautilus-python/extensions/ghostty.py;
  # all that was ever missing is the two things that let nautilus reach it, both of
  # which look arbitrary in isolation:
  #
  # - share/nautilus-python/extensions is not in the default environment.pathsToLink,
  #   and that list is an allowlist filtering *both* /run/current-system/sw and
  #   /etc/profiles/per-user — which is the one that matters here, since ghostty comes
  #   from home.packages. Without the entry the .py is in the closure, unreachable.
  # - NAUTILUS_4_EXTENSION_DIR is what points nautilus at libnautilus-python.so;
  #   nothing sets it outside a services.desktopManager.gnome session. It lands in
  #   /etc/pam/environment, which pam_env reads at *session start* — so a change here
  #   needs a re-login, not just a switch.
  #
  # Do not add a second "open terminal here" extension on top of this. That is what
  # programs.nautilus-open-any-terminal was, and it labels a selected folder
  # "Open in Ghostty" exactly like ghostty.py does, so folders drew the entry twice.
  environment.systemPackages = [ pkgs.nautilus-python ];
  environment.pathsToLink = [ "/share/nautilus-python/extensions" ];
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR =
    "${pkgs.nautilus-python}/lib/nautilus/extensions-4";

  # GLib will not launch a Terminal=true desktop entry — nvim.desktop ("Neovim
  # wrapper", from nixpkgs' wrapNeovim), senpai.desktop — unless it can find a
  # terminal to host it. Its hardcoded fallback list is gnome-terminal, konsole,
  # xterm and friends; Ghostty is not on it and never will be, so with nothing else
  # installed the launch failed silently. The only general route is the thing GLib
  # checks *first*: an `xdg-terminal-exec` on PATH. This module supplies it and
  # writes /etc/xdg/xdg-terminals.list, read because /etc/xdg leads XDG_CONFIG_DIRS.
  #
  # The list is redundant today — xdg-terminal-exec would find Ghostty on its own
  # from `Categories=…TerminalEmulator` — but it pins the choice so a second terminal
  # arriving as somebody's dependency cannot silently win. Ghostty needs no ExecArg
  # entry: its desktop file declares `X-TerminalArgExec=-e`, which the spec reads.
  # Unlike NAUTILUS_4_EXTENSION_DIR above, this needs no re-login.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };
}
