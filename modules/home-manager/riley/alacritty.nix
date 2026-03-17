{ ... }:
{
  programs.alacritty = {
    enable = true;
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
