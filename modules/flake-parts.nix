{ inputs, ... }:

{
  # `flake.modules.<class>.<name>`: where every feature file stores its lower-level
  # (NixOS / Home Manager) modules. All features merge under the one name `pc` per
  # class; the host (hosts/framework-13-pro.nix) imports those two.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];
}
