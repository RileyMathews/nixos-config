{
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/caddy-single-proxy
  ];
  networking.hostName = "borg";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  environment.systemPackages = with pkgs; [
    zsh
    stow
    starship
    gcc
    fzf
    tmux
    direnv
    zoxide
    unstablePkgs.neovim
  ];
}
