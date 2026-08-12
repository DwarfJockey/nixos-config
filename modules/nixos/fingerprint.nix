{ ... }:

{
  # Fingerprint reader (Framework 13). Enrolled prints live in /var/lib/fprint,
  # which is persisted (persistence.nix) so enrollment survives the ephemeral root.
  # Enroll once at runtime with `fprintd-enroll`.
  services.fprintd.enable = true;

  # Allow a fingerprint (OR password) for sudo. There is no boot password on this
  # host, so this only affects sudo prompts.
  security.pam.services.sudo.fprintAuth = true;

  # ...but NOT for `login`, the stack Noctalia's lock screen authenticates
  # against. nixpkgs defaults fprintAuth to services.fprintd.enable for *every*
  # PAM service, which puts pam_fprintd first as `auth sufficient`. PAM auth is
  # serialised by design, so on a graphical caller that can't render "place your
  # finger" it blocks for its full 30s default timeout before pam_unix ever sees
  # the already-typed password — that was the half-minute "Authenticating..."
  # hang at boot and after resume. Noctalia runs its own fprintd verify next to
  # its PAM call, so swipe-to-unlock still works; PAM's copy only stole the
  # device from it ("fprintd: Verification was in progress, stopping it").
  security.pam.services.login.fprintAuth = false;
}
