{ config, ... }:
{
  imports = [
    ../nas-oci
    ../nginx-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "pinchflat.rileymathews.com" ];

  myNginx.proxies.pinchflat = {
    listenHost = "pinchflat.rileymathews.com";
    backendHost = "http://127.0.0.1:8945";
  };

  age.secrets.pinchflat-env-file = {
    file = ../../secrets/pinchflat-env-file.age;
  };

  services.nasOci = {
    enable = true;

    mounts.pinchflat = {
      mountPoint = "/mnt/pinchflat";
      device = "nas:/pinchflat";
    };

    containers.pinchflat = {
      definition = {
        image = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
        ports = [ "127.0.0.1:8945:8945" ];
        user = "1000:1000";
        environment = {
          TZ = "America/Chicago";
          PORT = "8945";
          LOG_LEVEL = "info";
        };
        environmentFiles = [ config.age.secrets.pinchflat-env-file.path ];
        volumes = [
          "/mnt/pinchflat/config:/config"
          "/mnt/jellyfin/media/pinchflat:/downloads"
        ];
      };
    };
  };
}
