{ config, ... }:
{
  imports = [
    ../nas-oci
    ../restic-backup
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

  services.resticBackup = {
    enable = true;
    backups.pinchflat-data = {
      type = "path-list";
      gatusHealthcheckId = "pinchflat-backup";
      paths = [
        "/var/lib/appdata/pinchflat/config"
      ];
    };
  };

  services.nasOci = {
    enable = true;

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
          "/var/lib/appdata/pinchflat/config:/config"
          "/mnt/jellyfin/media/pinchflat:/downloads"
        ];
      };
    };
  };
}
