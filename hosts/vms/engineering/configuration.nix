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
    "defiant"
    "bridge"
    "data"
    "enterprise"
    "engineering"
    "forgejo"
    "relay"
    "nas"
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
      alerting = {
        contactPoints.settings.contactPoints = [{
          orgId = 1;
          name = "ntfy";
          receivers = [{
            uid = "ntfy-home-server-alerts";
            type = "webhook";
            disableResolveMessage = false;
            settings = {
              url = "http://127.0.0.1:8021";
              httpMethod = "POST";
              payload.template = ''
                {{ coll.Dict
                  "topic" "home-server-alerts"
                  "title" (tmpl.Exec "default.title" .)
                  "message" (tmpl.Exec "default.message" .)
                  "priority" 3
                  | data.ToJSON }}
              '';
            };
          }];
        }];
        rules.settings.groups = [{
          orgId = 1;
          name = "disk-space";
          folder = "Infrastructure";
          interval = "1m";
          rules = [{
            uid = "disk-usage-above-85";
            title = "Disk usage above 85%";
            condition = "C";
            data = [
              {
                refId = "A";
                datasourceUid = prometheusDatasourceUid;
                relativeTimeRange = {
                  from = 600;
                  to = 0;
                };
                model = {
                  datasource = {
                    type = "prometheus";
                    uid = prometheusDatasourceUid;
                  };
                  editorMode = "code";
                  expr = ''
                    100 * (1 - node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!="/nix/store"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs",mountpoint!="/nix/store"}) and on(instance, device, mountpoint) node_filesystem_readonly == 0
                  '';
                  instant = true;
                  intervalMs = 1000;
                  maxDataPoints = 43200;
                  range = false;
                  refId = "A";
                };
              }
              {
                refId = "B";
                datasourceUid = "__expr__";
                model = {
                  conditions = [{
                    evaluator = {
                      params = [];
                      type = "gt";
                    };
                    operator.type = "and";
                    query.params = [ "B" ];
                    reducer.type = "last";
                    type = "query";
                  }];
                  datasource = {
                    type = "__expr__";
                    uid = "__expr__";
                  };
                  expression = "A";
                  intervalMs = 1000;
                  maxDataPoints = 43200;
                  reducer = "last";
                  refId = "B";
                  type = "reduce";
                };
              }
              {
                refId = "C";
                datasourceUid = "__expr__";
                model = {
                  conditions = [{
                    evaluator = {
                      params = [ 85 ];
                      type = "gt";
                    };
                    operator.type = "and";
                    query.params = [ "C" ];
                    reducer.type = "last";
                    type = "query";
                  }];
                  datasource = {
                    type = "__expr__";
                    uid = "__expr__";
                  };
                  expression = "B";
                  intervalMs = 1000;
                  maxDataPoints = 43200;
                  refId = "C";
                  type = "threshold";
                };
              }
            ];
            noDataState = "OK";
            execErrState = "Error";
            for = "5m";
            annotations = {
              summary = ''Disk usage is {{ printf "%.1f" $values.B.Value }}% on {{ $labels.instance }} ({{ $labels.mountpoint }})'';
              description = ''Filesystem {{ $labels.device }} mounted at {{ $labels.mountpoint }} on {{ $labels.instance }} has exceeded 85% usage for five minutes.'';
            };
            labels = {
              severity = "warning";
              service = "filesystem";
            };
            notification_settings = {
              receiver = "ntfy";
              group_by = [ "grafana_folder" "alertname" "instance" "device" "mountpoint" ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            };
          }];
        }];
      };
    };
  };

  environment.etc."grafana-dashboards/podman.json".source = ./podman-dashboard.json;
  environment.etc."grafana-dashboards/node-exporter.json".source = ./node-exporter-dashboard.json;
  environment.etc."grafana-dashboards/caddy.json".source = ./caddy-dashboard.json;
  environment.etc."grafana-dashboards/postgres.json".source = ./postgres-dashboard.json;
  environment.etc."grafana-dashboards/nas-zfs.json".source = ./nas-zfs-dashboard.json;

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
            "backup-server:9002"
            "bridge:9002"
            "data:9002"
            "defiant:9002"
            "enterprise:9002"
            "forgejo:9002"
            "immichdb:9002"
            "lab:9002"
            "nas:9002"
            "pg17:9002"
            "postgres-dev:9002"
            "rabbitmq:9002"
            "redis:9002"
            "relay:9002"
            "worf:9002"
            "yamato:9002"
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
            "data:9882"
            "defiant:9882"
            "bridge:9882"
            "enterprise:9882"
            "yamato:9882"
          ];
        }];
      }
      {
        job_name = "smartctl";
        static_configs = [{
          targets = [ "nas:9633" ];
        }];
      }
      {
        job_name = "zfs";
        static_configs = [{
          targets = [ "nas:9134" ];
        }];
      }
      {
        job_name = "postgres";
        static_configs = [{
          targets = [
            "nas:9187"
            "pg17:9187"
          ];
        }];
      }
    ];
  };
}
