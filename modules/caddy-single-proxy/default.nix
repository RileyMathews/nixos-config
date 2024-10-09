{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myCaddy;
in
{
  options.myCaddy = {
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

    environmentFile = mkOption {
      type = types.path;
      default = /home/riley/cloudflare;
      description = "Path to the environment file containing DNS provider credentials.";
    };
  };

  #### **Define Configuration**
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.hostName != null;
        message = "The option `myCaddy.hostName` must be set when `myCaddy.enable` is true.";
      }
      {
        assertion = cfg.reverseProxyAddress != null;
        message = "The option `myCaddy.reverseProxyAddress` must be set when `myCaddy.enable` is true.";
      }
    ];

    services.caddy = {
      enable = true;
      virtualHosts = {
        "${cfg.hostName}" = {
          useACMEHost = cfg.hostName;
          extraConfig = ''
            reverse_proxy ${cfg.reverseProxyAddress}
          '';
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.email;
      certs = {
        "${cfg.hostName}" = {
          dnsProvider = cfg.dnsProvider;
          group = "caddy";
          environmentFile = cfg.environmentFile;
        };
      };
    };
  };
}

