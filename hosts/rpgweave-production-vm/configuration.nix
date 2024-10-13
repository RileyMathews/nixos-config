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
    ./../../modules/nginx-single-proxy
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  myNginx = {
    enable = true;
    hostName = "rpgweave.com";
    reverseProxyAddress = "http://127.0.0.1:8000";
  };

  services.nginx.virtualHosts."rpgweave.com".listen = [
    {
      addr = "0.0.0.0";
      port = 80;
      proxyProtocol = true;
    }
    {
      addr = "0.0.0.0";
      port = 443;
      ssl = true;
      proxyProtocol = true;
    }
  ];

  networking.hostName = "rpgweave-production";
}
