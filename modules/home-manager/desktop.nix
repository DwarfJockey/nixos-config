{ ... }:

{
  imports = [
    ./desktop/niri.nix
    ./desktop/noctalia.nix
    ./desktop/browser.nix
    ./desktop/comms.nix
    ./desktop/terminal.nix
  ];

  # GTK / Qt — theme, icons, cursor, and fonts are owned by Stylix
  # (modules/nixos/theming.nix); these just enable the integrations.
  gtk.enable = true;
  qt.enable = true;
}
