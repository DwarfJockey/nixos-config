let
  framework-13-pro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILj/1eycq5cJBHHXVzG3vm0yx3R3Ps551wg9yoETVRD6 framework-13-pro";
in {
  "user-password.age".publicKeys = [ framework-13-pro ];
  "git-identity.age".publicKeys = [ framework-13-pro ];
}
