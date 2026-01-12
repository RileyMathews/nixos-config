{
  config,
  modulesPath,
  lib,
  unstablePkgs,
  ...
}:
{
  imports = [ ../nginx-multi-proxy ../dns ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "mealie.rileymathews.com" ];

  myNginx.proxies.mealie = {
    listenHost = "mealie.rileymathews.com";
    backendHost = "http://127.0.0.1:9000";
  };

  # Resilient NFS mount:
  # - NFSv4.2
  # - automount (mount only when accessed)
  # - bounded systemd timeouts (avoid boot/shutdown wedges)
  # - soft (I/O errors instead of D-state forever if NAS drops)
  fileSystems."/mnt/mealie" = {
    device = "nas:/mealie";
    fsType = "nfs";
    options = [
      "vers=4.2"
      "proto=tcp"
      "_netdev"
      "nofail"

      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=30s"
      "x-systemd.device-timeout=10s"

      "soft"
      "timeo=600"
      "retrans=2"
    ];
  };

  # Don’t let systemd even try to mount/automount until Tailscale is up.
  # (Unit names for /mnt/mealie are mnt-mealie.mount + mnt-mealie.automount.)
  systemd.services."mnt-mealie.mount".after = [ "tailscale-ready.service" ];
  systemd.services."mnt-mealie.mount".requires = [ "tailscale-ready.service" ];
  systemd.services."mnt-mealie.automount".after = [ "tailscale-ready.service" ];
  systemd.services."mnt-mealie.automount".requires = [ "tailscale-ready.service" ];

  age.secrets.mealie-credentials-file = {
    file = ../../secrets/mealie-credentials-file.age;
  };

  virtualisation.oci-containers.containers = {
    mealie = {
      image = "ghcr.io/mealie-recipes/mealie:v3.9.2";
      ports = [ "9000:9000" ];
      volumes = [ "/mnt/mealie/app/data:/app/data" ];
      user = "1000:1000";

      environment = {
        ALLOW_SIGNUP = "true";
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Chicago";
        DB_ENGINE = "postgres";
        POSTGRES_USER = "mealie";
        POSTGRES_SERVER = "pg17.tailscale.rileymathews.com";
        POSTGRES_PORT = "5432";
        POSTGRES_DB = "mealie";
        MAX_WORKERS = "1";
        WEB_CONCURRENCY = "1";
        BASE_URL = "bmealie.rileymathews.com";
        TOKEN_TIME = "720";
      };

      environmentFiles = [ config.age.secrets.mealie-credentials-file.path ];
    };
  };

  # Order the container behind Tailscale + ensure /mnt/mealie is mounted (via automount).
  systemd.services."podman-mealie".unitConfig = {
    RequiresMountsFor = [ "/mnt/mealie" ];
    Requires = [ "tailscale-ready.service" "mnt-mealie.automount" ];
    After = [ "tailscale-ready.service" "mnt-mealie.automount" ];
  };

  # If Mealie crashes due to I/O errors when NAS drops, bring it back automatically.
  systemd.services."podman-mealie".serviceConfig = {
    Restart = "always";
    RestartSec = "5s";
  };
}

