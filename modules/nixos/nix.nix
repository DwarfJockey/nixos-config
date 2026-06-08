{ ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # Legacy nix-env / nix-build / nix-shell don't read nixpkgs.config.
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
}
