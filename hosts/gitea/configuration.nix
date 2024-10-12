{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/caddy-single-proxy
  ];

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  programs.zsh.enable = true;

  services.gitea = {
    enable = true;
    settings = {
      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
      server = {
        # ROOT_URL = "gitea.rileymathews.com";
        DOMAIN = "gitea.rileymathews.com";
      };
    };
  };

  myCaddy = {
    enable = true;
    hostName = "gitea.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:3000";
  };

  services.tailscale.enable = true;

  networking.hostName = "gitea";
}
