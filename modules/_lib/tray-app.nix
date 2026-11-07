# A session app as a Home Manager systemd user unit, ordered after the tray watcher.
# Not a module (paths containing `/_` are not imported): a plain function, used by the 1Password,
# Discord and Zen features.
#
# Tray apps can't be general.autostart entries: Electron asks the bus once, at
# tray-creation time, whether org.kde.StatusNotifierWatcher has an owner, and if it
# doesn't it never creates the icon — there is no XEmbed fallback on Wayland and no
# retry. Noctalia hosts that watcher and only claims the name a few seconds in, well
# after Umbriel has spawned everything, so both apps came up permanently invisible:
# running, hidden by --silent/--start-minimized, with no tray icon to restore them
# from. noctalia.service is Type = dbus on that name, so After= here is a real
# guarantee that the watcher exists. Kept soft (no Requires): if Noctalia dies the
# apps should still start, just without a tray. No Restart: quitting one deliberately
# shouldn't respawn it, matching the old autostart behaviour.
#
# graphical-session.target must be in After= too, even though WantedBy already binds
# these to it. A target implicitly gains After= on everything that Wants= it, so
# WantedBy alone gives `target After= app`; with `app After= noctalia After= target`
# that closes a cycle, and systemd breaks it by silently deleting the app's start job
# (dead unit, no tray, nothing logged but one "Found ordering cycle" line). Declaring
# the ordering explicitly cancels the implicit edge — which is exactly why
# noctalia.service, which has always listed the target in After=, never hit this.
description: exec: {
  Unit = {
    Description = description;
    PartOf = [ "graphical-session.target" ];
    After = [
      "graphical-session.target"
      "noctalia.service"
    ];
  };
  Service.ExecStart = exec;
  Install.WantedBy = [ "graphical-session.target" ];
}
