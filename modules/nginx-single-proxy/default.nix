{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNginx;
in
{
  options.myNginx = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the custom Caddy virtual host.";
    };

    hostName = mkOption {
      type = types.str;
      default = null;
      description = "Host name for the Caddy virtual host.";
    };

    reverseProxyAddress = mkOption {
      type = types.str;
      default = null;
      description = "Reverse proxy address for the Caddy virtual host.";
    };
  };
  #### **Define Configuration**
  config = mkIf cfg.enable {
    sops.secrets.cloudflare-api-key = {
      key = "cloudflare/api_key";
    };

    sops.templates.cloudflare-credentials = {
      content = ''
        CLOUDFLARE_API_KEY=${config.sops.placeholder.cloudflare-api-key}
        CLOUDFLARE_EMAIL=dev@rileymathews.com
      '';
      mode = "0400";
      owner = "nginx";
      group = "nginx";
    };

    assertions = [
      {
        assertion = cfg.hostName != null;
        message = "The option `myNginx.hostName` must be set when `myNginx.enable` is true.";
      }
      {
        assertion = cfg.reverseProxyAddress != null;
        message = "The option `myNginx.reverseProxyAddress` must be set when `myNginx.enable` is true.";
      }
    ];

    services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        # other Nginx options
        virtualHosts."${cfg.hostName}" =  {
          useACMEHost = cfg.hostName;
          forceSSL = true;
          locations."/" = {
            proxyPass = cfg.reverseProxyAddress;
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "dev@rileymathews.com";
      certs = {
        "${cfg.hostName}" = {
          dnsProvider = "cloudflare";
          group = "nginx";
          environmentFile = config.sops.templates.cloudflare-credentials.path;
        };
      };
    };
  };
}

