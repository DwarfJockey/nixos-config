{
  config,
  lib,
  pkgs,
  vars,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  inherit (import ../colors.nix { inherit lib; }) palette;
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

        # The shared colour roles (modules/colors.nix), which the Noctalia shell
        # renders from too — the greeter takes the key names as-is where the shell
        # prefixes them with `m`. A complete palette here outranks anything
        # greeter-sync would write into sync.toml, which is what we want: sync.toml
        # is mutable runtime state and this host's root is ephemeral.
        palette = palette c;

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
