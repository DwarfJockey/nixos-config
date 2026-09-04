{ config, lib, pkgs, vars, ... }:

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

  # Dump the active base16 palette: swatch, slot name, hex. Baked in at build time
  # from the same config.lib.stylix.colors every other bridge reads, so it cannot
  # drift from the running theme.
  stylixColors = pkgs.writeShellScriptBin "stylix-colors" (
    let
      c = config.lib.stylix.colors;
      row = n:
        "printf '\\e[48;2;${c."${n}-rgb-r"};${c."${n}-rgb-g"};${c."${n}-rgb-b"}m      "
        + "\\e[0m  ${n}  ${c.withHashtag.${n}}\\n'\n";
    in
    lib.concatMapStrings row (map (i: "base0${i}") (lib.stringToCharacters "0123456789ABCDEF"))
  );
in
{
  home.packages = [ claudeStatusline stylixColors pkgs.ripgrep pkgs.fd ];

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

    # Only what differs from nushell's own defaults. The completions completer is
    # deliberately absent: programs.carapace below sources carapace's generated
    # nushell config, which defines the same completer and installs it into
    # $env.config.completions.external.completer itself.
    extraConfig = ''
      $env.config.show_banner = false
      $env.config.completions.algorithm = "fuzzy"
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
  programs.carapace.enable = true;

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
    # source. git silently ignores the include if the path is absent. Setting
    # vars.git puts it in the repo instead and skips agenix — see vars.nix.
    includes = lib.optional (vars.git == null) { path = "/run/agenix/git-identity"; };
    settings.user = lib.mkIf (vars.git != null) vars.git;
    settings.credential."https://github.com".helper = "!gh auth git-credential";
  };
}
