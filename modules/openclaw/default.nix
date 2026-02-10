{ config, ... }:
{
  imports = [
    ../nas-oci
    ../nginx-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "openclaw.rileymathews.com" ];

  myNginx.proxies.openclaw = {
    listenHost = "openclaw.rileymathews.com";
    backendHost = "http://127.0.0.1:18789";
  };

  age.secrets.openclaw-credentials-file = {
    file = ../../secrets/openclaw-credentials-file.age;
  };

  services.nasOci = {
    enable = true;

    mounts.openclaw = {
      mountPoint = "/mnt/openclaw";
      device = "nas:/openclaw";
    };

    containers.openclaw = {
      definition = {
        image = "ghcr.io/openclaw/openclaw:2026.2.9";
        ports = [
          "127.0.0.1:18789:18789"
          "127.0.0.1:18790:18790"
        ];
        user = "1000:1000";
        volumes = [
          "${./openclaw.json}:/etc/openclaw/openclaw.json:ro"
          "/mnt/openclaw/state:/home/node/.openclaw/state"
          "/mnt/openclaw/workspace:/home/node/.openclaw/workspace"
        ];
        environment = {
          OPENCLAW_NIX_MODE = "1";
          OPENCLAW_HOME = "/home/node";
          OPENCLAW_CONFIG_PATH = "/etc/openclaw/openclaw.json";
          OPENCLAW_STATE_DIR = "/home/node/.openclaw/state";
          OPENCLAW_GATEWAY_PORT = "18789";
          OPENCLAW_BRIDGE_PORT = "18790";
        };
        environmentFiles = [ config.age.secrets.openclaw-credentials-file.path ];
      };
    };
  };
}
