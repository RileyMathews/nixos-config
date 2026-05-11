{ config, ... }:

{
  imports = [ ../nginx-multi-proxy ../dns ../container-images ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "dozzle.rileymathews.com" ];

  myNginx.proxies.dozzle = {
    listenHost = "dozzle.rileymathews.com";
    backendHost = "http://127.0.0.1:8088";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/appdata/dozzle 0755 root root -"
  ];

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.dozzle = {
    image = config.myContainerImages.dozzle;
    ports = [ "127.0.0.1:8088:8080" ];
    volumes = [ "/var/lib/appdata/dozzle:/data" ];
    environment = {
      DOZZLE_HOSTNAME = config.networking.hostName;
      DOZZLE_NO_ANALYTICS = "true";
      DOZZLE_ENABLE_ACTIONS = "false";
      DOZZLE_ENABLE_SHELL = "false";
      DOZZLE_REMOTE_AGENT = "enterprise:7007|enterprise|Homelab,discovery:7007|discovery|Homelab,yamato:7007|yamato|Homelab,data:7007|data|Homelab,defiant:7007|defiant|Homelab,bridge:7007|bridge|Homelab,worf:7007|worf|Homelab,immichdb:7007|immichdb|Homelab,thegenerosityco-staging:7007|thegenerosityco-staging|Homelab,lab:7007|lab|Homelab";
    };
  };

  systemd.services."podman-dozzle".serviceConfig = {
    Restart = "always";
    RestartSec = "5s";
  };
}
