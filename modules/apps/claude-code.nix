{
  flake.modules.homeManager.pc =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      colors = config.lib.stylix.colors;

      # base16 has no dark diff-background slots, so blend an accent pct% over base00
      # with the same sRGB lerp the Noctalia and Umbriel bridges use.
      inherit (import ../_lib/colors.nix { inherit lib; }) over;
      mix = name: pct: over colors.withHashtag.${name} colors.withHashtag.base00 (pct / 100.0);

      # Claude Code's built-in desktop notification is an OSC 9/777 escape sequence that
      # Ghostty forwards to the daemon — stamping *its own* app icon and desktop entry, which
      # no Claude Code setting can override, because an escape sequence carries no icon. The
      # only way to get the Claude logo on it is to send the notification ourselves from the
      # Notification hook. Body text comes from the hook's stdin payload.
      claudeNotify = pkgs.writeShellApplication {
        name = "claude-notify";
        runtimeInputs = [ pkgs.jq pkgs.libnotify ];
        text = ''
          body=$(jq -r '.message // .title // empty' 2>/dev/null || true)
          notify-send --app-name="Claude Code" --icon=${./claude-logo.png} \
            "Claude Code" "''${body:-Claude Code needs your attention}"
        '';
      };

      claudeStatusline = pkgs.writeShellApplication {
        name = "claude-statusline";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          input=$(cat)
          cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
          model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
          used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

          home_dir="$HOME"
          display_dir="''${cwd/#$home_dir/\~}"

          context_part=""
          if [ -n "$used" ]; then
            context_part=" | ctx:$(printf '%.0f' "$used")%"
          fi

          printf '\033[1;34m%s\033[0m@\033[1;32m%s\033[0m  \033[1;33m%s\033[0m  \033[0;36m%s\033[0m%s\n' \
            "$(whoami)" "$(hostname -s)" "$display_dir" "$model" "$context_part"
        '';
      };
    in
    {
      home.packages = [
        pkgs.claude-code
        pkgs.nodejs # Claude Code plugin hooks shell out to `node`; the claude-code wrapper hides its own
        claudeStatusline
      ];
      home.persistence."/persist".directories = [ ".claude" ];

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
      home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";

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
            # A Notification hook runs *alongside* the built-in notification rather than
            # replacing it, so the built-in has to be switched off or every event fires
            # twice. terminal_bell is the documented off-switch for the desktop
            # notification, and it is silent here: Ghostty's default bell-features is
            # `no-system,no-audio,attention,title`, so the bell draws no second
            # notification and makes no sound — the window just gets an attention hint.
            preferredNotifChannel = "terminal_bell";
            hooks.Notification = [
              { hooks = [ { type = "command"; command = "${claudeNotify}/bin/claude-notify"; } ]; }
            ];
          };
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="$HOME/.claude/settings.json"
          mkdir -p "$(dirname "$settings")"

          decl=${lib.escapeShellArg declarative}

          tmp=$(mktemp)
          { [ -s "$settings" ] && cat "$settings" || echo '{}'; } \
            | ${pkgs.jq}/bin/jq --argjson decl "$decl" '. * $decl' > "$tmp"
          mv "$tmp" "$settings"
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

    };
}
