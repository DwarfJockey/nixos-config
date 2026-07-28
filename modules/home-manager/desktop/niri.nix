{ config, lib, pkgs, inputs, ... }:

let
  # Window/popup opacity owned by Stylix (set in theming.nix, propagated to HM via
  # followSystem).
  stylixOpacity = config.stylix.opacity;

  # Material-3 elevation, approximated with niri's single drop shadow (niri can't
  # stack umbra+penumbra+ambient). color = MD3 key-shadow alpha 0.30 (#0000004D);
  # geometry blended toward the soft ambient layer. draw-behind-window = false so
  # the shadow stays outside the surface and doesn't bleed through translucent popups.
  mkShadow = { softness, spread, y }: {
    enable = true;
    color = "#0000004D";
    draw-behind-window = false;
    inherit softness spread;
    offset = { x = 0; inherit y; };
  };
  baseShadow   = mkShadow { softness = 4;  spread = 0; y = 1; };  # MD3 L1 — resting tiled windows + bar
  activeShadow = mkShadow { softness = 8;  spread = 1; y = 3; };  # MD3 L3 — active / raised window
  popupShadow  = mkShadow { softness = 12; spread = 3; y = 6; };  # MD3 L5 — floating windows, panels, popups

  # Uniform corner radius for all four corners.
  corners = r: { top-left = r; top-right = r; bottom-left = r; bottom-right = r; };

  # Shared spring for view/window/workspace motion.
  spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };

  # Mod+N focuses workspace N; Mod+Ctrl+N moves the column there. Generated over 1..9.
  workspaceBinds = lib.listToAttrs (lib.concatMap (n: [
    { name = "Mod+${toString n}";      value.action.focus-workspace = n; }
    { name = "Mod+Ctrl+${toString n}"; value.action.move-column-to-workspace = n; }
  ]) (lib.range 1 9));
in
{
  # Niri
  programs.niri.settings = {
    outputs."eDP-1".scale = 2.0;

    hotkey-overlay.skip-at-startup = true;

    # Noctalia compat: lets Noctalia panels grab focus reliably.
    debug.honor-xdg-activation-with-invalid-serial = [];

    spawn-at-startup = [
      # Noctalia is started by systemd.user.services.noctalia (in noctalia.nix), not
      # here — a niri-spawned scope inherited the 90s stop timeout and stalled shutdown.
      { command = ["zen-twilight"]; }
      { command = ["steam" "-silent"]; }
      { command = ["1password" "--silent"]; }
      { command = ["vesktop" "--start-minimized"]; }
    ];

    workspaces."1" = {};

    # Border/focus-ring colors come from niri-flake's stylix target
    # (stylix.targets.niri): border enabled, active = base0D / inactive = base03,
    # focus-ring off, cursor from stylix.cursor. We override only the width —
    # niri's default is 4; 2 logical px reads as a crisp thin accent on this 2×
    # display (colors stay target-driven via mkDefault).
    layout.border.width = 1;
    layout.struts.bottom = 4;
    layout.struts.top = 4;
    layout.shadow = baseShadow;

    input.touchpad = {
      dwt            = true;
      natural-scroll = true;
      scroll-method  = "two-finger";
      tap            = false;
      click-method   = "clickfinger";
    };

    layer-rules = [
      { # Wallpaper sits in the overview backdrop
        matches = [{ namespace = "^noctalia-backdrop"; }];
        place-within-backdrop = true;
      }
      { # Panels / popups. Shadow is drawn by Noctalia itself, not niri: niri
        # can't clip a layer-surface shadow to a floating popup's visible card
        # (it shadows the whole surface incl. invisible margins), so these
        # surfaces' shadows would land at the surface edge, far from the card.
        matches = [{ namespace = "^noctalia-"; }];
        excludes = [
          { namespace = "^noctalia-bar"; }
          { namespace = "^noctalia-backdrop"; }
          { namespace = "^noctalia-wallpaper"; }
        ];
        opacity = stylixOpacity.popups;
        # 12px matches libadwaita's popover/menu radius.
        geometry-corner-radius = corners 12.0;
      }
      { # Status bar (elevation 2)
        matches = [{ namespace = "^noctalia-bar"; }];
        shadow = baseShadow;
      }
    ];

    window-rules = [
      { # Rounded + clipped corners for all windows (Noctalia compat)
        geometry-corner-radius = corners 15.0;
        clip-to-geometry = true;
      }
      { # Active windows (elevation 4)
        matches = [{ is-active = true; }];
        shadow = activeShadow;
      }
      { # Floating windows (elevation 8)
        matches = [{ is-floating = true; }];
        shadow = popupShadow;
      }
      { # Ghostty
        matches = [{ app-id = "com.mitchellh.ghostty"; }];
        default-column-width = { proportion = 2.0 / 3.0; };
      }
      { # Zen Twilight
        matches = [{ app-id = "zen-twilight"; }];
        open-on-workspace = "1";
        default-column-width = { proportion = 1.0; };
      }
      { # Zen Twilight Picture-in-picture
        matches = [
          {
            app-id = "zen-twilight";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
        default-floating-position = {
          x = 32;
          y = 32;
          relative-to = "bottom-right";
        };
        default-column-width = { fixed = 480; };
        default-window-height = { fixed = 270; };
      }
      { # Steam toasts
        matches = [
          {
            app-id = "steam";
            title = "r#'^notificationtoasts_\d+_desktop$'#";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
      }
      { # Gnome Text Editor
        matches = [ { app-id = "org.gnome.TextEditor"; } ];
        default-column-width = { proportion = 2. / 3.; };
      }
      { # Noctalia Settings
        matches = [ { app-id = "^dev\\.noctalia\\.Noctalia\\.Settings$"; } ];
        open-floating = true;
        default-column-width = { fixed = 540; };
        default-window-height = { fixed = 460; };
      }
    ];

    animations = {
      window-open.kind.easing = { curve = "ease-out-expo"; duration-ms = 250; };
      window-close.kind.easing = { curve = "ease-out-expo"; duration-ms = 200; };
      horizontal-view-movement.kind.spring = spring;
      window-movement.kind.spring = spring;
      workspace-switch.kind.spring = spring;
    };

    binds = {
      # Core Noctalia binds
      "Mod+Space".action.spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
      "Mod+S".action.spawn     = ["noctalia" "msg" "panel-toggle" "control-center"];
      "Mod+Comma".action.spawn = ["noctalia" "msg" "settings-toggle"];

      # Session
      "Mod+Shift+E".action.quit.skip-confirmation = true;
      "Mod+Shift+P".action.power-off-monitors     = [];
      "Super+L".action.spawn = ["noctalia" "msg" "session" "lock"];

      # Apps
      "Mod+T".action.spawn      = "ghostty";
      "Mod+B".action.spawn      = "zen-twilight";
      "Mod+E".action.spawn      = "nautilus";

      # Windows
      "Mod+Q".action.close-window                                   = [];
      "Mod+F".action.maximize-column                                = [];
      "Mod+Shift+F".action.fullscreen-window                        = [];
      "Mod+C".action.center-column                                  = [];
      "Mod+Ctrl+C".action.center-visible-columns                    = [];
      "Mod+Ctrl+F".action.expand-column-to-available-width          = [];
      "Mod+V".action.toggle-window-floating                         = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      # Focus column/window
      "Mod+Left".action.focus-column-left   = [];
      "Mod+Right".action.focus-column-right = [];
      "Mod+Down".action.focus-window-down   = [];
      "Mod+Up".action.focus-window-up       = [];
      "Mod+H".action.focus-column-left      = [];
      "Mod+L".action.focus-column-right     = [];
      "Mod+J".action.focus-window-down      = [];
      "Mod+K".action.focus-window-up        = [];
      "Mod+Home".action.focus-column-first  = [];
      "Mod+End".action.focus-column-last    = [];

      # Focus monitor
      "Mod+Shift+Left".action.focus-monitor-left   = [];
      "Mod+Shift+Right".action.focus-monitor-right = [];
      "Mod+Shift+Up".action.focus-monitor-up       = [];
      "Mod+Shift+Down".action.focus-monitor-down   = [];

      # Move column/window
      "Mod+Ctrl+Left".action.move-column-left     = [];
      "Mod+Ctrl+Right".action.move-column-right   = [];
      "Mod+Ctrl+Down".action.move-window-down     = [];
      "Mod+Ctrl+Up".action.move-window-up         = [];
      "Mod+Ctrl+H".action.move-column-left        = [];
      "Mod+Ctrl+L".action.move-column-right       = [];
      "Mod+Ctrl+J".action.move-window-down        = [];
      "Mod+Ctrl+K".action.move-window-up          = [];
      "Mod+Ctrl+Home".action.move-column-to-first = [];
      "Mod+Ctrl+End".action.move-column-to-last   = [];

      # Move column to monitor
      "Mod+Ctrl+Shift+Left".action.move-column-to-monitor-left   = [];
      "Mod+Ctrl+Shift+Right".action.move-column-to-monitor-right = [];
      "Mod+Ctrl+Shift+Up".action.move-column-to-monitor-up       = [];
      "Mod+Ctrl+Shift+Down".action.move-column-to-monitor-down   = [];

      # Column/window sizing
      "Mod+Minus".action.set-column-width        = "-10%";
      "Mod+Equal".action.set-column-width        = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      "Mod+R".action.reset-window-height         = [];

      # Workspaces
      "Mod+Tab".action.focus-workspace-previous          = [];
      "Mod+U".action.focus-workspace-down                = [];
      "Mod+I".action.focus-workspace-up                  = [];
      "Mod+Shift+U".action.move-column-to-workspace-down = [];
      "Mod+Shift+I".action.move-column-to-workspace-up   = [];

      # Overview
      "Mod+Grave".action.toggle-overview = [];

      # Screenshots (niri-native)
      "Print".action.screenshot             = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window  = [];

      # Audio (via Noctalia — shows OSD overlay)
      "XF86AudioRaiseVolume".action.spawn  = ["noctalia" "msg" "volume-up"];
      "XF86AudioLowerVolume".action.spawn  = ["noctalia" "msg" "volume-down"];
      "XF86AudioMute".action.spawn         = ["noctalia" "msg" "volume-mute"];
      "XF86AudioMicMute".action.spawn      = ["noctalia" "msg" "mic-mute"];

      # Brightness (via Noctalia — shows OSD overlay)
      "XF86MonBrightnessUp".action.spawn   = ["noctalia" "msg" "brightness-up"];
      "XF86MonBrightnessDown".action.spawn = ["noctalia" "msg" "brightness-down"];
      # Mod+1..9 focus-workspace / Mod+Ctrl+1..9 move-column-to-workspace (generated).
    } // workspaceBinds;
  };

  # Append raw KDL that niri-flake's typed settings don't expose to the
  # niri-flake-generated config.kdl.
  xdg.configFile.niri-config.source = lib.mkForce (
    inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package (
      config.programs.niri.finalConfig + ''

        // Background blur (niri 26.4+). Appended as raw KDL because niri-flake's
        // typed settings don't expose `background-effect` yet. xray is false on all
        // background blurs so the blur samples the windows behind, not the wallpaper.

        layer-rule {
            match namespace="^noctalia-"
            background-effect {
                xray false
            }
        }
      ''
    )
  );
}
