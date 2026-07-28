{ ... }:

{
  # Ghostty — theme and font come from Stylix's ghostty target.
  programs.ghostty = {
    enable = true;
    settings = {
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
      ];
    };
  };
}
