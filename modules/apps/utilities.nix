{
  # Everyday tools with no configuration of their own.
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        curl
        gimp
      ];
    };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        celluloid
        file-roller
        gnome-text-editor
        vipsdisp
        openscad
      ];
      home.persistence."/persist".directories = [ ".local/share/org.gnome.TextEditor" ];
    };
}
