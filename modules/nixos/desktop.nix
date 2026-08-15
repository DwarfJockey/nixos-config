{ pkgs, inputs, ... }:

let
  niriBase = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

  # niri-session calls `systemctl --user import-environment` with no arguments,
  # which systemd deprecated in 258 — every invocation prints a warning. greetd
  # runs niri-session directly on VT1 with the tty as its stdio, so that warning
  # paints a yellow line on the bare console in the gap between the greeter
  # exiting and niri taking over KMS. (noctalia-greeter-session avoids this by
  # doing `exec >/dev/null 2>&1` and logging to syslog; niri-session has no such
  # guard.) Upstream still calls it bare, so drop stderr for that one call.
  #
  # symlinkJoin rather than overrideAttrs: overriding an attr changes the
  # derivation hash and rebuilds niri from source, missing niri.cachix.org.
  # --replace-fail makes the build shout if upstream ever fixes the line.
  # `niriBase // …` so the join only overrides the store path: niri-flake reads
  # plain mkDerivation attrs off the package (providedSessions, pname, version,
  # cargoBuildNoDefaultFeatures, …) that symlinkJoin would otherwise drop.
  niriPkg = niriBase // pkgs.symlinkJoin {
    name = "niri-${niriBase.version}";
    paths = [ niriBase ];
    postBuild = ''
      rm $out/bin/niri-session
      substitute ${niriBase}/bin/niri-session $out/bin/niri-session \
        --replace-fail 'systemctl --user import-environment' \
                       'systemctl --user import-environment 2>/dev/null'
      chmod +x $out/bin/niri-session
    '';
  };
in
{
  # Niri
  programs.niri = {
    enable = true;
    package = niriPkg;
  };

  # Login (greetd + Noctalia Greeter)
  # The session slots are owned by modules/nixos/greeter.nix: it sets
  # default_session.command to noctalia-greeter-session, and nixpkgs' greetd
  # module defaults default_session.user to `greeter`. Do NOT set either here —
  # the greeter module reads default_session.user to own /var/lib/noctalia-greeter
  # and asserts that user exists, and a non-mkDefault command would shadow it.
  #
  # There is deliberately no `initial_session` (autologin). That was the previous
  # arrangement, and it made logind register the desktop as `Class=greeter`, which
  # logind treats as second-class: it refuses Lock/SetLockedHint on such a session,
  # so niri and Noctalia logged "Session does not support lock screen" on every
  # lock. Now the *greeter* is the greeter-class session, and the niri session it
  # launches is a normal `Class=user` one.
  services.greetd.enable = true;

  # XDG Portal
  # xdg-desktop-portal-gtk serves the Settings portal interface, which allows
  # apps like Zen Browser to query the system color scheme (prefer-dark).
  # Without this, browsers fall back to light mode.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Desktop services
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
