
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      gtk-titlebar = false;
      window-decoration = "server";
      confirm-close-surface = false;
      command = "nu";
    };
  };
}

