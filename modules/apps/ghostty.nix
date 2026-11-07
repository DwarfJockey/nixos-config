{
  flake.modules.nixos.pc = {
    # GLib will not launch a Terminal=true desktop entry — nvim.desktop ("Neovim
    # wrapper", from nixpkgs' wrapNeovim), senpai.desktop — unless it can find a
    # terminal to host it. Its hardcoded fallback list is gnome-terminal, konsole,
    # xterm and friends; Ghostty is not on it and never will be, so with nothing else
    # installed the launch failed silently. The only general route is the thing GLib
    # checks *first*: an `xdg-terminal-exec` on PATH. This module supplies it and
    # writes /etc/xdg/xdg-terminals.list, read because /etc/xdg leads XDG_CONFIG_DIRS.
    #
    # The list is redundant today — xdg-terminal-exec would find Ghostty on its own
    # from `Categories=…TerminalEmulator` — but it pins the choice so a second terminal
    # arriving as somebody's dependency cannot silently win. Ghostty needs no ExecArg
    # entry: its desktop file declares `X-TerminalArgExec=-e`, which the spec reads.
    # Unlike NAUTILUS_4_EXTENSION_DIR (apps/nautilus.nix), this needs no re-login.
    xdg.terminal-exec = {
      enable = true;
      settings.default = [ "com.mitchellh.ghostty.desktop" ];
    };
  };

  flake.modules.homeManager.pc = {
    # Ghostty — theme and font come from Stylix's ghostty target.
    programs.ghostty = {
      enable = true;
      settings = {
        keybind = [
          "performable:ctrl+c=copy_to_clipboard"
          "ctrl+v=paste_from_clipboard"
        ];
      };
    };
    home.persistence."/persist".directories = [ ".config/ghostty" ];
  };
}
