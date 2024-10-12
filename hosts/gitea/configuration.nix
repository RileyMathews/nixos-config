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

  networking.hostName = "gitea";
}
