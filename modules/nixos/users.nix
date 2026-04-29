{ config, pkgs, inputs, ... }:

{
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.user-password.file = ../../secrets/user-password.age;

  users.mutableUsers = false;

  users.users.robert = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.user-password.path;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "onepassword" "gamemode" ];
    shell = pkgs.nushell;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "bak";
  };
}
