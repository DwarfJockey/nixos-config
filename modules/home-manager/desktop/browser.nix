{ pkgs, inputs, ... }:

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
      extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        ublock-origin
        dearrow
        remove-youtube-s-suggestions
      ];
      id = 0;
      isDefault = true;
      # Zen paints a per-workspace theme behind the chrome: a gradient in
      # #zen-browser-background / #zen-toolbar-background, plus a grain PNG overlaid
      # at --zen-grainy-background-opacity (the theme picker's texture slider). That
      # state lives in the profile's zen-sessions.jsonlz4 — persisted, but not
      # Nix-managed — so it is suppressed here in CSS rather than via the picker,
      # leaving Stylix's flat base00. Merges with (does not replace) Stylix's
      # userChrome: the option is types.oneOf [ lines path ], and either delegates to
      # lines.merge when every definition is a string, so both are concatenated.
      # Side effect: the picker's gradient/texture sliders now appear to do nothing.
      userChrome = ''
        .zen-browser-grain { display: none !important; }

        #zen-browser-background,
        #zen-toolbar-background { display: none !important; }
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
