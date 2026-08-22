{
  config,
  lib,
  pkgs,
  vars,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  themedWallpaper = import ../wallpaper.nix {
    inherit pkgs lib;
    colors = config.lib.stylix.colors;
  };
in
{
  # Noctalia Greeter — the greetd greeter, replacing the old autologin. It ships
  # its own wlroots compositor; the module points greetd's default_session at
  # `noctalia-greeter-session` and runs it as the `greeter` user (which is why
  # desktop.nix must NOT override services.greetd.settings.default_session.user —
  # the module reads that name to own /var/lib/noctalia-greeter).
  #
  # Password-only by design. The greeter has no fprintd client of its own; its
  # only fingerprint route is [auth].allow_empty_password plus pam_fprintd in the
  # stack, and that is exactly the 30s stall removed in fingerprint.nix. Swipe
  # still works for sudo and for the Noctalia lock screen (its own fprintd client).
  programs.noctalia-greeter = {
    enable = true;

    settings = {
      # Picker *label* (the .desktop Name=), not the .desktop id — list them with
      # `noctalia-greeter sessions`. Sessions are discovered via XDG_DATA_DIRS
      # (nixpkgs puts displayManager.sessionData.desktops first there, and greetd's
      # PAM stack runs pam_env); the greeter's other hardcoded NixOS path,
      # /run/current-system/sw/share/wayland-sessions, does not exist. The entry
      # comes from programs.umbriel (modules/nixos/desktop.nix), which registers
      # the package in services.displayManager.sessionPackages.
      session.default = "Umbriel";
      user.default = vars.username;

      appearance = {
        scheme = "Synced"; # "Synced" = use the palette below rather than a builtin
        hide_logo = true;
        theme_mode = "dark";
        font_family = config.stylix.fonts.sansSerif.name;

        # Same Stylix base16 -> Noctalia slot mapping as the shell bridge in
        # modules/home-manager/desktop/noctalia.nix; the greeter uses the same key
        # names without the `m` prefix. A complete palette here outranks anything
        # greeter-sync would write into sync.toml, which is what we want: sync.toml
        # is mutable runtime state and this host's root is ephemeral.
        palette = {
          primary = c.base0D;
          on_primary = c.base00;
          secondary = c.base0E;
          on_secondary = c.base00;
          tertiary = c.base0C;
          on_tertiary = c.base00;
          error = c.base08;
          on_error = c.base00;
          surface = c.base00;
          on_surface = c.base05;
          surface_variant = c.base01;
          on_surface_variant = c.base04;
          outline = c.base03;
          shadow = c.base00;
          hover = c.base0C;
          on_hover = c.base00;
        };

        wallpaper = {
          path = "${themedWallpaper}";
          fill_mode = "crop";
        };
      };

      cursor = {
        theme = config.stylix.cursor.name;
        size = config.stylix.cursor.size;
        path = "${config.stylix.cursor.package}/share/icons";
      };

      keyboard.layout = vars.keyboardLayout;
    };
  };
}
