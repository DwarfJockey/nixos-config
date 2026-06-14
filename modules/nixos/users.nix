{ config, pkgs, inputs, ... }:

{
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.user-password.file = ../../secrets/user-password.age;
  # git user.name/user.email, read at runtime via programs.git.includes (shell.nix).
  # owner = robert so the user's git can read the decrypted file.
  age.secrets.git-identity = {
    file = ../../secrets/git-identity.age;
    owner = "robert";
  };

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
