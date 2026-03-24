{ ... }:
{
  programs.alacritty = {
    enable = true;
    package = null;
    settings = {
      env.TERM = "xterm-256color";

      window.padding = {
        x = 1;
        y = 4;
      };

      font.offset.y = 3;
    };
  };
}
