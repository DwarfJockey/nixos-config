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

  # Wallpaper: the vendored photo remapped onto the base16 palette (lutgen, with
  # luminosity preserved so the photo's structure survives the hue shift) and
  # then dimmed toward the theme background — a subtle, on-theme backdrop rather
  # than a busy neon photo. Built in the Nix store like any other asset, so it
  # survives the ephemeral root and keeps the niri overview backdrop filled.
  # Colors come from the scheme, so the wallpaper tracks it. Dim is tunable:
  # -colorize 30% = blend 30% toward base00 (higher = darker/flatter);
  # -modulate 100,80,100 = 80% saturation (lower = greyer).
  wallpaperSrc = ../wallpapers/acrylic-pour-magenta-cyan.jpg;
  base16Palette = with config.lib.stylix.colors; [
    base00 base01 base02 base03 base04 base05 base06 base07
    base08 base09 base0A base0B base0C base0D base0E base0F
  ];
  themedWallpaper = pkgs.runCommand "wallpaper-themed.png" { } ''
    ${pkgs.lutgen}/bin/lutgen apply -P -o recolored.png ${wallpaperSrc} -- \
      ${lib.concatStringsSep " " base16Palette}
    ${pkgs.imagemagick}/bin/magick recolored.png \
      -modulate 100,80,100 \
      -fill "${stylixColors.base00}" -colorize 30% \
      $out
  '';
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
  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia shell (bar / dock / control-center / lock)";
      PartOf    = [ "graphical-session.target" ];
      After     = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart      = noctaliaBin;
      Restart        = "on-failure";
      TimeoutStopSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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
        # Suppress the first-run "Welcome to Noctalia" setup wizard. Noctalia
        # otherwise shows it until a marker file exists in its state dir
        # (~/.local/state/noctalia/.setup-complete), which impermanence wipes
        # every reboot — so the wizard would return on every login. This
        # persisted config.toml key short-circuits that check.
        setup_wizard_enabled = false;
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

      # Runs once per Noctalia start (per session), when its IPC is ready. Two jobs:
      # 1. Re-assert the themed wallpaper. On a fresh boot Noctalia regenerates its
      #    non-persisted runtime state from its OWN bundled default and ignores
      #    config.toml's wallpaper path, so wallpaper-set is the only lever that
      #    applies it — do this BEFORE locking so the lock screen shows it too.
      #    (The home.activation hook above covers the switch-without-reboot case,
      #    where Noctalia keeps running and this hook doesn't re-fire.)
      # 2. Lock the session, so the autologin boots straight to the lock screen.
      hooks.started = "${pkgs.writeShellScript "noctalia-started" ''
        ${noctaliaBin} msg wallpaper-set "${themedWallpaper}"
        ${noctaliaBin} msg session lock
      ''}";

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
}
