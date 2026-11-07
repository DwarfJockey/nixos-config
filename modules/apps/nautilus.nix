{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      # Trash, network mounts and MTP (gvfs); thumbnails (tumbler).
      services.gvfs.enable = true;
      services.tumbler.enable = true;

      # "Open in Ghostty" in Nautilus' right-click menu — on a selected folder, on the
      # folder background, and on a plain file (which opens that file's parent). Ghostty
      # *bundles* the extension that draws it, share/nautilus-python/extensions/ghostty.py;
      # all that was ever missing is the two things that let nautilus reach it, both of
      # which look arbitrary in isolation:
      #
      # - share/nautilus-python/extensions is not in the default environment.pathsToLink,
      #   and that list is an allowlist filtering *both* /run/current-system/sw and
      #   /etc/profiles/per-user — which is the one that matters here, since ghostty comes
      #   from home.packages. Without the entry the .py is in the closure, unreachable.
      # - NAUTILUS_4_EXTENSION_DIR is what points nautilus at libnautilus-python.so;
      #   nothing sets it outside a services.desktopManager.gnome session. It lands in
      #   /etc/pam/environment, which pam_env reads at *session start* — so a change here
      #   needs a re-login, not just a switch.
      #
      # Do not add a second "open terminal here" extension on top of this. That is what
      # programs.nautilus-open-any-terminal was, and it labels a selected folder
      # "Open in Ghostty" exactly like ghostty.py does, so folders drew the entry twice.
      environment.systemPackages = [ pkgs.nautilus-python ];
      environment.pathsToLink = [ "/share/nautilus-python/extensions" ];
      environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR =
        "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nautilus ];
      home.persistence."/persist".directories = [ ".local/share/gvfs-metadata" ];
    };
}
