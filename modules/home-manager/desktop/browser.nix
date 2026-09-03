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

  # Zen Browser â Stylix themes it via its zen-browser target; tell it which
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
        remove-youtube-s-suggestions
        betterttv
      ];
      id = 0;
      isDefault = true;
      # Default engine, set by hand in the GUI. `force` is required: HM refuses to
      # clobber a search.json.mozlz4 that already exists as a real file, and this
      # profile has one. The cost is that site-offered engines can no longer be
      # added at runtime — the file becomes a store symlink. `"ddg"` is the engine
      # *id*; home-manager's search module moved off display names and warns on them.
      search = {
        force = true;
        default = "ddg";
      };
      # Merges with (does not replace) Stylix's userChrome: the option is
      # types.oneOf [ lines path ], and either delegates to lines.merge when every
      # definition is a string, so both are concatenated. `lib.mkAfter` is
      # load-bearing â without it this block lands *before* Stylix's, and the
      # corrections below target the same `:root` with the same `!important`, so
      # Stylix would win every tie. The `display: none` rules are order-independent,
      # so moving the whole block last costs nothing.
      #
      # Zen paints a per-workspace theme behind the chrome: a gradient in
      # #zen-browser-background / #zen-toolbar-background, plus a grain PNG overlaid
      # at --zen-grainy-background-opacity (the theme picker's texture slider). That
      # state lives in the profile's zen-sessions.jsonlz4 â persisted, but not
      # Nix-managed â so it is suppressed here in CSS rather than via the picker,
      # leaving Stylix's flat base00.
      # Side effect: the picker's gradient/texture sliders now appear to do nothing.
      userChrome = lib.mkAfter ''
        .zen-browser-grain { display: none !important; }

        #zen-browser-background,
        #zen-toolbar-background { display: none !important; }

        /* GTK's popover_bg_color is base01; Stylix's zen target writes base00, so
           menus sit flush with the window where every GTK popover reads as raised.
           One variable covers the family â zen-popup.css:36 feeds it into
           --panel-background-color and zen-single-components.css:284 into
           --toolbar-background-color. */
        :root {
          --arrowpanel-background: ${c.base01} !important;
        }

        /* Linux keeps popup.css's `--panel-border-color: ThreeDShadow`, which renders
           #535251 here â ~55 levels brighter than the panel it outlines. Zen clears it
           for Windows and macOS (zen-panel-ui.css) but never for Linux. GTK4 popovers
           draw no border at all; the separation is the lighter fill plus the drop
           shadow, and Zen's shadow is already comparable (measured 3 levels vs GTK's
           4). If a panel still reads flat, --panel-box-shadow is the knob. */
        :is(menupopup, panel) {
          --panel-border-color: transparent !important;
        }

        /* Must be declared on zen-workspace, not :root. ZenSpace.mjs:407 does
           `this.style.setProperty("--zen-primary-color", primaryColor)` â an inline
           style on this element â and a custom property resolves from the *nearest
           declaring ancestor*, with origin and !important only arbitrating between
           declarations on the same element. So Stylix's :root value is never consulted
           inside this subtree, and the workspace picker's accent leaks into the tab
           strip: zen-workspaces.css:410 mixes 5% of it into the selected tab, which
           measured #4D544F â green-dominant, where every slot in this scheme is warm.
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
           classic bookmarks/history sidebar, not Zen's tab strip â that one already
           matches. */
        #commonDialog { background-color: ${c.base01} !important; }
        #sidebar-box,
        .sidebar-placesTree { background-color: ${c.base01} !important; }
      '';
      # Everything below `browser.ai.control.*` is a choice made in Zen's own UI,
      # captured here so the profile stays derivable. `settings` lands in user.js,
      # which Gecko re-reads on *every* launch and which outranks prefs.js — so
      # these are re-asserted rather than merely seeded. That is what makes the
      # layout blob below sticky, and also what makes it a lock: rearranging
      # buttons in the GUI holds for the session and reverts on restart until this
      # attrset is updated to match.
      settings = {
        "browser.ai.control.default"            = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText"       = "blocked";
        "browser.ai.control.sidebarChatbot"     = "blocked";
        "browser.ai.control.smartTabGroups"     = "blocked";
        "browser.ai.control.translations"       = "blocked";

        # Zen view.
        "zen.view.use-single-toolbar"        = false;
        "zen.view.compact.enable-at-startup" = false;
        "sidebar.visibility"                 = "hide-on-close";

        # Privacy panel on "Custom". The `policies` block above already sets
        # EnableTrackingProtection with Locked = true, so the ETP radio group
        # renders locked in the UI; this pref only records which preset is selected.
        "browser.contentblocking.category" = "custom";
        # "Clear form data on shutdown". Inert on its own — it is gated behind
        # privacy.sanitize.sanitizeOnShutdown, which is off, matching the live
        # profile. Recorded for fidelity with what the panel shows.
        "privacy.clearOnShutdown_v2.formdata" = true;

        # Toolbar/button layout. Gecko stores this as a JSON *string*; building it
        # from an attrset keeps it diffable instead of one escaped line. The opaque
        # widget ids are extension buttons: `_d634138d-…_` is 1Password,
        # `_21f1ba12-…_` is Remove YouTube Suggestions.
        "browser.uiCustomization.state" = builtins.toJSON {
          placements = {
            widget-overflow-fixed-list = [ ];
            unified-extensions-area = [
              "ublock0_raymondhill_net-browser-action"
              "_21f1ba12-47e1-4a9b-ad4e-3a0260bbeb26_-browser-action"
              "firefox_betterttv_net-browser-action"
            ];
            nav-bar = [
              "back-button"
              "forward-button"
              "stop-reload-button"
              "customizableui-special-spring1"
              "vertical-spacer"
              "urlbar-container"
              "customizableui-special-spring2"
              "unified-extensions-button"
              "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
            ];
            toolbar-menubar = [ "menubar-items" ];
            TabsToolbar = [ "tabbrowser-tabs" ];
            vertical-tabs = [ ];
            PersonalToolbar = [ "import-button" "personal-bookmarks" ];
            zen-sidebar-top-buttons = [ "zen-toggle-compact-mode" ];
            zen-sidebar-foot-buttons = [
              "downloads-button"
              "zen-workspaces-button"
              "zen-create-new-button"
            ];
          };
          seen = [
            "developer-button"
            "screenshot-button"
            "ublock0_raymondhill_net-browser-action"
            "_21f1ba12-47e1-4a9b-ad4e-3a0260bbeb26_-browser-action"
            "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
            "firefox_betterttv_net-browser-action"
          ];
          dirtyAreaCache = [
            "nav-bar"
            "vertical-tabs"
            "zen-sidebar-foot-buttons"
            "PersonalToolbar"
            "unified-extensions-area"
            "toolbar-menubar"
            "TabsToolbar"
            "zen-sidebar-top-buttons"
          ];
          currentVersion = 25;
          newElementCount = 2;
        };
      };
    };
  };
}
