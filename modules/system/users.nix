{ config, inputs, ... }:

let
  inherit (config) vars;
  # The .age files in secrets/ are encrypted to *this* host's SSH key, so a fresh
  # install on other hardware cannot decrypt them. Setting vars.hashedPassword /
  # vars.git to plain values opts out of agenix entirely — see README.
  useAgenixPassword = vars.hashedPassword == null;
  useAgenixGit = vars.git == null;
in
{
  flake.modules.nixos.pc =
    { config, lib, pkgs, ... }:
    {
      imports = [ inputs.agenix.nixosModules.default ];

      age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

      age.secrets =
        lib.optionalAttrs useAgenixPassword {
          user-password.file = ../../secrets/user-password.age;
        }
        # git user.name/user.email, read at runtime via programs.git.includes (shell/git.nix).
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
        # Apps that need a group add it in their own file (apps/1password.nix,
        # apps/steam.nix). Naming a group no module created is a build-time assertion
        # failure, so the group and its membership live together.
        extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
        shell = pkgs.nushell;
      };
    };
}
