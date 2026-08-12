{ ... }:

{
  # GNOME keyring (freedesktop Secret Service). Provides the secrets store that
  # libsecret clients D-Bus-activate; without it they pop an "unlock keyring"
  # dialog. Keyring data lives in ~/.local/share/keyrings, which is persisted
  # (home/robert.nix) so it survives the ephemeral root.
  #
  # This one option is enough to auto-unlock at login. The nixpkgs module puts
  # pam_gnome_keyring into the `login` stack, and greetd's PAM service substacks
  # `login`, so the password typed at Noctalia Greeter reaches the keyring and
  # opens it. That only holds while the login keyring's password matches the
  # user password — the two must be changed together.
  #
  # Nothing extra is needed for greetd itself: its PAM service is built with
  # `useDefaultRules = false` and contains only substack/include of `login`, so
  # `security.pam.services.greetd.enableGnomeKeyring` emits no rules at all. It
  # used to be set here and was always a no-op.
  services.gnome.gnome-keyring.enable = true;
}
