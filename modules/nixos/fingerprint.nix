{ ... }:

{
  # Fingerprint reader (Framework 13). Enrolled prints live in /var/lib/fprint,
  # which is persisted (persistence.nix) so enrollment survives the ephemeral root.
  # Enroll once at runtime with `fprintd-enroll`.
  services.fprintd.enable = true;

  # Allow a fingerprint (OR password) for sudo. There is no boot password on this
  # host, so this only affects sudo prompts.
  security.pam.services.sudo.fprintAuth = true;
}
