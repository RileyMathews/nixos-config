{ lib, ... }:
{
  programs.git = {
    enable = false;
    package = null;
    settings = {
      user.name = "Riley Mathews";
      user.email = "rileymathews80@gmail.com";
      pull.rebase = false;
    };
  };
}
