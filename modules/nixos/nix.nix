{ inputs, ... }:

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

  # Firefox/Zen add-ons as pkgs.firefox-addons.*, rather than the input's own
  # packages.<system>. Same derivations, but built against *this* pkgs, so
  # allowUnfree above applies — the input's flake evaluates a plain
  # nixpkgs.legacyPackages with the default config, which refuses any proprietary
  # add-on (1Password) no matter what this repo sets. home-manager runs with
  # useGlobalPkgs (modules/nixos/users.nix), so desktop/browser.nix sees it too.
  nixpkgs.overlays = [ inputs.firefox-addons.overlays.default ];
}
