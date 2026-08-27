{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:

let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaBin = "${noctaliaPkg}/bin/noctalia";

  # Bridge Stylix -> Noctalia manually. Stylix now ships a `noctalia` target
  # (stylix.targets.noctalia) that writes programs.noctalia too, but it uses the
  # raw stylix.image for the wallpaper (this repo wants the recolored+dimmed
  # themedWallpaper below) and doesn't bridge the bar opacity — so it's disabled
  # (see stylix.targets.noctalia.enable below) in favour of this tuned bridge.
  stylixColors = config.lib.stylix.colors.withHashtag;
  # Window opacity owned by Stylix (set in theming.nix, propagated to HM via
  # followSystem). Bridged manually here: Stylix's noctalia target is disabled
  # (below) and only bridges dock/notification/osd opacity anyway, not the bar.
  stylixOpacity = config.stylix.opacity;
  # The colour roles, shared with the greeter (modules/colors.nix) — including the
  # adw-gtk3 composites, which are precomputed there because this palette parses
  # 8-digit hex and then masks the alpha off. Noctalia's shell spells the same roles
  # mFoo where the greeter uses foo_bar, so the names are mapped across:
  # `on_surface_variant` becomes `mOnSurfaceVariant`.
  inherit (import ../../colors.nix { inherit lib; }) palette;
  toShellKey =
    n:
    let
      camel = lib.toCamelCase n;
    in
    "m" + lib.toUpper (lib.substring 0 1 camel) + lib.substring 1 (-1) camel;
  noctaliaVariant = lib.mapAttrs' (n: v: lib.nameValuePair (toShellKey n) v) (palette stylixColors);
  # Single Stylix scheme (dark polarity); reuse it for both variants since mode=dark.
  noctaliaStylixPalette = {
    dark = noctaliaVariant;
    light = noctaliaVariant;
  };

  # Themed wallpaper. Lives in modules/wallpaper.nix because the Noctalia greeter
  # (modules/nixos/greeter.nix) shows the same image and can't reach into
  # home-manager scope for it. Same args => same store path, so sharing it is free.
  themedWallpaper = import ../../wallpaper.nix {
    inherit pkgs lib;
    colors = config.lib.stylix.colors;
  };

  # This repo's checkout, for the nix-monitor plugin's Update button.
  configDir = "${config.home.homeDirectory}/${vars.configDir}";
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
  home.activation.noctaliaWallpaper = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${noctaliaBin} msg wallpaper-get > /dev/null 2>&1; then
      ${noctaliaBin} msg wallpaper-set "${themedWallpaper}" || true
    fi
  '';

  # Noctalia runs as a user service (not a compositor autostart) so teardown is
  # bounded: the Quickshell binary ignores SIGTERM, so as a compositor-spawned transient
  # scope it stalled shutdown for the full 90s DefaultTimeoutStopSec. TimeoutStopSec
  # here gives it a 3s grace period, then SIGKILL (harmless — its runtime state is
  # non-persisted). Bound to graphical-session.target: Umbriel imports the Wayland
  # env into the user manager before raising the target, so the socket is reachable.
  #
  # Type = dbus makes the unit reach "active" only once Noctalia owns
  # org.kde.StatusNotifierWatcher — it hosts the system tray, and it connects to the
  # bus seconds before QML instantiates that service. Without this, After= on this
  # unit would only mean "the process was exec'd", which is useless to tray clients:
  # Electron checks NameHasOwner() once at tray-creation and never retries, so
  # 1password/vesktop silently came up with no tray icon (see umbriel.nix).
  # ponytail: couples the shell's readiness to that one bus name — if a future
  # Noctalia stops claiming it, the unit stalls in `activating` for TimeoutStartSec
  # (90s) then fails into the Restart loop, taking the bar with it. Then: back to
  # Type = simple, and move the wait into the tray apps' ExecStartPre.
  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia shell (bar / dock / control-center / lock)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = noctaliaBin;
      Type = "dbus";
      BusName = "org.kde.StatusNotifierWatcher";
      Restart = "on-failure";
      TimeoutStopSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Noctalia scans $XDG_DATA_HOME/noctalia/plugins as its last (highest-precedence)
  # plugin root with no config needed, so a single symlink is the whole install —
  # each subdirectory holding a plugin.toml is one plugin, and the scan follows
  # symlinks. ~/.local/share is not persisted, but home-manager-robert.service runs
  # at boot and re-creates this, same as every other HM dotfile on the ephemeral root.
  xdg.dataFile."noctalia/plugins/nix-monitor".source = "${inputs.noctalia-plugins}/nix-monitor";

  # Noctalia shell
  programs.noctalia = {
    enable = true;
    package = noctaliaPkg;
    # Noctalia's own UI follows Stylix via this generated palette (see the let block).
    customPalettes.Stylix = noctaliaStylixPalette;
    settings = {
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Stylix";
        # Stylix owns every themed target in this repo; Noctalia's own template
        # engine would fight it.
        templates = {
          enable_builtin_templates = false;
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
        order = [
          "top"
          "bottom"
        ];

        # Top-edge bar, replacing the old `main`. Laid out in the Noctalia GUI and
        # ported back here: the GUI writes to ~/.local/state/noctalia/settings.toml,
        # which the ephemeral root wipes on reboot (see *Noctalia settings* in
        # CLAUDE.md), so this file is the only copy that survives.
        top = {
          position = "top";
          enabled = true;
          start = [ "workspaces" ];
          center = [
            "notifications"
            "clock"
            "weather"
          ];
          end = [
            "network"
            "bluetooth"
            "volume"
            "battery"
          ];
          # Widgets sit in capsules for their geometry — padding and grouping — but
          # draw no fill: capsule_opacity is 0.0, so they read flat against the bar
          # while keeping capsule spacing. bar.bottom's capsule_group sets its own
          # opacity = 1.0 and stays visible as a single plate, and the launcher and
          # session widgets override back to 0.99 for their accent fills.
          # capsule_radius is adw-gtk3's button radius (`button { border-radius: 9px }`)
          # rather than the 4 picked by eye in the GUI, so it agrees with the geometry
          # below. capsule_border stays unset: it was an artifact of the old flat restyle.
          capsule = true;
          capsule_radius = 9;
          capsule_opacity = 0.0;
          color = "on_surface";
          font_weight = 400;
          # Geometry taken from adw-gtk3 rather than tuned by eye, so the bar reads
          # as a headerbar beside the GTK windows under it. thickness is its compact
          # variant (`headerbar.default-decoration { min-height: 36px }`, chosen over
          # the standard headerbar's 46px for vertical budget); padding is
          # `headerbar { padding: 0 6px }`; widget_spacing is GtkHeaderBar's default
          # spacing, which is Noctalia's own default too. radius (15) and border_width
          # (1.0) below already match `popover.background`'s radius and the headerbar's
          # `border-width: 0 0 1px`. All four are logical pixels on both sides —
          # thickness reaches layer-shell set_size unscaled — so they compare directly
          # despite the 2x panel.
          thickness = 36;
          # Stylix binding, not the 0.84999998 the GUI round-trips it to.
          background_opacity = stylixOpacity.desktop;
          padding = 6;
          widget_spacing = 6;
          radius = 15;
          border_width = 1.0;
          # Bar shadow is Noctalia-drawn; Umbriel's layer rules carry blur only,
          # so it has no say in this either way.
          shadow = true;
          contact_shadow = false;
          margin_ends = 0;
          margin_edge = 0;
        };

        # Second bar along the bottom edge. Everything not listed here stays at
        # Noctalia's bar defaults (margins, capsule, colors, shadow).
        bottom = {
          position = "bottom";
          enabled = true;
          # cpu/ram/sysmon are drawn as one capsule group (`g1` below) instead of three
          # separate widgets, so the zone references the group id rather than them.
          start = [
            "launcher"
            "group:g1"
          ];
          center = [ "media" ];
          end = [
            "tray"
            "caffeine"
            "clipboard"
            "nix-monitor"
            "session"
          ];
          # Same capsule treatment as bar.top; radius is adw-gtk3's button radius.
          capsule = true;
          capsule_radius = 9;
          # Capsules keep their geometry (padding, grouping) but draw no fill: the
          # widgets read flat against the bar, while bar.bottom's capsule_group keeps
          # its own opacity = 1.0 and stays visible as a single plate.
          capsule_opacity = 0.0;
          # One capsule swallowing the three system gauges. `members` names what it
          # holds; "group:g1" in a zone above is what places it.
          capsule_group = [
            {
              id = "g1";
              enabled = true;
              members = [
                "cpu"
                "ram"
                "sysmon"
              ];
              fill = "surface_variant";
              padding = 6.0;
              radius = 9.0;
              opacity = 1.0;
              accordion = false;
            }
          ];
          color = "on_surface";
          font_weight = 400;
          # adw-gtk3 compact headerbar geometry, as bar.top above.
          thickness = 36;
          background_opacity = stylixOpacity.desktop;
          padding = 6;
          widget_spacing = 6;
          radius = 15;
          # Nearly square where the bar meets the screen edge.
          radius_bottom_left = 5;
          radius_bottom_right = 5;
          border_width = 1.0;
          margin_ends = 0;
          # Always visible: windows tile above the bar instead of under it, so
          # auto-hide (and its smart_auto_hide / show_on_workspace_switch modifiers)
          # is off.
          reserve_space = true;
          auto_hide = false;
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
        # Chrome hairlines off across the shell's own UI. The Outline role still
        # colours what remains (bar edges, which are drawn from bar.*.border_width,
        # and Umbriel's window borders) — this only drops the 1px lines Noctalia
        # would otherwise draw around its buttons, cards, inputs and popups.
        button_borders = false;
        card_borders = false;
        input_borders = false;
        popup_borders = false;
        # Glyph-only launcher rows.
        launcher.show_icons = false;
        # panel_anchor_bar deliberately unset: when set it *overrides* the bar a
        # panel was opened from, so top-bar widgets would drop their panels at the
        # bottom. Unset, each panel attaches to its own bar; panels with no source
        # bar (the Mod+Space / Mod+S keybinds) fall back to the first enabled bar
        # in `bar.order`, i.e. top.
        panel = {
          transparency_mode = "glass";
          # placement: attached | floating (the only two values Noctalia accepts).
          control_center_placement = "floating";
          session_placement = "floating";
          wallpaper_placement = "floating";
          # "auto" = position the floating panel from the bar click, not screen centre.
          launcher_position = "auto";
          # The launcher docks to its bar rather than floating; launcher_position
          # and open_near_click_launcher below only bite while a panel floats.
          launcher_placement = "attached";
          clipboard_position = "auto";
          polkit_position = "auto";
          open_near_click_control_center = true;
          open_near_click_launcher = true;
          open_near_click_clipboard = true;
          open_near_click_session = true;
          open_near_click_wallpaper = true;
          # Noctalia draws popup/panel shadows (content-aware); Umbriel's single
          # global shadow covers windows, not layer surfaces. Color = the
          # palette's mShadow (base00).
          shadow = true;
        };
        shadow.alpha = 0.35;
      };
      # Noctalia's desktop widget layer is unused; the bars carry everything.
      desktop_widgets.enabled = false;

      dock.shadow = true;

      control_center = {
        sidebar = "none";
        sidebar_section = "none";
      };

      audio.enable_sounds = true;
      backdrop.enabled = true;
      battery.warning_threshold = 20;
      calendar.enabled = true;

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
      # pure friction. Mod+L (umbriel.nix) and idle lock are unaffected.
      hooks.started = "${pkgs.writeShellScript "noctalia-started" ''
        ${noctaliaBin} msg wallpaper-set "${themedWallpaper}"
      ''}";

      location.auto_locate = true;
      nightlight = {
        enabled = true;
        temperature_day = 5000;
      };
      notification.position = "top_center";
      osd.position = "bottom_center";
      weather.unit = "imperial";

      # Discovery alone doesn't load a plugin — the id has to be listed in `enabled`
      # too. `source = []` is load-bearing: with the key absent Noctalia seeds its two
      # built-in git sources (official + community) and re-clones both (~16MB) into
      # ~/.local/state/noctalia, which impermanence wipes — so that ran on every boot.
      # An explicit empty array suppresses it (Noctalia probes the raw table for the
      # array, so [] counts as configured while a missing key does not). Cost: the
      # in-shell plugin store browser is empty; plugins get added here instead, which
      # is the only way they'd survive a reboot anyway.
      plugins = {
        source = [ ];
        enabled = [ "avivbintangaringga/nix-monitor" ];
        auto_update = "none";
      };

      # Plugin-level settings (the manifest's root [[setting]] block), as opposed to
      # the per-widget-instance ones under `widget` below.
      plugin_settings."avivbintangaringga/nix-monitor" = {
        # The branch the local nixpkgs rev is compared against; matches the nixpkgs
        # input in flake.nix.
        branch = "nixos-unstable";
        # The panel's Update button. Run through `sh -lc` in a terminal, so `cd` and
        # `&&` are fine. Only the nixpkgs input is bumped, so the compositor and shell
        # stay on their pinned revs. Writes flake.lock; review and commit that as usual. optimize_command/clean_command keep their defaults
        # (nix-store --optimise -vv / nix-collect-garbage -d).
        update_command = "cd ${configDir} && nix flake update nixpkgs && sudo nixos-rebuild switch --flake .#${vars.hostname}";
        panel_card_color = "surface_variant";
        panel_card_opacity = 70;
      };

      widget = {
        battery = {
          hide_when_full = true;
          show_label = false;
        };
        brightness.show_label = false;
        # anchor pins a *center* widget's midpoint to the bar midline so its siblings
        # growing cannot drift it sideways (src/shell/bar/bar.cpp). Off here: the three
        # center widgets read as one group, notifications first.
        clock = {
          anchor = false;
          format = "{:%l:%M %P}";
          tooltip_format = "%A %B %e";
        };
        media = {
          anchor = true;
          hide_when_no_media = true;
          hide_album_art = true;
          max_length = 440;
          title_scroll = "on_hover";
        };
        network.show_label = false;
        # cpu/ram/sysmon are glyph-only gauges; sysmon is the generic stat widget,
        # pointed at disk usage so the three read as a set.
        cpu.show_value = false;
        ram.show_value = false;
        sysmon = {
          show_value = false;
          stat = "disk_used_pct";
        };
        # Launcher and session sit on accent-filled capsules, so they read as the two
        # action buttons on the bottom bar. Their own capsule_opacity overrides the
        # bar's 0.0, so these two keep a visible fill where every other widget is
        # flat. capsule_radius is left off deliberately: the GUI writes "auto" as a
        # *string* there and Noctalia only reads a number, so the absent key is what
        # gives the automatic pill radius.
        launcher = {
          glyph = "layout-grid";
          capsule = true;
          capsule_fill = "primary";
          capsule_opacity = 0.99;
          color = "on_primary";
        };
        session = {
          capsule = true;
          capsule_fill = "primary";
          capsule_opacity = 0.99;
          icon_color = "on_secondary";
        };
        weather.show_condition = false;
        # Bell stays in the bar with nothing unread, so the center group keeps a
        # stable width.
        notifications.hide_when_no_unread = false;
        # Tray items live behind a drawer button; match_adjacent_spacing keeps the
        # drawer's gap equal to its neighbours' as it opens.
        tray = {
          drawer = true;
          match_adjacent_spacing = true;
        };
        volume.show_label = false;
        # `style` is the v5 key (the pre-v5 name was `display`); it takes
        # regular | minimal | focus_hint. minimal drops the pills and colours the
        # label text instead. occupied_color would default to `secondary` (the lilac)
        # — overridden to on_surface so the orange mPrimary stays the bar's only
        # accent, per the bar.top comment above. Occupancy itself comes from
        # Noctalia's Umbriel workspace backend: ext-workspace-v1 carries only
        # active/urgent, so on a Noctalia build without Umbriel support every tag
        # renders as empty.
        workspaces = {
          style = "minimal";
          occupied_color = "on_surface";
        };

        # nix-monitor plugin widget (installed via xdg.dataFile above). Named
        # instance, so it needs an explicit `type` — the full plugin entry id, which
        # Noctalia resolves through the plugin registry. Glyph-only to match its
        # neighbours (battery/network/volume all set show_label = false). The state
        # colours are another manual Stylix bridge: the plugin ships hard-coded
        # #57ff57/#ffeb57/#ff5757 that would fight the palette, so they're mapped onto
        # Noctalia roles (which come from customPalettes.Stylix above) instead.
        nix-monitor = {
          type = "avivbintangaringga/nix-monitor:nix-monitor";
          show_text = false;
          colorize_text = true;
          up_to_date_color = "on_surface";
          checking_color = "on_surface";
          update_available_color = "error";
        };
      };

      # Lock screen layout, placed in Noctalia's widget editor and copied back here
      # verbatim — the editor writes only to the non-persisted state file, so without
      # this the login box returns to its default spot on every reboot. `cx`/`cy` are
      # the box centre in the `placement_*` logical space (1440x960 = the panel's
      # 2256x1504 at scale 2), so they only mean anything alongside those two, and the
      # instance name carries the output it was placed on.
      lockscreen_widgets = {
        enabled = true;
        schema_version = 2;
        widget_order = [ "lockscreen-login-box@eDP-1" ];
        widget."lockscreen-login-box@eDP-1" = {
          type = "login_box";
          output = "eDP-1";
          cx = 720.0;
          cy = 778.0;
          box_width = 810.0;
          box_height = 196.0;
          placement_width = 1440.0;
          placement_height = 960.0;
          rotation = 0.0;
          settings = {
            layout = "regular";
            background_color = "surface_variant";
            background_opacity = 0.88;
            background_radius = 12.0;
            input_opacity = 1.0;
            input_radius = 6.0;
            center_password_text = false;
            show_caps_lock = true;
            show_keyboard_layout = true;
            show_login_button = true;
            show_media = true;
            show_session_buttons = true;
            show_unlock_hint = true;
            show_weather = true;
          };
        };
      };
    };
  };
}
