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
    ./../../modules/dns
    ./../../modules/nginx-multi-proxy
  ];
  networking.hostName = "engineering";
  nix.settings.experimental-features = ["nix-command" "flakes"];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
      priority = 10;
    }
  ];

  boot.kernel.sysctl."vm.swappiness" = 15;

  myTailscale.enable = true;
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "grafana.rileymathews.com" ];

  myNginx.proxies.grafana = {
    listenHost = "grafana.rileymathews.com";
    backendHost = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.rileymathews.com";
        http_port = 2342;
        http_addr = "127.0.0.1";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  environment.etc."grafana-dashboards/podman.json".source = ./podman-dashboard.json;
  environment.etc."grafana-dashboards/node-exporter.json".source = ./node-exporter-dashboard.json;

  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        # enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    globalConfig.scrape_interval = "10s";
    scrapeConfigs = [
      {
        job_name = "engineering_scrape";
        static_configs = [{
          targets = [ 
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" 
            "discovery:9002"
            "data:9002"
            "defiant:9002"
            "borg:9002"
            "redis:9002"
            "worf:9002"
            "bridge:9002"
            "forgejo:9002"
            "pg17:9002"
            "backup-server:9002"
            "couchdb:9002"
            "relay:9002"
            "yamato:9002"
          ];
        }];
      }
      {
        job_name = "podman";
        static_configs = [{
          targets = [
            "borg:9882"
            "data:9882"
            "defiant:9882"
            "bridge:9882"
            "discovery:9882"
            "enterprise:9882"
            "yamato:9882"
          ];
        }];
      }
    ];
  };
}
