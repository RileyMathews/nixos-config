
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      gtk-titlebar = false;
      window-decoration = "server";
      confirm-close-surface = false;
      command = "fish";
      keybind = "ctrl+o=unbind";
    };
  };
}
