{
  description = "Framework 13 NixOS configuration";

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

    niri = {
      url = "github:sodiboo/niri-flake";
      # Deliberately NOT following nixpkgs: niri-unstable needs libdisplay-info
      # 0.2.0, which nixpkgs-unstable removed (2026-08-04). niri-flake pins its
      # own compatible nixpkgs, and this also enables its binary cache. Restore
      # the follows once niri-flake migrates to libdisplay-info 0.3.
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

  outputs = { self, nixpkgs, nixos-hardware, impermanence, disko, home-manager, zen-browser, firefox-addons, niri, agenix, stylix, ... }@inputs:
  {
    nixosConfigurations.framework-13 = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        nixos-hardware.nixosModules.framework-12th-gen-intel
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        niri.nixosModules.niri
        agenix.nixosModules.default
        stylix.nixosModules.stylix
        ./hosts/framework-13
      ];
    };
  };
}
