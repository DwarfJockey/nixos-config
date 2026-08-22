{ vars, ... }:

{
  # Fingerprint reader (Framework 13). Enrolled prints live in /var/lib/fprint,
  # which is persisted (persistence.nix) so enrollment survives the ephemeral root.
  # Enroll once at runtime with `fprintd-enroll`.
  #
  # This module stays imported even when vars.apps.fingerprint is off: nixos-hardware's
  # framework module sets `services.fprintd.enable = lib.mkDefault true`, so dropping
  # the import would leave fprintd on *and* lose the PAM fix below. A plain `false`
  # here outranks its mkDefault.
  services.fprintd.enable = vars.apps.fingerprint;

  # Allow a fingerprint (OR password) for sudo. There is no boot password on this
  # host, so this only affects sudo prompts.
  security.pam.services.sudo.fprintAuth = vars.apps.fingerprint;

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
