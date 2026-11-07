{
  flake.modules.nixos.pc = {
    # GNOME keyring (freedesktop Secret Service). Provides the secrets store that
    # libsecret clients D-Bus-activate; without it they pop an "unlock keyring"
    # dialog. Keyring data lives in ~/.local/share/keyrings, which is persisted
    # (below) so it survives the ephemeral root.
    #
    # This one option is enough to auto-unlock at login. The nixpkgs module puts
    # pam_gnome_keyring into the `login` stack, and greetd's PAM service substacks
    # `login`, so the password typed at Noctalia Greeter reaches the keyring and
    # opens it. That only holds while the login keyring's password matches the
    # user password — the two must be changed together.
    services.gnome.gnome-keyring.enable = true;
  };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.seahorse ]; # keyring GUI
      home.persistence."/persist".directories = [ ".local/share/keyrings" ];
    };
}
