{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      # Polkit agent. Neither Umbriel nor Noctalia registers one, so without this
      # `fprintd-enroll`/`pkexec` get an instant, promptless PermissionDenied. GTK
      # (mate-polkit), not a Qt/QML agent: Stylix's qt target exports
      # QT_STYLE_OVERRIDE=kvantum, which a QML agent takes as a Quick Controls style
      # and segfaults on.
      systemd.user.services.polkit-agent = {
        description = "Polkit authentication agent (mate-polkit)";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
          Restart = "on-failure";
        };
      };
    };
}
