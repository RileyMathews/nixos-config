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

    email = mkOption {
      type = types.str;
      default = "dev@rileymathews.com";
      description = "Email address for ACME registration.";
    };

    dnsProvider = mkOption {
      type = types.str;
      default = "cloudflare";
      description = "DNS provider for ACME DNS challenge.";
    };

  };

  #### **Define Configuration**
  config = mkIf cfg.enable {
    age.secrets.cloudflare-credentials = {
      file = ../secrets/cloudflare-credentials.age;
      mode = "0400";
      owner = "acme";
      group = "acme";
    };

    environment.etc."acme-cloudflare.env" = {
      text = ''CF_API_TOKEN_FILE=${config.age.secrets.cloudflare-credentials.path}'';
      mode = "0444";
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
      defaults.email = cfg.email;
      certs = {
        "${cfg.hostName}" = {
          dnsProvider = cfg.dnsProvider;
          group = "nginx";
          environmentFile = "/etc/acme-cloudflare.env";
        };
      };
    };
  };
}

