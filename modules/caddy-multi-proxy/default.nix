{ config, lib, pkgs, ... }:

with lib;

let
  enabledProxies = filterAttrs (_: proxyConfig: proxyConfig.enable) config.myCaddy.proxies;
  proxyProtocolValues = unique (mapAttrsToList (_: proxyConfig: proxyConfig.proxyProtocol) enabledProxies);
  useProxyProtocol = if enabledProxies == {} then false else head proxyProtocolValues;
in
{
  imports = [ ../acme-cloudflare ];

  options.myCaddy.proxies = mkOption {
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
      };
    }));
    default = {};
    description = "Caddy proxies configuration.";
  };

  config = {
    assertions = [
      {
        assertion = length proxyProtocolValues <= 1;
        message = "All enabled myCaddy.proxies entries must use the same proxyProtocol value because Caddy configures proxy protocol per listener, not per virtual host.";
      }
    ];

    services.caddy = {
      enable = true;
      virtualHosts = mapAttrs'
        (_: proxyConfig: nameValuePair proxyConfig.listenHost {
          useACMEHost = proxyConfig.listenHost;
          extraConfig = ''
            reverse_proxy ${proxyConfig.backendHost}
          '';
        })
        enabledProxies;
      globalConfig = mkIf useProxyProtocol ''
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

    myAcme = {
      enable = true;
      certs = mapAttrs'
        (_: proxyConfig: nameValuePair proxyConfig.listenHost {
          hostName = proxyConfig.listenHost;
          group = "caddy";
        })
        enabledProxies;
    };
  };
}
