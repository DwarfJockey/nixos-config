{
  # Senpai (IRC). Delete this file to drop IRC.
  flake.modules.homeManager.pc =
    { config, ... }:
    {
      programs.senpai = {
        enable = true;
        config = {
          address = "robert-mccoy.com:6697";
          nickname = "dwarfjockey";
          username = "dwarfjockey";
          # The password file is user-managed state, so it is read from the persisted
          # copy rather than declared here.
          password-cmd = [ "cat" "/persist${config.home.homeDirectory}/.config/senpai/password" ];
        };
      };
      home.persistence."/persist".directories = [ ".config/senpai" ];
    };
}
