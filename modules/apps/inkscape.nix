{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.inkscape ];
      home.persistence."/persist".directories = [ ".config/inkscape" ];
    };
}
