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
    ./../../modules/tailscale
    ./../../modules/opencode
  ];
  networking.hostName = "laforge";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.riley = import ./home.nix;
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

}
