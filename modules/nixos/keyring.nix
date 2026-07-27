{ ... }:

{
  # GNOME keyring (freedesktop Secret Service). Provides the secrets store that
  # libsecret clients D-Bus-activate; without it they pop an "unlock keyring"
  # dialog. Keyring data lives in ~/.local/share/keyrings, which is persisted
  # (home/robert.nix) so it survives the ephemeral root.
  services.gnome.gnome-keyring.enable = true;

  # Auto-unlock at login. greetd autologins with no password (desktop.nix), so
  # the PAM auth phase has no passphrase to unlock with — the session phase still
  # starts the daemon, which auto-unlocks a login keyring that has an *empty*
  # password. Blank the login keyring's password once (via seahorse) so it opens
  # silently on every boot. Consistent with this host's threat model: the disk
  # is not the security boundary, same as the file-based NetworkManager/gh secrets.
  security.pam.services.greetd.enableGnomeKeyring = true;
}
