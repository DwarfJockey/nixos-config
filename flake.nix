{
  description = "Framework 13 Pro NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      # Repo was renamed noctalia-shell -> noctalia; the v5 tag/branch was dropped
      # in the restructure, so track the default branch (v5 line) per upstream docs.
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-plugins = {
      # Noctalia community plugins, pinned for the nix-monitor widget
      # (modules/home-manager/desktop/noctalia.nix). Not a flake — just a tree of
      # plugin directories, each with a plugin.toml.
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };

    noctalia-greeter = {
      # greetd greeter matching the Noctalia shell. Separate repo from `noctalia`
      # above — the shell only ships a *sync* helper for it, not the greeter.
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    umbriel = {
      # Noctalia's own compositor (wlroots 0.20 + SceneFX). Safe to follow
      # nixpkgs — everything it builds against (wlroots_0_20, libxcb-wm,
      # xwayland-satellite) is in nixpkgs-unstable, so this keeps one nixpkgs
      # tree in the lock. Cost: no upstream binary cache, so it builds locally.
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xdg-desktop-portal-umbriel = {
      # Umbriel's portal backend — ScreenCast + Screenshot. Packages only, no
      # NixOS module; wired up in modules/nixos/desktop.nix.
      url = "github:noctalia-dev/xdg-desktop-portal-umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:KaylorBen/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-hardware, impermanence, disko, home-manager, umbriel, agenix, stylix, ... }@inputs:
  let
    # Every personal/host-specific value lives here — see ./vars.nix.
    vars = import ./vars.nix;
  in
  {
    nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs vars; };
      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        # Hardware-specific: swap or drop this on anything but a Framework 13 Pro
        # (Intel Core Ultra Series 3 / Panther Lake). Note the attr has no `-13-` infix.
        nixos-hardware.nixosModules.framework-intel-core-ultra-series3
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        umbriel.nixosModules.default
        agenix.nixosModules.default
        stylix.nixosModules.stylix
        ./hosts
      ];
    };
  };
}
