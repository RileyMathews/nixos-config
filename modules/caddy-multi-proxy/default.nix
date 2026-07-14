{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myCaddy;
  caddyMetricsPort = 2019;
  enabledProxies = filterAttrs (_: proxyConfig: proxyConfig.enable) cfg.proxies;
  useProxyProtocol = any (proxyConfig: proxyConfig.proxyProtocol) (attrValues enabledProxies);
in
{
  imports = [ ../acme-cloudflare ];

  options.myCaddy = {
    proxies = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enable the service.";
          };

          listenHost = mkOption {
            type = types.str;
            default = "localhost";
            description = "Host to listen on.";
          };

          backendHost = mkOption {
            type = types.str;
            default = "http://localhost:8080";
            description = "Backend host to proxy to.";
          };

          proxyProtocol = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable proxy protocol.";
          };

          useGodaddyAcme = mkOption {
            type = types.bool;
            default = false;
            description = "Use GoDaddy DNS for ACME certificate provisioning instead of Cloudflare.";
          };
        };
      }));
      default = {};
      description = "Caddy proxies configuration.";
    };
  };

  config = {
    services.caddy = {
      enable = true;
      enableReload = false;
      virtualHosts = mapAttrs'
        (_: proxyConfig: nameValuePair proxyConfig.listenHost {
          useACMEHost = proxyConfig.listenHost;
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-${replaceStrings [ "/" " " ] [ "_" "_" ] proxyConfig.listenHost}.log {
              mode 0640
              roll_size 100MiB
              roll_keep 5
              roll_keep_for 30d
            }
            format json
          '';
          extraConfig = ''
            reverse_proxy ${proxyConfig.backendHost}
          '';
        })
        enabledProxies;
      globalConfig = ''
        admin :${toString caddyMetricsPort}

        metrics {
          per_host
        }
      '' + optionalString useProxyProtocol ''

        servers :80 {
          listener_wrappers {
            proxy_protocol
          }
        }

        servers :443 {
          listener_wrappers {
            proxy_protocol
            tls
          }
        }
      '';
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ caddyMetricsPort ];

    services.alloy.enable = true;

    environment.etc."alloy/caddy.alloy".text = ''
      loki.source.file "caddy" {
        targets = [{
          __path__ = "${config.services.caddy.logDir}/access-*.log",
          job = "caddy",
          instance = "${config.networking.hostName}",
        }]
        forward_to = [loki.process.caddy.receiver]
        tail_from_end = true

        file_match {
          enabled = true
          sync_period = "10s"
        }
      }

      loki.process "caddy" {
        forward_to = [loki.write.engineering.receiver]

        stage.json {
          expressions = {
            host = "request.host",
            method = "request.method",
            status = "status",
          }
        }

        stage.labels {
          values = {
            host = "",
            method = "",
            status = "",
          }
        }
      }

      loki.write "engineering" {
        endpoint {
          url = "http://engineering:3100/loki/api/v1/push"
        }
      }
    '';

    systemd.services.alloy.serviceConfig.SupplementaryGroups = mkAfter [ "caddy" ];

    systemd.tmpfiles.rules = [
      "z ${config.services.caddy.logDir}/access-*.log 0640 caddy caddy - -"
    ];

    myAcme = {
      enable = true;
      certs = mapAttrs'
        (_: proxyConfig: nameValuePair proxyConfig.listenHost {
          hostName = proxyConfig.listenHost;
          group = "caddy";
          dnsProvider = if proxyConfig.useGodaddyAcme then "godaddy" else "cloudflare";
        })
        enabledProxies;
    };
  };
}
