{ config, lib, pkgs, inputs, ... }:

{
  home-manager.users.robert = {

    imports = [
      ./modules/shell.nix
      ./modules/editor.nix
      ./modules/desktop.nix
    ];

    # ── Impermanence ─────────────────────────────────────────────────────────
    home.persistence."/persist" = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
        ".config/DankMaterialShell"
        ".config/niri"
        ".config/zen"
        ".config/ghostty"
        ".config/nushell"
        ".config/1Password"
        ".config/gh"
        ".config/senpai"
        ".local/share/1Password"
        ".local/share/keyrings"
        ".local/share/org.gnome.TextEditor"
        ".local/share/Steam"
        ".local/share/nvim"
        ".ssh"
        ".claude"
      ];
      files = [
        ".local/share/recently-used.xbel"
      ];
    };

    # ── Packages ─────────────────────────────────────────────────────────────
    home.packages = with pkgs; [
      nautilus
      celluloid
      file-roller
      gnome-text-editor
      claude-code
      vipsdisp
      gh
    ];

    # ── Claude Code ──────────────────────────────────────────────────────────
    # settings.json must be a real file so /effort, /model, etc. can mutate it.
    # Activation merges declarative fields into whatever the user has saved.
    home.activation.claudeSettings =
      let
        declarative = builtins.toJSON {
          statusLine = {
            type = "command";
            command = "claude-statusline";
          };
        };
      in
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="$HOME/.claude/settings.json"
        mkdir -p "$(dirname "$settings")"

        if [ -L "$settings" ]; then
          rm "$settings"
        fi

        decl=${lib.escapeShellArg declarative}

        if [ -s "$settings" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --argjson decl "$decl" '. * $decl' "$settings" > "$tmp"
          mv "$tmp" "$settings"
        else
          printf '%s\n' "$decl" | ${pkgs.jq}/bin/jq '.' > "$settings"
        fi
      '';

    home.stateVersion = "25.05";
  };
}
