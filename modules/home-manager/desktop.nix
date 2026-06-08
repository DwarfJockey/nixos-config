{ config, lib, pkgs, inputs, ... }:

let
  colors = config.lib.stylix.colors;

  baseShadow = {
    enable = true;
    softness = 20;
    spread = 0;
    offset = { x = 0; y = 4; };
    color = "#00000040";
    draw-behind-window = true;
  };

  activeShadow = {
    enable = true;
    softness = 30;
    spread = 2;
    offset = { x = 0; y = 8; };
    color = "#00000050";
    draw-behind-window = true;
  };

  popupShadow = {
    enable = true;
    softness = 40;
    spread = 4;
    offset = { x = 0; y = 12; };
    color = "#00000060";
    draw-behind-window = true;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.dms-plugin-registry.modules.default
  ];

  # ── Niri ───────────────────────────────────────────────────────────────────
  programs.niri.settings = {
    outputs."eDP-1".scale = 2.0;

    hotkey-overlay.skip-at-startup = true;

    spawn-at-startup = [
      { command = ["zen-twilight"]; }
      { command = ["steam" "-silent"]; }
      { command = ["1password" "--silent"]; }
      { command = ["sh" "-c" "for i in $(seq 1 30); do dms ipc call lock lock && exit 0; sleep 1; done"]; }
    ];

    workspaces."1" = {};

    layout.border.enable = false;
    layout.struts.bottom = 8;
    layout.struts.top = 8;
    layout.shadow = baseShadow;

    input.touchpad = {
      dwt            = true;
      natural-scroll = true;
      scroll-method  = "two-finger";
      tap            = false;
      click-method   = "clickfinger";
    };

    layer-rules = [
      { # Popup windows (elevation 8)
        matches = [{ namespace = "^dms:.*"; }];
        excludes = [{ namespace = "^dms:bar$"; }];
        shadow = popupShadow;
        geometry-corner-radius = {
          bottom-left = 10.0;
          bottom-right = 10.0;
          top-left = 10.0;
          top-right = 10.0;
        };
      }
      { # Status bar (elevation 2)
        matches = [{ namespace = "^dms:bar$"; }];
        shadow = baseShadow;
      }
    ];

    window-rules = [
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
    ];

    animations = {
      window-open.kind.easing = { curve = "ease-out-expo"; duration-ms = 250; };
      window-close.kind.easing = { curve = "ease-out-expo"; duration-ms = 200; };
      horizontal-view-movement.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
      window-movement.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
      workspace-switch.kind.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.001; };
    };

    binds = {
      # ── Session ────────────────────────────────────────────────────────────
      "Mod+Shift+E".action.quit.skip-confirmation = true;
      "Mod+Shift+P".action.power-off-monitors     = [];
      "Super+L".action.spawn = ["dms" "ipc" "call" "lock" "lock"];

      # ── Apps ───────────────────────────────────────────────────────────────
      "Mod+T".action.spawn      = "ghostty";
      "Mod+B".action.spawn      = "zen-twilight";
      "Mod+E".action.spawn      = "nautilus";

      # ── Windows ────────────────────────────────────────────────────────────
      "Mod+Q".action.close-window                                   = [];
      "Mod+F".action.maximize-column                                = [];
      "Mod+Shift+F".action.fullscreen-window                        = [];
      "Mod+C".action.center-column                                  = [];
      "Mod+Ctrl+C".action.center-visible-columns                    = [];
      "Mod+Ctrl+F".action.expand-column-to-available-width          = [];
      "Mod+V".action.toggle-window-floating                         = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      # ── Focus column/window ────────────────────────────────────────────────
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

      # ── Focus monitor ──────────────────────────────────────────────────────
      "Mod+Shift+Left".action.focus-monitor-left   = [];
      "Mod+Shift+Right".action.focus-monitor-right = [];
      "Mod+Shift+Up".action.focus-monitor-up       = [];
      "Mod+Shift+Down".action.focus-monitor-down   = [];

      # ── Move column/window ─────────────────────────────────────────────────
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

      # ── Move column to monitor ─────────────────────────────────────────────
      "Mod+Ctrl+Shift+Left".action.move-column-to-monitor-left   = [];
      "Mod+Ctrl+Shift+Right".action.move-column-to-monitor-right = [];
      "Mod+Ctrl+Shift+Up".action.move-column-to-monitor-up       = [];
      "Mod+Ctrl+Shift+Down".action.move-column-to-monitor-down   = [];

      # ── Column/window sizing ───────────────────────────────────────────────
      "Mod+Minus".action.set-column-width        = "-10%";
      "Mod+Equal".action.set-column-width        = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      "Mod+R".action.reset-window-height         = [];

      # ── Workspaces ─────────────────────────────────────────────────────────
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

      # ── Overview ───────────────────────────────────────────────────────────
      "Mod+Grave".action.toggle-overview = [];

      # ── Screenshots (via DMS) ──────────────────────────────────────────────
      "Print".action.spawn      = ["dms" "ipc" "call" "niri" "screenshot"];
      "Ctrl+Print".action.spawn = ["dms" "ipc" "call" "niri" "screenshotScreen"];
      "Alt+Print".action.spawn  = ["dms" "ipc" "call" "niri" "screenshotWindow"];

      # ── Audio (via DMS — shows OSD overlay) ────────────────────────────────
      "XF86AudioRaiseVolume".action.spawn  = ["dms" "ipc" "call" "audio" "increment" "5"];
      "XF86AudioLowerVolume".action.spawn  = ["dms" "ipc" "call" "audio" "decrement" "5"];
      "XF86AudioMute".action.spawn         = ["dms" "ipc" "call" "audio" "mute"];
      "XF86AudioMicMute".action.spawn      = ["dms" "ipc" "call" "audio" "micmute"];

      # ── Brightness (via DMS — shows OSD overlay) ───────────────────────────
      "XF86MonBrightnessUp".action.spawn   = ["dms" "ipc" "call" "brightness" "increment" "10" "backlight:intel_backlight"];
      "XF86MonBrightnessDown".action.spawn = ["dms" "ipc" "call" "brightness" "decrement" "10" "backlight:intel_backlight"];
    };
  };

  # ── DankMaterialShell ──────────────────────────────────────────────────────
  programs.dank-material-shell = {
    enable = true;
    niri = {
      enableKeybinds = false;
      enableSpawn = true;
    };
    enableSystemMonitoring = true;
    enableAudioWavelength = true;
    enableClipboardPaste = true;
    settings = {
      blurredWallpaperLayer = true;
      niriLayoutGapsOverride = 16;
      niriLayoutBorderSize = 0;
      useFahrenheit   = true;
      useAutoLocation = true;
      use24HourClock  = false;
      cursorSettings.niri.hideWhenTyping = true;
      controlCenterShowBatteryIcon = true;
      barConfigs = [
        {
          id            = "default";
          name          = "Main Bar";
          enabled       = true;
          leftWidgets   = [ "launcherButton" "workspaceSwitcher" ];
          centerWidgets = [ "clock" "weather" ];
          rightWidgets  = [ "systemTray" "clipboard" "notificationButton" "controlCenterButton" ];
        }
      ];
    };
    session = {
      wallpaperPath               = "${config.home.homeDirectory}/Pictures/Wallpapers/default.png";
      nightModeEnabled            = true;
      nightModeAutoEnabled        = true;
      nightModeAutoMode           = "location";
      nightModeUseIPLocation      = true;
      nightModeTemperature        = 3400;
      nightModeHighTemperature    = 5000;
      wallpaperCyclingEnabled     = false;
    };
    plugins = {
      dankBatteryAlerts.enable = true;
    };
  };

  # ── Wallpaper ──────────────────────────────────────────────────────────────
  # Reuses the gradient generated by stylix.image (modules/nixos/theming.nix)
  # so SDDM and DMS show the same wallpaper.
  home.file."Pictures/Wallpapers/default.png".source = config.stylix.image;

  # ── Zen Browser ────────────────────────────────────────────────────────────
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
      userChrome = lib.mkAfter ''
        .zen-browser-grain {
          display: none !important;
        }
      '';
      settings = {
        "browser.ai.control.default"            = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText"       = "blocked";
        "browser.ai.control.sidebarChatbot"     = "blocked";
        "browser.ai.control.smartTabGroups"     = "blocked";
        "browser.ai.control.translations"       = "blocked";
        "zen.theme.toolbar-themed"              = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  # ── GTK ────────────────────────────────────────────────────────────────────
  #gtk.gtk4.theme = null;

  # ── Stylix targets ─────────────────────────────────────────────────────────
  stylix.targets.zen-browser.profileNames = [ "03bokykz.Default Profile" ];
  # Prevent Stylix from baking the store wallpaper into DMS's session.json;
  # sets the wallpaper via IPC instead.
  stylix.targets.dank-material-shell.image.enable = false;

  # ── Ghostty ────────────────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
      ];
    };
  };

  # ── Senpai ─────────────────────────────────────────────────────────────────
  programs.senpai = {
    enable = true;
    config = {
      address = "robert-mccoy.com:6697";
      nickname = "dwarfjockey";
      username = "dwarfjockey";
      password-cmd = [ "cat" "/persist/home/robert/.config/senpai/password" ];
      colors = {
        prompt  = "#${colors.base0D}";
        unread  = "#${colors.base0B}";
        status  = "#${colors.base03}";
        nicks   = {
          _params = [ "self" "#${colors.base0D}" ];
        };
      };
    };
  };
}
