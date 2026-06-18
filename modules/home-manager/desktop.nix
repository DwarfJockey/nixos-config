{ config, lib, pkgs, inputs, ... }:

let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Bridge Stylix -> Noctalia: Stylix's own noctalia-shell target no-ops here (it
  # writes programs.noctalia-shell.colors, but this repo uses programs.noctalia),
  # so build a Noctalia custom palette from Stylix's base16 colors instead. The
  # m* mapping matches Stylix's noctalia-shell target; the terminal block follows
  # base16 slot order (Stylix themes real terminals directly — this is just for
  # Noctalia's internal palette completeness).
  stylixColors = config.lib.stylix.colors.withHashtag;
  # Window opacity owned by Stylix (set in theming.nix, propagated to HM via
  # followSystem). Bridged manually because Stylix's noctalia-shell target
  # no-ops against this repo's programs.noctalia.
  stylixOpacity = config.stylix.opacity;
  noctaliaVariant = with stylixColors; {
    mSurface = base00; mOnSurface = base05;
    mSurfaceVariant = base01; mOnSurfaceVariant = base04;
    mPrimary = base0D; mOnPrimary = base00;
    mSecondary = base0E; mOnSecondary = base00;
    mTertiary = base0C; mOnTertiary = base00;
    mError = base08; mOnError = base00;
    mOutline = base03; mShadow = base00;
    mHover = base0C; mOnHover = base00;
    terminal = {
      background = base00; foreground = base05; cursor = base08; cursorText = base00;
      selectionBg = base02; selectionFg = base07;
      normal = { black = base00; red = base01; green = base02; yellow = base03;
                 blue = base04; magenta = base05; cyan = base06; white = base07; };
      bright = { black = base08; red = base09; green = base0A; yellow = base0B;
                 blue = base0C; magenta = base0D; cyan = base0E; white = base0F; };
    };
  };
  # Single Stylix scheme (dark polarity); reuse it for both variants since mode=dark.
  noctaliaStylixPalette = { dark = noctaliaVariant; light = noctaliaVariant; };

  # Wallpaper: the vendored photo remapped onto the base16 palette (lutgen, with
  # luminosity preserved so the photo's structure survives the hue shift) and
  # then dimmed toward the theme background — a subtle, on-theme backdrop rather
  # than a busy neon photo. Built in the Nix store like any other asset, so it
  # survives the ephemeral root and keeps the niri overview backdrop filled.
  # Colors come from the scheme, so the wallpaper tracks it. Dim is tunable:
  # -colorize 55% = blend 55% toward base00 (higher = darker/flatter);
  # -modulate 100,80,100 = 80% saturation (lower = greyer).
  wallpaperSrc = ./wallpapers/demon-city-shinjuku.jpg;
  base16Palette = with config.lib.stylix.colors; [
    base00 base01 base02 base03 base04 base05 base06 base07
    base08 base09 base0A base0B base0C base0D base0E base0F
  ];
  themedWallpaper = pkgs.runCommand "wallpaper-themed.png" { } ''
    ${pkgs.lutgen}/bin/lutgen apply -P -o recolored.png ${wallpaperSrc} -- \
      ${lib.concatStringsSep " " base16Palette}
    ${pkgs.imagemagick}/bin/magick recolored.png \
      -modulate 100,80,100 \
      -fill "${stylixColors.base00}" -colorize 55% \
      $out
  '';

  # Material-3 elevation, approximated with niri's single drop shadow (niri can't
  # stack umbra+penumbra+ambient). color = MD3 key-shadow alpha 0.30 (#0000004D);
  # geometry blended toward the soft ambient layer. draw-behind-window = false so
  # the shadow stays outside the surface and doesn't bleed through translucent popups.
  baseShadow = {            # MD3 Level 1 — resting tiled windows + bar
    enable = true;
    softness = 4;
    spread = 0;
    offset = { x = 0; y = 1; };
    color = "#0000004D";
    draw-behind-window = false;
  };

  activeShadow = {          # MD3 Level 3 — active / raised window
    enable = true;
    softness = 8;
    spread = 1;
    offset = { x = 0; y = 3; };
    color = "#0000004D";
    draw-behind-window = false;
  };

  popupShadow = {           # MD3 Level 5 — floating windows, panels, popups
    enable = true;
    softness = 12;
    spread = 3;
    offset = { x = 0; y = 6; };
    color = "#0000004D";
    draw-behind-window = false;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.noctalia.homeModules.default
  ];

  # Niri
  programs.niri.settings = {
    outputs."eDP-1".scale = 2.0;

    hotkey-overlay.skip-at-startup = true;

    # Noctalia compat: lets Noctalia panels grab focus reliably.
    debug.honor-xdg-activation-with-invalid-serial = [];

    spawn-at-startup = [
      { command = ["noctalia"]; }
      { command = ["zen-twilight"]; }
      { command = ["steam" "-silent"]; }
      { command = ["1password" "--silent"]; }
    ];

    workspaces."1" = {};

    # Border/focus-ring colors come from niri-flake's stylix target
    # (stylix.targets.niri): border enabled, active = base0D / inactive = base03,
    # focus-ring off, cursor from stylix.cursor. We override only the width —
    # niri's default is 4; 2 logical px reads as a crisp thin accent on this 2×
    # display (colors stay target-driven via mkDefault).
    layout.border.width = 2;
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
        geometry-corner-radius = {
          bottom-left = 12.0;
          bottom-right = 12.0;
          top-left = 12.0;
          top-right = 12.0;
        };
      }
      { # Status bar (elevation 2)
        matches = [{ namespace = "^noctalia-bar"; }];
        shadow = baseShadow;
      }
    ];

    window-rules = [
      { # Rounded + clipped corners for all windows (Noctalia compat)
        geometry-corner-radius = {
          top-left = 15.0;
          top-right = 15.0;
          bottom-left = 15.0;
          bottom-right = 15.0;
        };
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
      horizontal-view-movement.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
      window-movement.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
      workspace-switch.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
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

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

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
    };
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

  # Noctalia shell
  programs.noctalia = {
    enable = true;
    package = noctaliaPkg;
    # Noctalia's own UI follows Stylix via this generated palette (see the let block).
    customPalettes.Stylix = noctaliaStylixPalette;
    settings = {
      theme = {
        mode           = "dark";
        source         = "custom";
        custom_palette = "Stylix";
      };

      # base16-recolored, dimmed wallpaper generated in the Nix store; see
      # themedWallpaper in the let block. Noctalia reads [wallpaper.default].path
      # from config.toml (a declarative, persisted setting).
      wallpaper = {
        default.path = "${themedWallpaper}";
        automation.enabled = false;
      };

      bar.main = {
        position = "top";
        enabled  = true;
        start  = [ "launcher" "workspaces" ];
        center = [ "notifications" "clock" "weather" ];
        end    = [ "tray" "clipboard" "volume" "bluetooth" "network" "battery" ];
        # Flat bar restyle. Neutral on_surface/outline roles (blue mPrimary only
        # on active states) so the bar reads like a libadwaita panel rather than
        # a purple-tinted (secondary) one.
        capsule            = false;
        capsule_opacity    = 0.0;
        capsule_border     = "outline";
        capsule_radius     = 0;
        color              = "on_surface";
        font_weight        = 400;
        thickness          = 32;
        background_opacity = stylixOpacity.desktop;
        padding            = 12;
        widget_spacing     = 12;
        radius             = 15;
        border_width       = 1.0;
        # Bar shadow stays niri-owned (anchored full-width surface; niri places
        # it correctly). Noctalia only draws shadows for its popups/panels.
        shadow             = false;
        contact_shadow     = false;
        margin_ends        = 0;
        margin_edge        = 0;
      };

      shell = {
        font_family = "Adwaita Sans";
        settings_show_advanced = true;
        app_icon_colorize = false;
        panel = {
          session_placement = "centered";
          transparency_mode = "glass";
          control_center_placement = "floating";
          open_near_click_control_center = true;
          # Noctalia draws popup/panel shadows (content-aware) since niri can't
          # place a layer-surface shadow on a floating popup card. Color = the
          # palette's mShadow (base00).
          shadow = true;
        };
        shadow.alpha = 0.55;
      };

      # dock.shadow defaults to true — disable so no Noctalia surface casts a shadow.
      dock.shadow = false;

      control_center.sidebar_section = "none";

      # Lock the session as soon as Noctalia is up, so the autologin boots
      # straight to the lock screen. Fires once per Noctalia start (per session).
      hooks.started = "noctalia msg session lock";

      location.auto_locate  = true;
      nightlight.enabled    = true;
      notification.position = "top_center";
      osd.position          = "bottom_center";
      weather.unit          = "imperial";

      widget = {
        battery       = { hide_when_full = true; show_label = false; };
        brightness.show_label = false;
        clock         = { anchor = false; format = "{:%l:%M %P}"; };
        network.show_label = false;
        notifications.hide_when_no_unread = true;
        tray.drawer   = true;
        volume.show_label = false;
        workspaces    = { display = "name"; minimal = true; };
      };
    };
  };

  # Zen Browser — Stylix themes it via its zen-browser target; tell it which
  # profile(s) to write userChrome/userContent into.
  stylix.targets.zen-browser.profileNames = [ "03bokykz.Default Profile" ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs._1password-gui ];
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;
      DisableFeedbackCommands = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
    profiles."03bokykz.Default Profile" = {
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        ublock-origin
        dearrow
        remove-youtube-s-suggestions
      ];
      id = 0;
      isDefault = true;
      settings = {
        "browser.ai.control.default"            = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText"       = "blocked";
        "browser.ai.control.sidebarChatbot"     = "blocked";
        "browser.ai.control.smartTabGroups"     = "blocked";
        "browser.ai.control.translations"       = "blocked";
      };
    };
  };

  # GTK / Qt — theme, icons, cursor, and fonts are owned by Stylix
  # (modules/nixos/theming.nix); these just enable the integrations.
  gtk.enable = true;
  qt.enable = true;

  # Ghostty — theme and font come from Stylix's ghostty target.
  programs.ghostty = {
    enable = true;
    settings = {
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
      ];
    };
  };

  # Senpai
  programs.senpai = {
    enable = true;
    config = {
      address = "robert-mccoy.com:6697";
      nickname = "dwarfjockey";
      username = "dwarfjockey";
      password-cmd = [ "cat" "/persist/home/robert/.config/senpai/password" ];
    };
  };
}
