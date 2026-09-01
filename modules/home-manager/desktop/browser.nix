{ config, lib, pkgs, inputs, ... }:

let
  # Bridge Stylix -> Zen for the handful of places its own target gets wrong.
  # Same idiom as desktop/umbriel.nix: the `#`-prefixed palette plus the adw-gtk3
  # compositing helper from modules/colors.nix.
  c = config.lib.stylix.colors.withHashtag;
  inherit (import ../../colors.nix { inherit lib; }) over;
in
{
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

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
      extensions.packages = with pkgs.firefox-addons; [
        ublock-origin
        onepassword-password-manager
        dearrow
        remove-youtube-s-suggestions
      ];
      id = 0;
      isDefault = true;
      # Merges with (does not replace) Stylix's userChrome: the option is
      # types.oneOf [ lines path ], and either delegates to lines.merge when every
      # definition is a string, so both are concatenated. `lib.mkAfter` is
      # load-bearing — without it this block lands *before* Stylix's, and the
      # corrections below target the same `:root` with the same `!important`, so
      # Stylix would win every tie. The `display: none` rules are order-independent,
      # so moving the whole block last costs nothing.
      #
      # Zen paints a per-workspace theme behind the chrome: a gradient in
      # #zen-browser-background / #zen-toolbar-background, plus a grain PNG overlaid
      # at --zen-grainy-background-opacity (the theme picker's texture slider). That
      # state lives in the profile's zen-sessions.jsonlz4 — persisted, but not
      # Nix-managed — so it is suppressed here in CSS rather than via the picker,
      # leaving Stylix's flat base00.
      # Side effect: the picker's gradient/texture sliders now appear to do nothing.
      userChrome = lib.mkAfter ''
        .zen-browser-grain { display: none !important; }

        #zen-browser-background,
        #zen-toolbar-background { display: none !important; }

        /* GTK's popover_bg_color is base01; Stylix's zen target writes base00, so
           menus sit flush with the window where every GTK popover reads as raised.
           One variable covers the family — zen-popup.css:36 feeds it into
           --panel-background-color and zen-single-components.css:284 into
           --toolbar-background-color. */
        :root {
          --arrowpanel-background: ${c.base01} !important;
        }

        /* Linux keeps popup.css's `--panel-border-color: ThreeDShadow`, which renders
           #535251 here — ~55 levels brighter than the panel it outlines. Zen clears it
           for Windows and macOS (zen-panel-ui.css) but never for Linux. GTK4 popovers
           draw no border at all; the separation is the lighter fill plus the drop
           shadow, and Zen's shadow is already comparable (measured 3 levels vs GTK's
           4). If a panel still reads flat, --panel-box-shadow is the knob. */
        :is(menupopup, panel) {
          --panel-border-color: transparent !important;
        }

        /* Must be declared on zen-workspace, not :root. ZenSpace.mjs:407 does
           `this.style.setProperty("--zen-primary-color", primaryColor)` — an inline
           style on this element — and a custom property resolves from the *nearest
           declaring ancestor*, with origin and !important only arbitrating between
           declarations on the same element. So Stylix's :root value is never consulted
           inside this subtree, and the workspace picker's accent leaks into the tab
           strip: zen-workspaces.css:410 mixes 5% of it into the selected tab, which
           measured #4D544F — green-dominant, where every slot in this scheme is warm.
           Declaring here puts us on the same element, where user origin beats the
           inline author declaration. The lightness is separate: the
           rgba(255,255,255,0.18) base is Zen's own, so the value is replaced outright
           with adw's neutral lift over the sidebar, which is what GTK's own active tab
           measures. */
        zen-workspace {
          --tab-background-color-selected: ${over c.base05 c.base01 0.1} !important;
          --tab-selected-textcolor: ${c.base05} !important;
        }

        /* Stylix points these at base00 via direct selectors; the GTK equivalents
           (dialog_bg_color, sidebar_bg_color) are base01. #sidebar-box is Firefox's
           classic bookmarks/history sidebar, not Zen's tab strip — that one already
           matches. */
        #commonDialog { background-color: ${c.base01} !important; }
        #sidebar-box,
        .sidebar-placesTree { background-color: ${c.base01} !important; }
      '';
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
}
