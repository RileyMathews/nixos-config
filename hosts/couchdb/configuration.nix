{
  config,
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
    ./../../modules/dns
  ];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["couchdb.rileymathews.com"];
    myNginx.proxies.couchdb = {
        listenHost = "couchdb.rileymathews.com";
        backendHost = "http://127.0.0.1:5984";
    };

  networking.hostName = "couchdb";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  myTailscale.enable = true;

  systemd.mounts = [{
    what = "nas:/main/couchdb";
    where = "/mnt/couchdb";
    type = "nfs";
    options = "defaults";

    # Make it wait for Tailscale
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscale-ready.service" ];
    requires = [ "tailscale-ready.service" ];
  }];

  systemd.services."podman-couchdb".unitConfig = {
    Requires = [ "mnt-couchdb.mount" ];
    After = [ "mnt-couchdb.mount" ];
  };

  virtualisation.oci-containers.containers = {
    couchdb = {
      image = "couchdb:3.5.1";
      ports = ["5984:5984"];
      volumes = [ 
        "/mnt/couchdb/data:/opt/couchdb/data" 
        "/mnt/couchdb/etc/local.ini:/opt/couchdb/etc/local.ini" 
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [80 443 5984];
}
