{ config, lib, pkgs, inputs, ... }:

let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaBin = "${noctaliaPkg}/bin/noctalia";

  # Bridge Stylix -> Noctalia manually. Stylix now ships a `noctalia` target
  # (stylix.targets.noctalia) that writes programs.noctalia too, but it uses the
  # raw stylix.image for the wallpaper (this repo wants the recolored+dimmed
  # themedWallpaper below) and doesn't bridge the bar opacity — so it's disabled
  # (see stylix.targets.noctalia.enable below) in favour of this tuned bridge.
  # Build a Noctalia custom palette from Stylix's base16 colors; the m* mapping
  # matches Stylix's target, and the terminal block follows base16 slot order
  # (Stylix themes real terminals directly — this is just for Noctalia's internal
  # palette completeness).
  stylixColors = config.lib.stylix.colors.withHashtag;
  # Window opacity owned by Stylix (set in theming.nix, propagated to HM via
  # followSystem). Bridged manually here: Stylix's noctalia target is disabled
  # (below) and only bridges dock/notification/osd opacity anyway, not the bar.
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

  # App icons for the bar launcher buttons, taken from the icon theme Stylix already
  # sets system-wide (theming.nix) rather than from each app's own package, so they
  # restyle together with the rest of the desktop. Both the package and the theme
  # directory name come from the Stylix options, so changing the theme moves these
  # with it. 128x128 is the largest Papirus ships; Noctalia renders at
  # round(48 * contentScale), and these are SVGs anyway.
  papirusApps = "${config.stylix.icons.package}/share/icons/${config.stylix.icons.dark}/128x128/apps";

  # Themed wallpaper. Lives in modules/wallpaper.nix because the Noctalia greeter
  # (modules/nixos/greeter.nix) shows the same image and can't reach into
  # home-manager scope for it. Same args => same store path, so sharing it is free.
  themedWallpaper = import ../../wallpaper.nix {
    inherit pkgs lib;
    colors = config.lib.stylix.colors;
  };

  # This repo's checkout, for the nix-monitor plugin's Update button.
  configDir = "${config.home.homeDirectory}/Projects/nixos-config";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Stylix now ships a `noctalia` target; disable it so the manual bridge above
  # (themed wallpaper + bar opacity, which the target doesn't cover) owns the
  # Noctalia theming instead of conflicting with it.
  stylix.targets.noctalia.enable = false;

  # Re-assert the themed wallpaper into the running Noctalia after a switch.
  # config.toml (persisted) always points here, but Noctalia's live source of
  # truth is its non-persisted runtime state; when a rebuild changes the
  # themedWallpaper store hash, the running shell still holds the stale path and
  # falls back to its bundled default until the next reboot re-seeds from
  # config.toml. This closes that switch-without-reboot gap. No-op (guarded) when
  # Noctalia isn't running yet, e.g. during early boot activation.
  home.activation.noctaliaWallpaper =
    inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ${noctaliaBin} msg wallpaper-get > /dev/null 2>&1; then
        ${noctaliaBin} msg wallpaper-set "${themedWallpaper}" || true
      fi
    '';

  # Noctalia runs as a user service (not niri spawn-at-startup) so teardown is
  # bounded: the Quickshell binary ignores SIGTERM, so as a niri-spawned transient
  # scope it stalled shutdown for the full 90s DefaultTimeoutStopSec. TimeoutStopSec
  # here gives it a 3s grace period, then SIGKILL (harmless — its runtime state is
  # non-persisted). Bound to graphical-session.target: niri --session imports the
  # Wayland env into the user manager, so the socket is reachable.
  #
  # Type = dbus makes the unit reach "active" only once Noctalia owns
  # org.kde.StatusNotifierWatcher — it hosts the system tray, and it connects to the
  # bus seconds before QML instantiates that service. Without this, After= on this
  # unit would only mean "the process was exec'd", which is useless to tray clients:
  # Electron checks NameHasOwner() once at tray-creation and never retries, so
  # 1password/vesktop silently came up with no tray icon (see niri.nix).
  # ponytail: couples the shell's readiness to that one bus name — if a future
  # Noctalia stops claiming it, the unit stalls in `activating` for TimeoutStartSec
  # (90s) then fails into the Restart loop, taking the bar with it. Then: back to
  # Type = simple, and move the wait into the tray apps' ExecStartPre.
  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia shell (bar / dock / control-center / lock)";
      PartOf    = [ "graphical-session.target" ];
      After     = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart      = noctaliaBin;
      Type           = "dbus";
      BusName        = "org.kde.StatusNotifierWatcher";
      Restart        = "on-failure";
      TimeoutStopSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Noctalia scans $XDG_DATA_HOME/noctalia/plugins as its last (highest-precedence)
  # plugin root with no config needed, so a single symlink is the whole install —
  # each subdirectory holding a plugin.toml is one plugin, and the scan follows
  # symlinks. ~/.local/share is not persisted, but home-manager-robert.service runs
  # at boot and re-creates this, same as every other HM dotfile on the ephemeral root.
  xdg.dataFile."noctalia/plugins/nix-monitor".source =
    "${inputs.noctalia-plugins}/nix-monitor";

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
        # Stylix owns every themed target in this repo; Noctalia's own template
        # engine would fight it.
        templates = {
          enable_builtin_templates   = false;
          enable_community_templates = false;
        };
      };

      # base16-recolored, dimmed wallpaper generated in the Nix store; see
      # themedWallpaper in the let block. Noctalia reads [wallpaper.default].path
      # from config.toml (a declarative, persisted setting).
      wallpaper = {
        default.path = "${themedWallpaper}";
        automation.enabled = false;
        transition = [ "fade" ];
      };

      bar = {
        order = [ "main" "bottom" ];

        main = {
          position = "top";
          enabled  = true;
          start  = [ "workspaces" ];
          center = [ "clock" "notifications" ];
          end    = [ "network" "volume" "battery" ];
          # Flat bar restyle. Neutral on_surface/outline roles (blue mPrimary only
          # on active states) so the bar reads like a libadwaita panel rather than
          # a purple-tinted (secondary) one.
          capsule            = false;
          capsule_opacity    = 0.0;
          capsule_border     = "outline";
          # capsule_radius omitted = automatic pill radius (Noctalia only reads a
          # number here; the GUI's "auto" is the absent key).
          color              = "on_surface";
          font_weight        = 400;
          thickness          = 32;
          background_opacity = stylixOpacity.desktop;
          padding            = 12;
          widget_spacing     = 12;
          radius             = 15;
          border_width       = 1.0;
          # Bar shadow is Noctalia-drawn now; the matching niri layer-rule for
          # ^noctalia-bar is gone from niri.nix.
          shadow             = true;
          contact_shadow     = false;
          margin_ends        = 0;
          margin_edge        = 0;
        };

        # Second bar along the bottom edge. Everything not listed here stays at
        # Noctalia's bar defaults (margins, capsule, colors, shadow).
        bottom = {
          position = "bottom";
          enabled  = true;
          # term/browser/files are custom_button instances and spacer_2 is a spacer
          # instance; both are defined under `widget` below. spacer_2 is deliberately
          # reused in all three zones — one instance, one set of settings.
          start  = [ "launcher" "spacer_2" "term" "browser" "files" "tray" ];
          center = [ "media" "spacer_2" "weather" ];
          end    = [ "cpu" "ram" "spacer_2" "clipboard" "caffeine" "nightlight" "bluetooth"
                     "avivbintangaringga/nix-monitor:nix-monitor" "session" ];
          thickness          = 32;
          background_opacity = stylixOpacity.desktop;
          padding            = 12;
          widget_spacing     = 12;
          radius             = 15;
          # Square off the two corners that sit on the screen edge.
          radius_bottom_left  = 0;
          radius_bottom_right = 0;
          border_width       = 1.0;
          reserve_space      = false;
          # Plain auto-hide: reveal on pointer approach only. smart_auto_hide (hide
          # only when a window would overlap) is explicitly off, and the bar no longer
          # peeks on workspace switch.
          auto_hide                = true;
          smart_auto_hide          = false;
          show_on_workspace_switch = false;
        };
      };

      shell = {
        # Suppress the first-run "Welcome to Noctalia" setup wizard. Noctalia
        # otherwise shows it until a marker file exists in its state dir
        # (~/.local/state/noctalia/.setup-complete), which impermanence wipes
        # every reboot — so the wizard would return on every login. This
        # persisted config.toml key short-circuits that check.
        setup_wizard_enabled = false;
        font_family = "Adwaita Sans";
        settings_show_advanced = true;
        app_icon_colorize = false;
        # panel_anchor_bar deliberately unset: when set it *overrides* the bar a
        # panel was opened from, so top-bar widgets would drop their panels at the
        # bottom. Unset, each panel attaches to its own bar; panels with no source
        # bar (the Mod+Space / Mod+S keybinds) fall back to the first enabled bar
        # in `bar.order`, i.e. main.
        panel = {
          transparency_mode = "glass";
          # placement: attached | floating (the only two values Noctalia accepts).
          control_center_placement = "floating";
          session_placement        = "floating";
          wallpaper_placement      = "floating";
          # "auto" = position the floating panel from the bar click, not screen centre.
          launcher_position  = "auto";
          clipboard_position = "auto";
          polkit_position    = "auto";
          open_near_click_control_center = true;
          open_near_click_launcher       = true;
          open_near_click_clipboard      = true;
          open_near_click_session        = true;
          open_near_click_wallpaper      = true;
          # Noctalia draws popup/panel shadows (content-aware) since niri can't
          # place a layer-surface shadow on a floating popup card. Color = the
          # palette's mShadow (base00).
          shadow = true;
        };
        shadow.alpha = 0.55;
      };

      dock.shadow = true;

      control_center = {
        sidebar         = "none";
        sidebar_section = "none";
      };

      audio.enable_sounds = true;
      backdrop.enabled    = true;
      battery.warning_threshold = 20;
      calendar.enabled    = true;

      # Runs once per Noctalia start (per session), when its IPC is ready:
      # re-assert the themed wallpaper. On a fresh boot Noctalia regenerates its
      # non-persisted runtime state from its OWN bundled default and ignores
      # config.toml's wallpaper path, so wallpaper-set is the only lever that
      # applies it. (The home.activation hook above covers the
      # switch-without-reboot case, where Noctalia keeps running and this hook
      # doesn't re-fire.)
      #
      # This used to also `msg session lock`, so passwordless autologin landed on
      # the lock screen. Noctalia Greeter (modules/nixos/greeter.nix) is the login
      # step now, so locking a session the user just authenticated into would be
      # pure friction. Super+L (niri.nix) and idle lock are unaffected.
      hooks.started = "${pkgs.writeShellScript "noctalia-started" ''
        ${noctaliaBin} msg wallpaper-set "${themedWallpaper}"
      ''}";

      location.auto_locate  = true;
      nightlight            = { enabled = true; temperature_day = 5000; };
      notification.position = "top_center";
      osd.position          = "bottom_center";
      weather.unit          = "imperial";

      # Discovery alone doesn't load a plugin — the id has to be listed in `enabled`
      # too. `source = []` is load-bearing: with the key absent Noctalia seeds its two
      # built-in git sources (official + community) and re-clones both (~16MB) into
      # ~/.local/state/noctalia, which impermanence wipes — so that ran on every boot.
      # An explicit empty array suppresses it (Noctalia probes the raw table for the
      # array, so [] counts as configured while a missing key does not). Cost: the
      # in-shell plugin store browser is empty; plugins get added here instead, which
      # is the only way they'd survive a reboot anyway.
      plugins = {
        source      = [ ];
        enabled     = [ "avivbintangaringga/nix-monitor" ];
        auto_update = false;
      };

      # Plugin-level settings (the manifest's root [[setting]] block), as opposed to
      # the per-widget-instance ones under `widget` below.
      plugin_settings."avivbintangaringga/nix-monitor" = {
        # The branch the local nixpkgs rev is compared against; matches the nixpkgs
        # input in flake.nix.
        branch = "nixos-unstable";
        # The panel's Update button. Run through `sh -lc` in a terminal, so `cd` and
        # `&&` are fine. Only the nixpkgs input is bumped — `niri` is deliberately
        # un-followed (flake.nix) and must stay pinned. Writes flake.lock; review and
        # commit that as usual. optimize_command/clean_command keep their defaults
        # (nix-store --optimise -vv / nix-collect-garbage -d).
        update_command = "cd ${configDir} && nix flake update nixpkgs && sudo nixos-rebuild switch --flake .#framework-13";
        panel_card_color   = "surface_variant";
        panel_card_opacity = 70;
      };

      widget = {
        battery       = { hide_when_full = true; show_label = false; };
        brightness.show_label = false;
        clock         = { anchor = true; format = "{:%l:%M %P}"; tooltip_format = "%A %B %e"; };
        media         = { anchor = false; hide_when_no_media = true; title_scroll = "always"; };
        network.show_label = false;
        notifications.hide_when_no_unread = true;
        # Tray moved to the bottom bar's start zone; items sit inline, not behind a
        # drawer button.
        tray.drawer   = false;
        volume.show_label = false;
        # Bare separator instance. Like the custom_button entries below, the name is
        # arbitrary, so it needs an explicit type.
        spacer_2      = { type = "spacer"; };
        # `display`/`minimal` are pre-v5 names Noctalia no longer reads.
        workspaces    = { style = "minimal"; };

        # nix-monitor plugin widget (installed via xdg.dataFile above). The instance
        # name is the full plugin entry id, which is also what goes in the bar zone —
        # Noctalia resolves an unknown widget type through the plugin registry, so no
        # `type` key here. Glyph-only to match its neighbours (battery/network/volume
        # all set show_label = false). The state colours are another manual Stylix
        # bridge: the plugin ships hard-coded #57ff57/#ffeb57/#ff5757 that would fight
        # the palette, so they're mapped onto Noctalia roles (which come from
        # customPalettes.Stylix above) instead. mPrimary/blue for "update available"
        # follows the bar's rule of accenting only actionable states.
        "avivbintangaringga/nix-monitor:nix-monitor" = {
          show_text              = false;
          colorize_glyph         = true;
          up_to_date_color       = "on_surface";
          checking_color         = "on_surface_variant";
          update_available_color = "primary";
          unknown_color          = "on_surface_variant";
        };

        # App launcher buttons on the bottom bar. Unlike every entry above — which are
        # bare built-in widget types — these are arbitrary instance names, so each needs
        # an explicit `type`. custom_image takes a raw filesystem path: Noctalia's XDG
        # icon-theme resolver is wired only into the taskbar/tray widgets, so an icon
        # *name* here renders nothing. A bad path fails silently (blank button), so keep
        # these interpolated from papirusApps rather than hand-written.
        # Gestures bind under `actions` (left/right/middle/scroll_*). `exec <cmd>`
        # goes to runAsync, not a shell — no pipes/globs without `sh -c`. Before
        # Noctalia 5.0 these were flat `command`/`right_command`/… keys; 5.0 still
        # migrates them, but warns on every launch until the source is updated.
        # Commands match the Mod+T / Mod+B / Mod+E binds in niri.nix.
        # term/browser use Papirus' generic freedesktop icons rather than the
        # per-app logos, so the three buttons read as a matched set.
        term = {
          type         = "custom_button";
          custom_image = "${papirusApps}/utilities-terminal.svg";
          tooltip      = "Ghostty";
          actions.left = "exec ghostty";
        };
        browser = {
          type         = "custom_button";
          custom_image = "${papirusApps}/internet-web-browser.svg";
          tooltip      = "Zen Browser";
          actions.left = "exec zen-twilight";
        };
        files = {
          type         = "custom_button";
          custom_image = "${papirusApps}/org.gnome.Nautilus.svg";
          tooltip      = "Files";
          actions.left = "exec nautilus";
        };
      };
    };
  };
}
