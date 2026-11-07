{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.prusa-slicer ];
      home.persistence."/persist".directories = [ ".config/PrusaSlicer" ]; # custom MP Cadet printer profile
    };
}
