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
  home.packages = [ claudeStatusline ];

  # ── Nushell ────────────────────────────────────────────────────────────────
  programs.nushell = {
    enable = true;
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

  # ── lsd ────────────────────────────────────────────────────────────────────
  programs.lsd.enable = true;

  # ── Carapace ───────────────────────────────────────────────────────────────
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  # ── Starship ───────────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      git_status.disabled = true;
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fossil_branch.symbol = " ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      ocaml.symbol = " ";

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };

      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";
    };
  };

  # ── Git ────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user = {
      name  = "robert";
      email = "robert@example.com";
    };
    settings.credential."https://github.com".helper = "!gh auth git-credential";
  };
}
