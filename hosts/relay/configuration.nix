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
    ./../../modules/nginx-multi-proxy
  ];
  networking.hostName = "relay";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  myNginx.proxies.rpgweave = {
    listenHost = "rpgweave.com";
    backendHost = "http://rpgweave:80";
    proxyProtocol = true;
  };
  myNginx.proxies.rpgweave-staging = {
    listenHost = "staging.rpgweave.com";
    backendHost = "http://rpgweave-staging:80";
    proxyProtocol = true;
  };
  myNginx.proxies.vaultwarden = {
    listenHost = "vaultwarden.rileymathews.com";
    backendHost = "http://worf:8222";
    proxyProtocol = true;
  };
  myNginx.proxies.proxmox = {
    listenHost = "pve.rileymathews.com";
    backendHost = "https://shipyard:8006";
    proxyProtocol = true;
  };
}

