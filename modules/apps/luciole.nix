{ inputs, ... }:
let
  luciolePkg = pkgs: inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      # System-wide (not home.packages) so its org.freedesktop.FileManager1 D-Bus
      # service ("Show in folder" from other apps) lands in the session bus's
      # service dir. Upstream's modules only add the package, so they're skipped.
      environment.systemPackages = [ (luciolePkg pkgs) ];

      # Trash, network mounts. Luciole draws its own thumbnails (no tumbler); its
      # terminal action goes through xdg-terminal-exec (apps/ghostty.nix).
      services.gvfs.enable = true;

      # /etc/xdg/mimeapps.list, so ~/.config/mimeapps.list stays the apps' to write.
      xdg.mime.defaultApplications."inode/directory" = "dev.noctalia.luciole.desktop";
    };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      # Colours: Noctalia renders Luciole's bundled template from its active palette
      # (the Stylix one, desktop/noctalia.nix) into colors.toml, which Luciole reloads
      # live. User templates run even with the builtin/community ones disabled.
      # Fonts and icons need nothing: Luciole reads GTK settings.ini (Stylix GTK target).
      programs.noctalia.settings.theme.templates.user.luciole = {
        input_path = "${luciolePkg pkgs}/share/luciole/templates/colors.toml";
        output_path = "$XDG_CONFIG_HOME/luciole/colors.toml";
      };

      home.persistence."/persist".directories = [
        ".config/luciole" # GUI settings (settings.toml), rendered colors.toml
        ".local/share/gvfs-metadata"
      ];
    };
}
