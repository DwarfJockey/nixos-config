{ config, inputs, ... }:

let
  inherit (config) vars;
in
{
  # Home Manager as a NixOS module. The host puts modules.homeManager.pc under
  # home-manager.users.<username>; Home Manager modules get `osConfig` for the rare
  # read of NixOS state (desktop/umbriel.nix), and everything else they need comes
  # from the top-level config they close over — no extraSpecialArgs.
  flake.modules.nixos.pc = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
    };
  };

  flake.modules.homeManager.pc = {
    home.stateVersion = vars.stateVersion;
  };
}
