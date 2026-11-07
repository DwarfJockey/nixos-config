{ config, inputs, ... }:

let
  inherit (config) vars;
  inherit (config.flake) modules;
in
{
  # The one machine. Everything a feature contributes lands in modules.nixos.pc /
  # modules.homeManager.pc; this file assembles them with the host-only parts
  # (hardware, disk layout — ./framework-13-pro/) into the system. The attr name is
  # vars.hostname, not this file's name, so renaming the host is a vars edit.
  flake.nixosConfigurations.${vars.hostname} = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      modules.nixos.pc
      modules.nixos.framework-13-pro
      { home-manager.users.${vars.username}.imports = [ modules.homeManager.pc ]; }
    ];
  };

  flake.modules.nixos.framework-13-pro = {
    nixpkgs.hostPlatform = "x86_64-linux";

    # Hardware-specific: swap or drop this on anything but a Framework 13 Pro
    # (Intel Core Ultra Series 3 / Panther Lake). Note the attr has no `-13-` infix.
    imports = [ inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3 ];

    system.stateVersion = vars.stateVersion;
  };
}
