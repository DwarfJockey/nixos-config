let
  framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5jhk8Tl4rxmbqQTxSK9+Z6gLylOd9xh4elHO1vmQox framework-13";
in {
  "user-password.age".publicKeys = [ framework-13 ];
}
