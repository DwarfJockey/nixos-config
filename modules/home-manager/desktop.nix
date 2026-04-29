{ config, lib, pkgs, inputs, ... }:

let
  colors = config.lib.stylix.colors;

  recoloredWallpapers = pkgs.runCommand "recolored-wallpapers" {
    nativeBuildInputs = [ pkgs.lutgen pkgs.imagemagick ];
  } ''
    mkdir -p $out
    for img in ${../../home/wallpapers}/*; do
      [ -f "$img" ] || continue
      basename="$(basename "$img")"
      lutgen apply -o "$out/$basename" "$img" -- \
        "#${colors.base00}" "#${colors.base01}" "#${colors.base02}" "#${colors.base03}" \
        "#${colors.base04}" "#${colors.base05}" "#${colors.base06}" "#${colors.base07}" \
        "#${colors.base08}" "#${colors.base09}" "#${colors.base0A}" "#${colors.base0B}" \
        "#${colors.base0C}" "#${colors.base0D}" "#${colors.base0E}" "#${colors.base0F}"
      # Darken slightly for contrast with windows
      magick "$out/$basename" -modulate 85,100,100 "$out/$basename"
    done

    # Create default.png from the first image for DMS wallpaperPath
    first="$(find $out -maxdepth 1 -type f | sort | head -n1)"
    if [ -n "$first" ]; then
      cp "$first" "$out/default.png"
    fi
  '';

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
    inputs.nix-monitor.homeManagerModules.default
  ];

  # ── Niri ───────────────────────────────────────────────────────────────────
  programs.niri.settings = {
    outputs."eDP-1".scale = 2.0;

    hotkey-overlay.skip-at-startup = true;

    spawn-at-startup = [
      { command = ["sh" "-c" "for i in $(seq 1 30); do dms ipc call lock lock && exit 0; sleep 1; done"]; }
    ];

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
      "Mod+Return".action.spawn = "ghostty";
      "Mod+B".action.spawn      = "zen-twilight";
      "Mod+E".action.spawn      = "nautilus";

      # ── Windows ────────────────────────────────────────────────────────────
      "Mod+Q".action.close-window                                   = [];
      "Mod+F".action.maximize-column                                = [];
      "Mod+Shift+F".action.fullscreen-window                        = [];
      "Mod+C".action.center-column                                  = [];
      "Mod+V".action.toggle-window-floating                         = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      # ── Focus ──────────────────────────────────────────────────────────────
      "Mod+Left".action.focus-column-left   = [];
      "Mod+Right".action.focus-column-right = [];
      "Mod+Down".action.focus-window-down   = [];
      "Mod+Up".action.focus-window-up       = [];
      "Mod+Home".action.focus-column-first  = [];
      "Mod+End".action.focus-column-last    = [];

      # ── Move windows ───────────────────────────────────────────────────────
      "Mod+Shift+Left".action.move-column-left     = [];
      "Mod+Shift+Right".action.move-column-right   = [];
      "Mod+Shift+Down".action.move-window-down     = [];
      "Mod+Shift+Up".action.move-window-up         = [];
      "Mod+Shift+Home".action.move-column-to-first = [];
      "Mod+Shift+End".action.move-column-to-last   = [];

      # ── Column/window sizing ───────────────────────────────────────────────
      "Mod+Minus".action.set-column-width        = "-10%";
      "Mod+Equal".action.set-column-width        = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      "Mod+R".action.reset-window-height         = [];

      # ── Workspaces ─────────────────────────────────────────────────────────
      "Mod+U".action.focus-workspace-down               = [];
      "Mod+I".action.focus-workspace-up                 = [];
      "Mod+Ctrl+Down".action.focus-workspace-down       = [];
      "Mod+Ctrl+Up".action.focus-workspace-up           = [];
      "Mod+Shift+U".action.move-column-to-workspace-down         = [];
      "Mod+Shift+I".action.move-column-to-workspace-up           = [];
      "Mod+Ctrl+Shift+Down".action.move-column-to-workspace-down = [];
      "Mod+Ctrl+Shift+Up".action.move-column-to-workspace-up     = [];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      # ── Overview ───────────────────────────────────────────────────────────
      "Mod+Tab".action.toggle-overview = [];

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
      barConfigs = [
        {
          id            = "default";
          name          = "Main Bar";
          enabled       = true;
          leftWidgets   = [ "launcherButton" "workspaceSwitcher" ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets  = [ "systemTray" "clipboard" "notificationButton" "nixMonitor" "battery" "controlCenterButton" ];
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
      wallpaperCyclingEnabled     = true;
      wallpaperCyclingMode        = "interval";
      wallpaperCyclingInterval    = 60;
      wallpaperTransition         = "fade";
    };
    plugins = {
      dankBatteryAlerts.enable = true;
      nixMonitor.settings = {
        showGenerations = false;
        showStoreSize = false;
      };
    };
  };

  # ── Wallpaper recoloring ───────────────────────────────────────────────────
  home.file."Pictures/Wallpapers".source = recoloredWallpapers;

  # ── nix-monitor ────────────────────────────────────────────────────────────
  programs.nix-monitor = {
    enable = true;
    generationsCommand = [
      "sh" "-c"
      "ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l"
    ];
    rebuildCommand = [
      "bash" "-c"
      "sudo -S nixos-rebuild switch --flake ${config.home.homeDirectory}/Documents/nixos#framework-13 2>&1"
    ];
  };

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
  gtk.gtk4.theme = null;

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
