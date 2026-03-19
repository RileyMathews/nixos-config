{ lib, ... }:
{
  programs.git = {
    enable = true;
    userName = "Riley Mathews";
    userEmail = "rileymathews80@gmail.com";
    extraConfig = {
      pull.rebase = false;
    };
  };
}
