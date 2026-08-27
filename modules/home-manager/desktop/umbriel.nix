{
  config,
  lib,
  inputs,
  vars,
  ...
}:

let
  # Bridge Stylix -> Umbriel manually. Umbriel has no Stylix target (niri got one
  # from niri-flake), so every colour it draws is mapped here. Slot choices follow
  # Noctalia's own assets/templates/umbriel/umbriel.toml. The window borders no longer
  # reproduce what stylix.targets.niri set (active base0D / inactive base03): they are
  # composites now, see [appearance] below.
  c = config.lib.stylix.colors.withHashtag;
  inherit (import ../../colors.nix { inherit lib; }) withAlpha over;

  # Mod+N switches to workspace N; Mod+Ctrl+N moves the window there. Generated over 1..9.
  workspaceBinds = lib.listToAttrs (
    lib.concatMap (n: [
      {
        name = "Mod+${toString n}";
        value = "workspace-switch:${toString n}";
      }
      {
        name = "Mod+Ctrl+${toString n}";
        value = "window-move-to-workspace:${toString n}";
      }
    ]) (lib.range 1 9)
  );
in
{
  imports = [ inputs.umbriel.homeModules.default ];

  # Session autostart for apps that live in the system tray. These can't be
  # general.autostart entries: Electron asks the bus once, at tray-creation time,
  # whether org.kde.StatusNotifierWatcher has an owner, and if it doesn't it never
  # creates the icon — there is no XEmbed fallback on Wayland and no retry. Noctalia
  # hosts that watcher and only claims the name a few seconds in, well after Umbriel
  # has spawned everything, so both apps came up permanently invisible: running,
  # hidden by --silent/--start-minimized, with no tray icon to restore them from.
  # noctalia.service is Type = dbus on that name, so After= here is a real guarantee
  # that the watcher exists. Kept soft (no Requires): if Noctalia dies the apps should
  # still start, just without a tray. No Restart: quitting one deliberately shouldn't
  # respawn it, matching the old autostart behaviour.
  #
  # graphical-session.target must be in After= too, even though WantedBy already binds
  # these to it. A target implicitly gains After= on everything that Wants= it, so
  # WantedBy alone gives `target After= app`; with `app After= noctalia After= target`
  # that closes a cycle, and systemd breaks it by silently deleting the app's start job
  # (dead unit, no tray, nothing logged but one "Found ordering cycle" line). Declaring
  # the ordering explicitly cancels the implicit edge — which is exactly why
  # noctalia.service, which has always listed the target in After=, never hit this.
  systemd.user.services =
    let
      trayApp = description: exec: {
        Unit = {
          Description = description;
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "noctalia.service"
          ];
        };
        Service.ExecStart = exec;
        Install.WantedBy = [ "graphical-session.target" ];
      };
    in
    lib.optionalAttrs vars.apps.onePassword {
      # System path, not pkgs._1password-gui: programs._1password-gui (modules/nixos/apps.nix)
      # owns setuid wrappers tied to that exact package, and a second HM closure could drift.
      "1password" = trayApp "1Password" "/run/current-system/sw/bin/1password --silent";
    }
    // lib.optionalAttrs vars.apps.discord {
      # finalPackage is nixcord's Vencord-patched build; vesktop.package is the plain input.
      vesktop = trayApp "Vesktop (Discord)" "${config.programs.nixcord.finalPackage.vesktop}/bin/vesktop --start-minimized";
    };

  # Umbriel. `settings` is a free-form attrset serialised to
  # ~/.config/umbriel/config.toml by pkgs.formats.toml, then checked at build time
  # with `umbriel validate -c` (programs.umbriel.validateConfig, on by default) —
  # so a bad key fails the rebuild rather than the login. Umbriel also live-reloads
  # the file on save, but the file is a store symlink here, so a rebuild is what
  # applies changes.
  programs.umbriel = {
    enable = true;

    settings = {
      general = {
        # Umbriel's keybind cheatsheet overlay, shown on every startup by default.
        show_cheatsheet = false;
        # Spawns xwayland-satellite, which the package wrapper puts on umbriel's PATH.
        xwayland = true;

        # Only apps that need nothing from graphical-session.target belong here:
        # Umbriel raises umbriel-session.target (-> graphical-session.target) and
        # then immediately spawns these, so an autostart can never be ordered after
        # a session service. Apps that need the tray are user units instead
        # (systemd.user.services, above). Noctalia is one of those units too.
        #
        # Steam is fine here: libayatana-appindicator watches NameOwnerChanged and
        # re-registers its tray icon whenever the watcher shows up.
        autostart = [ "zen-twilight" ] ++ lib.optional vars.apps.steam "steam -silent";
      };

      # 2x scale on the Framework 13's 2256x1504 panel.
      output."eDP-1".scale = 2.0;

      # Umbriel-drawn surfaces: the cheatsheet overlay and the config-error banner.
      colors = {
        background = withAlpha c.base00 "F0";
        text_primary = c.base05;
        text_muted = c.base04;
        accent_primary = c.base09;
        accent_secondary = c.base0E;
        warning = c.base0A;
        error = c.base08;
      };

      appearance = {
        # Umbriel defaults this to true, which asks clients to drop their own
        # decorations via xdg-decoration. Umbriel then draws only the border — it
        # has no server-side titlebars — so Ghostty (window-decoration = auto,
        # which honours the negotiation) lost its GTK headerbar, and with it its
        # tab bar. niri defaulted to false and never set it, so `false` here is
        # what keeps decoration behaviour identical across the swap. Clients must
        # be restarted to pick a change up.
        prefer_no_csd = false;
        # 1 logical px reads as a crisp thin accent on this 2x display (Umbriel's
        # default is 2, niri's was 4).
        border_width = 1;
        corner_radius = 15;
        animation_ms = 250;
        # Composites, not raw slots. Focused is the Framework orange pulled 15% toward
        # the background so it reads as an accent beside the shell's own rather than
        # louder than it. Unfocused is the identical value mOutline computes and GTK's
        # @borders resolves to (#363432), so every hairline on screen — window edges,
        # bar edges, panel edges, GTK window borders — is one colour. That is far
        # dimmer than the old base03; the drop shadow below is what actually separates
        # an unfocused window from the wallpaper, which is how adw-gtk3 does it too.
        # Precomputed rather than #RRGGBBAA (which Umbriel would accept) so the borders
        # stay put instead of tinting with whatever wallpaper sits behind the window.
        border_focused = over c.base0E c.base00 0.85; # #a592d0
        border_unfocused = over c.base05 c.base00 0.15; # #363432
        scratchpad_border_focused = c.base0C;
        scratchpad_border_unfocused = c.base02;
        outer_border_color = c.base00;
        insert_hint_color = withAlpha c.base0C "80";
        backdrop_color = c.base00;

        # Native background blur, replacing the raw-KDL `background-effect` block
        # that niri-flake's typed settings couldn't express. Master switch only —
        # surfaces opt in through the layer_rule below.
        blur.enabled = true;

        # Single global drop shadow. niri had three (Material-3 elevation L1/L3/L5
        # for tiled/active/floating); Umbriel draws one for every window, so this is
        # the middle preset — MD3 key-shadow alpha 0.30 with the L3 geometry.
        shadow = {
          enabled = true;
          softness = 8;
          offset_x = 0;
          offset_y = 3;
          color = "#00000059";
        };
      };

      overview = {
        background_tint = withAlpha c.base00 "30";
        workspace_background = withAlpha c.base00 "44";
      };

      layout.gap = 8;

      input = {
        keyboard.layout = vars.keyboardLayout;
        # Umbriel exposes only tap and natural_scroll for touchpads; dwt and
        # two-finger scrolling are libinput defaults anyway. click-method still has no
        # Umbriel key, so the clickpad takes libinput's *default* method — which
        # modules/nixos/desktop.nix flips from buttonareas to clickfinger with a
        # libinput quirk. So: two-finger *press* = right click, while tap stays off.
        touchpad = {
          tap = false;
          natural_scroll = true;
        };
        cursor = {
          theme = config.stylix.cursor.name;
          size = config.stylix.cursor.size;
        };
      };

      window_rule = [
        {
          match.app_id = "^com\\.mitchellh\\.ghostty$";
          default_width = 2.0 / 3.0;
        }
        {
          match.app_id = "^zen-twilight$";
          default_workspace = 1;
          default_width = 1.0;
        }
        {
          match.app_id = "^zen-twilight$";
          match.title = "^Picture-in-Picture$";
          default_floating = true;
          default_size = [
            480
            270
          ];
          default_position = {
            x = 32;
            y = 32;
            anchor = "bottom_right";
          };
        }
        {
          match.app_id = "^steam$";
          match.title = "^notificationtoasts_[0-9]+_desktop$";
          default_position = {
            x = 10;
            y = 10;
            anchor = "bottom_right";
          };
          default_focused = false;
          default_pinned = true;
        }
        {
          match.app_id = "^org\\.gnome\\.TextEditor$";
          default_width = 2.0 / 3.0;
        }
        {
          # app_id is `dev.noctalia.Noctalia`, not `.Settings` — that was the pre-5.0
          # name carried over from niri.nix, so this rule silently never matched and
          # the settings window tiled. Size follows upstream's packaged example, which
          # is what the current window actually asks for.
          match.app_id = "^dev\\.noctalia\\.Noctalia$";
          default_floating = true;
          default_width = 2.0 / 3.0;
        }
        {
          # The portal's screen-share picker (xdg-desktop-portal-umbriel).
          match.app_id = "^dev\\.noctalia\\.UmbrielSharePicker$";
          default_floating = true;
          default_size = [
            800
            600
          ];
        }
      ];

      # Layer-shell blur is off by default; Noctalia's bars/panels/OSD opt in here.
      # Regex, blur_ignore_alpha, and blur_optimized all follow upstream's packaged
      # example. blur_optimized = false is load-bearing: it is this config's
      # equivalent of niri's `background-effect { xray false }`. The global
      # appearance.blur.optimized defaults to true, which caches one background blur
      # per output, and that cache holds the wallpaper layer and nothing above it —
      # so the bars and panels blurred the wallpaper and never the windows actually
      # behind them. false recomputes per surface, which is what samples the windows.
      layer_rule = [
        {
          match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
          blur = true;
          blur_ignore_alpha = 0.5;
          blur_optimized = false;
        }
      ];

      # Umbriel loads its built-in defaults only when no config file exists — with
      # this table present, it is the complete set of binds.
      keybinds = {
        # Core Noctalia binds
        "Mod+Space" = "spawn:noctalia msg panel-toggle launcher";
        "Mod+S" = "spawn:noctalia msg panel-toggle control-center";
        "Mod+Comma" = "spawn:noctalia msg settings-toggle";

        # Session
        "Mod+Shift+E" = "session-quit:skip-confirmation";
        "Mod+Shift+P" = "spawn:noctalia msg dpms-off";
        "Mod+L" = "spawn:noctalia msg session lock";

        # Apps
        "Mod+T" = "spawn:ghostty";
        "Mod+B" = "spawn:zen-twilight";
        "Mod+E" = "spawn:nautilus";

        # Windows
        "Mod+Q" = "window-close";
        "Mod+F" = "window-toggle-maximize";
        "Mod+Shift+F" = "window-toggle-fullscreen";
        "Mod+C" = "window-center";
        "Mod+V" = "window-toggle-floating";
        # No Umbriel equivalent for niri's switch-focus-between-floating-and-tiling;
        # pinned is the other floating-adjacent toggle it has.
        "Mod+Shift+V" = "window-toggle-pinned";
        # Was reset-window-height, which Umbriel has no analogue for. Umbriel
        # live-reloads on save anyway; this is the manual nudge.
        "Mod+R" = "config-reload";
        # Was expand-column-to-available-width.
        "Mod+Ctrl+F" = "window-toggle-maximize-to-edges";
        # Was focus-column-first / focus-column-last.
        "Mod+Home" = "layout-scroll-left";
        "Mod+End" = "layout-scroll-right";
        # Was focus-workspace-previous.
        "Mod+Tab" = "window-focus-next";

        # Focus window
        "Mod+Left" = "window-focus-left";
        "Mod+Right" = "window-focus-right";
        "Mod+Down" = "window-focus-down";
        "Mod+Up" = "window-focus-up";

        # Focus monitor
        "Mod+Shift+Left" = "output-focus-left";
        "Mod+Shift+Right" = "output-focus-right";
        "Mod+Shift+Up" = "output-focus-up";
        "Mod+Shift+Down" = "output-focus-down";

        # Move column/window
        "Mod+Ctrl+Left" = "column-move-left";
        "Mod+Ctrl+Right" = "column-move-right";
        "Mod+Ctrl+Down" = "window-move-down";
        "Mod+Ctrl+Up" = "window-move-up";

        # Move column to monitor
        "Mod+Ctrl+Shift+Left" = "column-move-to-output-left";
        "Mod+Ctrl+Shift+Right" = "column-move-to-output-right";
        "Mod+Ctrl+Shift+Up" = "column-move-to-output-up";
        "Mod+Ctrl+Shift+Down" = "column-move-to-output-down";

        # Column sizing. Umbriel has no window-height actions, so the Shift pair
        # (was set-window-height +-10%) reuses the width presets instead.
        "Mod+Minus" = "window-modify-width:-0.1";
        "Mod+Equal" = "window-modify-width:0.1";
        "Mod+Shift+Minus" = "window-set-width:0.5";
        "Mod+Shift+Equal" = "window-cycle-width";

        # Workspaces
        "Mod+U" = "workspace-next";
        "Mod+I" = "workspace-previous";
        # Was move-column-to-workspace-down/up, which Umbriel has no relative form
        # of; these restructure the column instead.
        "Mod+Shift+U" = "window-consume-left";
        "Mod+Shift+I" = "window-expel-right";

        # Overview
        "Mod+Grave" = "overview-toggle";

        # Screenshots (Umbriel has no native screenshot action; Noctalia's IPC
        # drives xdg-desktop-portal-umbriel).
        "Print" = "spawn:noctalia msg screenshot-region";
        "Ctrl+Print" = "spawn:noctalia msg screenshot-fullscreen";
        "Alt+Print" = "spawn:noctalia msg screenshot-fullscreen pick";

        # Audio (via Noctalia — shows OSD overlay)
        "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
        "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
        "XF86AudioMute" = "spawn:noctalia msg volume-mute";
        "XF86AudioMicMute" = "spawn:noctalia msg mic-mute";

        # Brightness (via Noctalia — shows OSD overlay)
        "XF86MonBrightnessUp" = "spawn:noctalia msg brightness-up";
        "XF86MonBrightnessDown" = "spawn:noctalia msg brightness-down";
        # Mod+1..9 workspace-switch / Mod+Ctrl+1..9 window-move-to-workspace (generated).
      }
      // workspaceBinds;
    };
  };
}
