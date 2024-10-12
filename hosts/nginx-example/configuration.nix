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
  networking.hostName = "nginx-example";
  virtualisation.oci-containers.containers."whoami" = {
    image = "containous/whoami";
    ports = ["8000:80"];
  };

  myNginx = {
    enable = true;
    hostName = "nginx-example.rileymathews.com";
    reverseProxyAddress = "http://127.0.0.1:8000";
  };
}
