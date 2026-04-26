{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../home/robert.nix
  ];

  # ── Flakes ──────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # ── Unfree packages ──────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── Niri ─────────────────────────────────────────────────────────────────────
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  # Disable niri-flake's default polkit agent — DMS provides its own
  systemd.user.services.niri-flake-polkit.enable = false;

  # ── Boot ────────────────────────────────────────────────────────────────────
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    plymouth.enable = true;
    
    # Enable "Silent Boot"
    consoleLogLevel = 0;
    initrd = {
      systemd.enable = true;
      verbose = false;
    };
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "intel_pstate=active"
    ];
  };

  # ── Networking ──────────────────────────────────────────────────────────────
  networking = {
    hostName = "framework-13";
    networkmanager.enable = true;
  };

  # ── Locale / Time ───────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── DankGreeter (display manager) ───────────────────────────────────────────
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/robert";
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "robert";
  };

  # ── Stylix (system-wide theming) ─────────────────────────────────────────────
  stylix = {
    enable = true;
    polarity = "dark";
    image =
      let c = config.lib.stylix.colors; in
      pkgs.runCommand "wallpaper.png" { buildInputs = [ pkgs.imagemagick ]; } ''
        magick -size 2880x1920 \
          gradient:"#${c.base00}"-"#${c.base01}" \
          \( -size 2880x1920 xc:none \
             -fill "#${c.base0B}18" \
             -draw "circle 2880,1920 1800,900" \
          \) -composite \
          \( -size 2880x1920 xc:none \
             -fill "#${c.base0D}12" \
             -draw "circle 0,0 800,800" \
          \) -composite \
          $out
      '';
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tomorrow-night.yaml";
    fonts = {
      serif = { package = pkgs.noto-fonts; name = "Noto Serif"; };
      sansSerif = { package = pkgs.adwaita-fonts; name = "Adwaita Sans"; };
      monospace = { package = pkgs.nerd-fonts.fira-code; name = "FiraCode Nerd Font"; };
      sizes = {
        applications = 11;
        terminal = 11;
      };
    };
    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
    };
    icons = {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      dark = "Adwaita";
      light = "Adwaita";
    };
    targets = {
      console.enable = false;
      plymouth.enable = false;
    };
  };
  
  # ── XDG Portal ───────────────────────────────────────────────────────────────
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode regardless of Stylix settings.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Sound ───────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Hardware acceleration (Intel 12th gen) ────────────────────────────────
  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver
    pkgs.libva-vdpau-driver
    pkgs.libvdpau-va-gl
  ];

  # ── Power & thermal management ────────────────────────────────────────────
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── Desktop services ─────────────────────────────────────────────────────────
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # ── Network discovery (Nautilus) ──────────────────────────────────────────
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # ── 1Password ────────────────────────────────────────────────────────────────
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "robert" ];
  };

  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      .zen-twilight-wrapped
    '';
    mode = "0755";
  };

  # ── Steam ────────────────────────────────────────────────────────────────────
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

  # ── Impermanence ─────────────────────────────────────────────────────────────
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/var/lib/systemd/coredump"
      "/var/lib/AccountsService"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # ── Users ────────────────────────────────────────────────────────────────────
  users.mutableUsers = false;

  users.users.robert = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$bzMV86c8qJfFTEVKgVeFH.$wala41vF7kWKzZ3PWo8iWEp2RtuWEehh0WRHCw0NyiA";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "onepassword" "gamemode" ];
    shell = pkgs.nushell;
  };

  # ── Home Manager ─────────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "bak";
  };

  # ── Base packages ────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    python3
    vim
    gimp
    samba
    xwayland-satellite
  ];

  security.sudo.wheelNeedsPassword = true;

  system.stateVersion = "25.05";
}
