{
  config,
  modulesPath,
  lib,
  pkgs,
  ...
}:
let
  lokiHttpPort = 3100;
  prometheusDatasourceUid = "PBFA97CFB590B2093";
  caddyMetricsPort = 2019;
  caddyScrapeTargets = map (host: "${host}:${toString caddyMetricsPort}") [
    "discovery"
    "defiant"
    "bridge"
    "data"
    "enterprise"
    "engineering"
    "familiar"
    "forgejo"
    "relay"
    "nas"
    "thegenerosityco"
    "yamato"
  ];
in
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/vms/swap-config.nix
    ./../../../modules/tailscale
    ./../../../modules/dns
    ./../../../modules/gatus
    ./../../../modules/ntfy
    ./../../../modules/caddy-multi-proxy
    ./../../../modules/dozzle
  ];
  networking.hostName = "engineering";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "grafana.rileymathews.com" ];
  networking.firewall.allowedTCPPorts = [80 443];

  virtualisation.podman.enable = true;
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];

  myCaddy.proxies.grafana = {
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
          uid = prometheusDatasourceUid;
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
        {
          name = "Loki";
          uid = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString lokiHttpPort}";
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
  environment.etc."grafana-dashboards/caddy.json".source = ./caddy-dashboard.json;

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = lokiHttpPort;
        grpc_listen_port = 9096;
      };

      common = {
        path_prefix = config.services.loki.dataDir;
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "${config.services.loki.dataDir}/chunks";
          rules_directory = "${config.services.loki.dataDir}/rules";
        };
      };

      schema_config.configs = [{
        from = "2024-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];

      compactor = {
        working_directory = "${config.services.loki.dataDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config.retention_period = "30d";
      analytics.reporting_enabled = false;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ lokiHttpPort ];

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
            "lab:9002"
          ];
        }];
      }
      {
        job_name = "caddy";
        static_configs = [{
          targets = caddyScrapeTargets;
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
