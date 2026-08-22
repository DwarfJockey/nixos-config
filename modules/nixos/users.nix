{ config, lib, pkgs, inputs, vars, ... }:

let
  # The .age files in secrets/ are encrypted to *this* host's SSH key, so a fresh
  # install on other hardware cannot decrypt them. Setting vars.hashedPassword /
  # vars.git to plain values opts out of agenix entirely — see README.
  useAgenixPassword = vars.hashedPassword == null;
  useAgenixGit = vars.git == null;
in
{
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets =
    lib.optionalAttrs useAgenixPassword {
      user-password.file = ../../secrets/user-password.age;
    }
    # git user.name/user.email, read at runtime via programs.git.includes (shell.nix).
    # owner = the user, so their git can read the decrypted file.
    // lib.optionalAttrs useAgenixGit {
      git-identity = {
        file = ../../secrets/git-identity.age;
        owner = vars.username;
      };
    };

  users.mutableUsers = false;

  users.users.${vars.username} = {
    isNormalUser = true;
    # mutableUsers = false, so hashedPassword (not initialHashedPassword) is authoritative.
    hashedPasswordFile = lib.mkIf useAgenixPassword config.age.secrets.user-password.path;
    hashedPassword = lib.mkIf (!useAgenixPassword) vars.hashedPassword;
    # `onepassword` and `gamemode` are created by those programs' modules (apps.nix);
    # naming a group that no module created is a build-time assertion failure.
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ]
      ++ lib.optional vars.apps.onePassword "onepassword"
      ++ lib.optional vars.apps.steam "gamemode";
    shell = pkgs.nushell;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs vars; };
    backupFileExtension = "bak";
  };
}
