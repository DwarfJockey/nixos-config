{ config, lib, pkgs, inputs, ... }:

let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Active (dark) Framework palette — single source for niri's focus-ring colors.
  palette = (import ./framework-palette.nix).dark;

  # Noctalia issue #2687: the community zen-browser template leaves black/grey
  # bars on the window's background edges. Zen sets --zen-main-browser-background
  # on the #zen-browser-background element (out-specificity-ing the template's
  # :root rule) and also reads --zen-main-browser-background-old, which the
  # template never sets. Paint both with --base (defined on `*` by the template,
  # so this stays a static add-on — no Noctalia tokens needed).
  zenBgFixCss = pkgs.writeText "zen-userChrome-bgfix.css" ''
    #zen-browser-background {
      --zen-main-browser-background: var(--base) !important;
      --zen-main-browser-background-old: var(--base) !important;
    }
  '';

  # Inject an @import of the rendered fix into each Zen profile's userChrome.css,
  # mirroring the community template's apply.sh. Idempotent; the unique filename
  # keeps the community sed cleanup (which matches zen-userChrome\.css) off our line.
  zenBgFixApply = pkgs.writeShellScript "zen-bgfix-apply.sh" ''
    set -euo pipefail
    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}"
    css="$cache_dir/noctalia/zen-browser/zen-userChrome-bgfix.css"
    line="@import \"$css\";"
    find "''${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen" \
      -mindepth 2 -maxdepth 2 -type d -name chrome 2>/dev/null |
      while IFS= read -r dir; do
        uc="$dir/userChrome.css"
        touch "$uc"
        if ! grep -Fq "$line" "$uc"; then
          [ -s "$uc" ] && [ -n "$(tail -c1 "$uc")" ] && echo >>"$uc"
          printf '%s\n' "$line" >>"$uc"
        fi
      done
  '';

  # Neovim theming template (input). Noctalia substitutes {{colors.<token>...}}
  # and writes the result to the output_path below; editor.nix loads it via the
  # base16-nvim plugin. Tokens are restricted to those the shipped `helix` builtin
  # template uses, so they are guaranteed to render for the custom palette.
  nvimThemeLua = pkgs.writeText "noctalia.lua" ''
    require('base16-colorscheme').setup({
      base00 = '{{colors.surface.default.hex}}',
      base01 = '{{colors.surface_container.default.hex}}',
      base02 = '{{colors.surface_container_high.default.hex}}',
      base03 = '{{colors.outline.default.hex}}',
      base04 = '{{colors.on_surface_variant.default.hex}}',
      base05 = '{{colors.on_surface.default.hex}}',
      base06 = '{{colors.on_surface.default.hex}}',
      base07 = '{{colors.on_background.default.hex}}',
      base08 = '{{colors.error.default.hex}}',
      base09 = '{{colors.tertiary.default.hex}}',
      base0A = '{{colors.secondary.default.hex}}',
      base0B = '{{colors.primary.default.hex}}',
      base0C = '{{colors.tertiary_container.default.hex}}',
      base0D = '{{colors.primary_container.default.hex}}',
      base0E = '{{colors.secondary_container.default.hex}}',
      base0F = '{{colors.error_container.default.hex}}',
    })

    local hi = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end
    hi('TelescopeNormal',       { fg = '{{colors.on_surface.default.hex}}',         bg = '{{colors.surface.default.hex}}' })
    hi('TelescopeBorder',       { fg = '{{colors.outline.default.hex}}',            bg = '{{colors.surface.default.hex}}' })
    hi('TelescopePromptPrefix', { fg = '{{colors.primary.default.hex}}',            bg = '{{colors.surface.default.hex}}' })
    hi('TelescopePromptTitle',  { fg = '{{colors.surface.default.hex}}',            bg = '{{colors.primary.default.hex}}' })
    hi('TelescopeResultsTitle', { fg = '{{colors.surface.default.hex}}',            bg = '{{colors.tertiary.default.hex}}' })
    hi('TelescopeSelection',    { fg = '{{colors.on_surface.default.hex}}',         bg = '{{colors.surface_container_high.default.hex}}' })
    hi('TelescopeMatching',     { fg = '{{colors.primary.default.hex}}',            bold = true })
  '';

  # Live-reload running nvim instances after the template re-renders. Unlike the
  # upstream community apply.sh, this makes no lazy.nvim assumptions and never
  # touches init.lua (a read-only nix-store symlink under nixvim).
  nvimThemeApply = pkgs.writeShellScript "nvim-theme-apply.sh" ''
    set -euo pipefail
    pkill -SIGUSR1 nvim 2>/dev/null || true
  '';

  baseShadow = {
    enable = true;
    softness = 10;
    spread = 0;
    offset = { x = 0; y = 2; };
    color = "#00000040";
    draw-behind-window = true;
  };

  activeShadow = {
    enable = true;
    softness = 15;
    spread = 1;
    offset = { x = 0; y = 4; };
    color = "#00000050";
    draw-behind-window = true;
  };

  popupShadow = {
    enable = true;
    softness = 20;
    spread = 2;
    offset = { x = 0; y = 6; };
    color = "#00000060";
    draw-behind-window = true;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.twilight
    inputs.noctalia.homeModules.default
  ];

  # ── Niri ───────────────────────────────────────────────────────────────────
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

    layout.border.enable = false;
    # Colors here are fallbacks: the Noctalia "niri" template (rendered to
    # ~/.config/niri/noctalia.kdl and pulled in by the trailing `include` below)
    # overrides focus-ring/border/shadow colors at runtime. enable/width stay.
    layout.focus-ring = {
      enable = true;
      width  = 0.5;
    };
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
      { # Panels / popups (elevation 8)
        matches = [{ namespace = "^noctalia-"; }];
        excludes = [
          { namespace = "^noctalia-bar"; }
          { namespace = "^noctalia-backdrop"; }
          { namespace = "^noctalia-wallpaper"; }
        ];
        shadow = popupShadow;
        geometry-corner-radius = {
          bottom-left = 10.0;
          bottom-right = 10.0;
          top-left = 10.0;
          top-right = 10.0;
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
      # ── Core Noctalia binds ────────────────────────────────────────────────
      "Mod+Space".action.spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
      "Mod+S".action.spawn     = ["noctalia" "msg" "panel-toggle" "control-center"];
      "Mod+Comma".action.spawn = ["noctalia" "msg" "settings-toggle"];

      # ── Session ────────────────────────────────────────────────────────────
      "Mod+Shift+E".action.quit.skip-confirmation = true;
      "Mod+Shift+P".action.power-off-monitors     = [];
      "Super+L".action.spawn = ["noctalia" "msg" "session" "lock"];

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

      # ── Screenshots (niri-native) ──────────────────────────────────────────
      "Print".action.screenshot        = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window   = [];

      # ── Audio (via Noctalia — shows OSD overlay) ───────────────────────────
      "XF86AudioRaiseVolume".action.spawn  = ["noctalia" "msg" "volume-up"];
      "XF86AudioLowerVolume".action.spawn  = ["noctalia" "msg" "volume-down"];
      "XF86AudioMute".action.spawn         = ["noctalia" "msg" "volume-mute"];
      "XF86AudioMicMute".action.spawn      = ["noctalia" "msg" "mic-mute"];

      # ── Brightness (via Noctalia — shows OSD overlay) ──────────────────────
      "XF86MonBrightnessUp".action.spawn   = ["noctalia" "msg" "brightness-up"];
      "XF86MonBrightnessDown".action.spawn = ["noctalia" "msg" "brightness-down"];
    };
  };

  # Append Noctalia's niri theme include to the niri-flake-generated config.kdl.
  # `optional=true` keeps `niri validate` happy at build time (Noctalia writes
  # ~/.config/niri/noctalia.kdl only at runtime). The include is positional-last
  # so the template's colors win; Noctalia's apply.sh sees the line already
  # present and never tries to write to the read-only config.kdl symlink.
  xdg.configFile.niri-config.source = lib.mkForce (
    inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package (
      config.programs.niri.finalConfig + ''

        include optional=true "noctalia.kdl"
      ''
    )
  );

  # ── Noctalia shell ───────────────────────────────────────────────────────
  programs.noctalia = {
    enable = true;
    package = noctaliaPkg;
    customPalettes.Framework = import ./framework-palette.nix;
    settings = {
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Framework";
        # App theming: render Noctalia's palette into GTK/Qt/Ghostty configs,
        # plus the community Zen Browser template (its apply.sh injects @imports
        # into the Zen profile's chrome CSS).
        templates = {
          enable_builtin_templates   = true;
          builtin_ids                = [ "gtk3" "gtk4" "qt" "ghostty" "niri" ];
          enable_community_templates = true;
          community_ids              = [ "zen-browser" ];
          # Issue #2687 fix — add-on user template (see zenBgFix* in the let block).
          user.zen_browser_bgfix = {
            input_path  = "${zenBgFixCss}";
            output_path = "$XDG_CACHE_HOME/noctalia/zen-browser/zen-userChrome-bgfix.css";
            post_hook   = "bash '${zenBgFixApply}'";
          };
          # Neovim base16 colorscheme (see nvimTheme* in the let block; loaded by
          # editor.nix via base16-nvim).
          user.neovim = {
            input_path  = "${nvimThemeLua}";
            output_path = "$XDG_CACHE_HOME/noctalia/nvim/noctalia.lua";
            post_hook   = "bash '${nvimThemeApply}'";
          };
        };
      };

      # Static wallpaper, vendored in the repo so it survives the ephemeral root
      # (the GUI/runtime wallpaper state in ~/.local/state/noctalia is not
      # persisted). Noctalia reads [wallpaper.default].path from config.toml.
      wallpaper = {
        default.path = "${./wallpapers/framework-pro-7.png}";
        automation.enabled = false;
      };

      bar.main = {
        position = "top";
        enabled  = true;
        start  = [ "launcher" "workspaces" ];
        center = [ "notifications" "clock" "weather" ];
        end    = [ "tray" "clipboard" "network" "bluetooth" "volume" "battery" ];
        # Flat bar restyle
        capsule         = true;
        capsule_opacity = 0.0;
        capsule_border  = "secondary";
        capsule_radius  = 0;
        color           = "secondary";
        thickness       = 36;
        padding         = 4;
        widget_spacing  = 4;
        radius          = 0;
        shadow          = false;
        margin_ends     = 0;
        margin_edge     = 0;
      };

      shell = {
        font_family = "Adwaita Sans";
        settings_show_advanced = true;
        app_icon_colorize = true;
        panel = {
          session_placement = "centered";
          transparency_mode = "solid";
          control_center_placement = "floating";
          open_near_click_control_center = true;
          shadow = false;
        };
        shadow.alpha = 0.0;
      };

      control_center.sidebar_section = "none";

      # Lock the session as soon as Noctalia is up, so the autologin boots
      # straight to the lock screen. Fires once per Noctalia start (per session).
      hooks.started = "noctalia msg session lock";

      location.auto_locate  = true;
      nightlight.enabled    = true;
      notification.position = "top_center";
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
      # userChrome.css is intentionally NOT managed here: the Noctalia
      # zen-browser community template's apply.sh owns it at runtime (injects
      # @import lines). Managing it via HM would make apply.sh clobber the
      # store symlink and break the next rebuild.
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

  # ── Cursor / icons / GTK / Qt ──────────────────────────────────────────────
  # Base dark theme + assets. Noctalia's templates overlay accent colors on top
  # (gtk-3.0/4.0 noctalia.css, qt5ct/qt6ct color files).
  home.pointerCursor = {
    package = pkgs.phinger-cursors;
    name    = "phinger-cursors-dark";
    size    = 24;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    theme     = { package = pkgs.adw-gtk3; name = "adw-gtk3-dark"; };
    iconTheme = { package = pkgs.papirus-icon-theme; name = "Papirus-Dark"; };
    font      = { name = "Adwaita Sans"; size = 11; };
    # Don't let HM manage gtk-4.0/gtk.css — the Noctalia gtk4 template's apply.sh
    # owns it (injects @import noctalia.css). HM managing it collides at
    # activation. GTK4/libadwaita colors come from the imported noctalia.css.
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # ── Ghostty ────────────────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      # Colors come from the Noctalia "ghostty" template (writes ~/.config/ghostty/themes/noctalia).
      theme = "noctalia";
      font-family = "FiraCode Nerd Font";
      font-size = 11;
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
    };
  };
}
