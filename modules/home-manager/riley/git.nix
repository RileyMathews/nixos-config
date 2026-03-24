{ lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Riley Mathews";
      user.email = "rileymathews80@gmail.com";
      pull.rebase = false;
    };
  };
}
