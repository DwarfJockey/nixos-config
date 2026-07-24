{ ... }:

{
  # Local Btrfs snapshots of /persist — the only place durable state lives on this
  # ephemeral-root host. Snapshot-only (no external target): guards against bad
  # writes / accidental deletion, NOT disk failure. Snapshots are stored under
  # /persist/.snapshots, which is on the persistent @persist subvolume and so
  # survives reboots. An offsite restic target can be layered on here later.
  services.btrbk.instances.persist = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "24h 7d 4w";
      volume."/persist" = {
        snapshot_dir = ".snapshots"; # -> /persist/.snapshots
        subvolume = "."; # the @persist subvolume itself
      };
    };
  };
}
