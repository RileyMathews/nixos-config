
{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    systemd.enable = false;
    settings = {
      gtk-titlebar = false;
      window-decoration = "server";
      confirm-close-surface = false;
      command = "fish";
      keybind = "ctrl+o=unbind";
    };
  };
}
