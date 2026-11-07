{ lib, pkgs, vars, ... }:

lib.mkMerge [
  # 1Password
  (lib.mkIf vars.apps.onePassword {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ vars.username ];
    };

    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        .zen-twilight-wrapped
      '';
      mode = "0755";
    };
  })

  # Steam
  (lib.mkIf vars.apps.steam {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {
          GAMEMODERUN = "1";
        };
        extraArgs = "-system-composer";
      };
      remotePlay.openFirewall = true;
    };
    programs.gamemode.enable = true;
  })

  # RomVault — not in nixpkgs. Upstream ships one .NET Framework exe run under mono.
  (lib.mkIf vars.apps.romVault (
    let
      exe = pkgs.fetchzip {
        url = "https://www.romvault.com/download/ROMVault_V3.8.0.zip";
        hash = "sha256-J9xE1fBkuw2uKVxF0rcL9kdmz59h3bWkmuprDX36tZI=";
        stripRoot = false;
      };
      # RomVault writes its config and cache beside the exe, so run a copy from a
      # persisted dir rather than from the read-only store.
      # XENVIRONMENT pins Xft.dpi to 96 for this process only. At 2x scale satellite
      # publishes Xft.dpi 192; libgdiplus sizes fonts from it but WinForms lays out
      # controls at 96, so text overflowed and clipped. 96 keeps them consistent
      # (1x, so small; mono has no working HiDPI).
      xres = pkgs.writeText "romvault-xresources" "Xft.dpi: 96\n";
      romvault = pkgs.writeShellApplication {
        name = "romvault";
        runtimeInputs = [ pkgs.mono ];
        text = ''
          dir="$HOME/RomVault"
          mkdir -p "$dir" && cd "$dir"
          cp -f --no-preserve=mode ${exe}/ROMVault38.exe .
          XENVIRONMENT=${xres} exec mono ROMVault38.exe "$@"
        '';
      };
    in
    {
      environment.systemPackages = [
        romvault
        (pkgs.makeDesktopItem {
          name = "romvault";
          desktopName = "RomVault";
          exec = "romvault";
          categories = [ "Utility" ];
        })
      ];
    }
  ))
]
