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

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.rileymathews.com";
      upstream-base-url = "https://ntfy.sh";
      listen-http = ":8000";
    };
  };

  myCaddy = {
    enable = true;
    hostName = "ntfy.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  networking.hostName = "ntfy";
}
