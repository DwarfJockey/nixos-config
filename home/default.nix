{ config, lib, pkgs, inputs, vars, ... }:

let
  colors = config.lib.stylix.colors;

  # base16 has no dark diff-background slots, so blend an accent pct% over base00.
  mix = name: pct:
    let
      channel = k:
        (lib.toInt colors."${name}-rgb-${k}" * pct
          + lib.toInt colors."base00-rgb-${k}" * (100 - pct)) / 100;
      hex = n: lib.fixedWidthString 2 "0" (lib.toHexString n);
    in
    "#" + hex (channel "r") + hex (channel "g") + hex (channel "b");
in
{
  home-manager.users.${vars.username} = {

    imports = [
      ../modules/home-manager/shell.nix
      ../modules/home-manager/editor.nix
      ../modules/home-manager/desktop.nix
    ];

    # Impermanence
    home.persistence."/persist" = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
        ".config/noctalia"
        ".config/zen"
        ".config/ghostty"
        ".config/nushell"
        ".config/1Password"
        ".config/vesktop"
        ".config/gh"
        ".config/senpai"
        ".config/dconf"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".local/share/1Password"
        ".local/share/keyrings"
        ".local/share/org.gnome.TextEditor"
        ".local/share/Steam"
        ".local/share/Bay 12 Games"
        ".local/share/nvim"
        ".local/share/gvfs-metadata"
        ".ssh"
        ".claude"
      ];
      # No `files` list: impermanence bind-mounts single files, and rename() onto a mount
      # point is EBUSY, so anything written atomically never lands. Persist directories.
    };

    # Packages
    home.packages = with pkgs; [
      nautilus
      celluloid
      file-roller
      gnome-text-editor
      claude-code
      nodejs
      vipsdisp
      gh
      seahorse
    ];

    # Claude Code
    #
    # Claude's *global* config (onboarding flags, project trust, MCP auth) lives at
    # `$CLAUDE_CONFIG_DIR/.claude.json`, defaulting to `$HOME/.claude.json` — a sibling
    # of the persisted `.claude` directory, so tmpfs ate it every reboot and the theme
    # picker replayed on the first launch after boot. Adding it to home.persistence
    # would not help: impermanence bind-mounts single files, and rename() onto a mount
    # point is EBUSY, which breaks Claude's atomic writes. Pointing CLAUDE_CONFIG_DIR
    # at the already-bind-mounted directory puts it inside a normal persisted dir
    # instead. settings.json resolves to `$CLAUDE_CONFIG_DIR/settings.json`, so it stays
    # exactly where it was.
    home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.users.users.${vars.username}.home}/.claude";

    # settings.json must be a real file so /effort, /model, etc. can mutate it.
    # Activation merges declarative fields into whatever the user has saved.
    home.activation.claudeSettings =
      let
        declarative = builtins.toJSON {
          theme = "custom:base16";
          statusLine = {
            type = "command";
            command = "claude-statusline";
          };
        };
      in
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="$HOME/.claude/settings.json"
        mkdir -p "$(dirname "$settings")"

        # One-time move of the pre-CLAUDE_CONFIG_DIR global config, so project trust,
        # MCP auth and history survive the switch instead of resetting.
        if [ -f "$HOME/.claude.json" ] && [ ! -e "$HOME/.claude/.claude.json" ]; then
          mv "$HOME/.claude.json" "$HOME/.claude/.claude.json"
        fi

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

    # Claude Code theme — the manual Stylix bridge for a target Stylix has no support
    # for, same idea as Noctalia / Umbriel / the greeter. `dark-ansi` resolves every colour
    # it is not given through the terminal's ANSI palette, which Stylix already paints
    # from base16, so only the slots the 16 colours cannot reach are overridden here:
    # base09 (the Framework accent) and the diff *backgrounds*, which `dark-ansi` would
    # otherwise draw as full-brightness ansi:green / ansi:red behind base05 text.
    home.file.".claude/themes/base16.json".text = builtins.toJSON {
      name = "base16";
      base = "dark-ansi";
      overrides = {
        claude            = colors.withHashtag.base09;
        claudeShimmer     = colors.withHashtag.base0A;
        fastMode          = colors.withHashtag.base09;
        promptBorder      = colors.withHashtag.base03;
        diffAdded         = mix "base0B" 22;
        diffRemoved       = mix "base08" 22;
        diffAddedDimmed   = mix "base0B" 12;
        diffRemovedDimmed = mix "base08" 12;
        diffAddedWord     = mix "base0B" 45;
        diffRemovedWord   = mix "base08" 45;
      };
    };

    home.stateVersion = vars.stateVersion;
  };
}
