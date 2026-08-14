{ config, lib, pkgs, ... }:

let
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
  home.packages = [ claudeStatusline pkgs.ripgrep pkgs.fd ];

  # direnv + nix-direnv: per-project shells load automatically (nushell
  # integration is wired by the Home-Manager module).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Search / preview
  programs.fzf.enable = true;
  programs.bat.enable = true;

  # Nushell
  programs.nushell = {
    enable = true;

    # home.sessionVariables only reaches hm-session-vars.sh (a POSIX script) and, for a
    # subset, environment.d for the systemd user manager. nushell is the login shell and
    # reads neither, so every HM session variable — EDITOR/VISUAL=nvim included — was
    # silently dropped in interactive shells. Values containing "$" are skipped: those are
    # POSIX expansions (XDG_CONFIG_DIRS is "${XDG_CONFIG_DIRS:+…}") that nushell would take
    # literally, and it already inherits a correct value for them from the session.
    environmentVariables =
      lib.filterAttrs (_: v: !(lib.hasInfix "$" (toString v))) config.home.sessionVariables;

    extraConfig = ''
     let carapace_completer = {|spans|
     carapace $spans.0 nushell ...$spans | from json
     }
     $env.config = {
      show_banner: false,
      completions: {
      case_sensitive: false # case-sensitive completions
      quick: true    # set to false to prevent auto-selecting completions
      partial: true    # set to false to prevent partial filling of the prompt
      algorithm: "fuzzy"    # prefix or fuzzy
      external: {
      # set to false to prevent nushell looking into $env.PATH to find more suggestions
          enable: true
      # set to lower can improve completion performance at the cost of omitting some options
          max_results: 100
          completer: $carapace_completer # check 'carapace_completer'
        }
      }
     }
     $env.PATH = ($env.PATH |
     split row (char esep) |
     prepend ${config.home.homeDirectory}/.apps |
     append /usr/bin/env
     )
     '';
    shellAliases = {
      ls = "lsd";
      ".." = "cd ..";
      vim = "nvim";
      myip = "curl http://ipecho.net/plain; echo";
    };
  };

  # lsd
  programs.lsd.enable = true;

  # Carapace
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  # Starship
  programs.starship = {
    enable = true;
    # All the per-language / per-OS Nerd Font glyphs come from upstream's
    # nerd-font-symbols preset; no need to inline the copy.
    presets = [ "nerd-font-symbols" ];
    settings = {
      add_newline = true;
      git_status.disabled = true;
      directory.read_only = " 󰌾";
    };
  };

  # Git
  programs.git = {
    enable = true;
    # Identity comes from an agenix secret at runtime (secrets/git-identity.age,
    # registered in modules/nixos/users.nix) so name/email never live in repo
    # source. git silently ignores the include if the path is absent.
    includes = [ { path = "/run/agenix/git-identity"; } ];
    settings.credential."https://github.com".helper = "!gh auth git-credential";
  };
}
