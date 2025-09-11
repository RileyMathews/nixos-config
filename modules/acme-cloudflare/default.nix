{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myAcme;
in
{
  options.myAcme = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the custom ACME configuration with Cloudflare DNS.";
    };

    email = mkOption {
      type = types.str;
      default = "dev@rileymathews.com";
      description = "Email address for ACME registration.";
    };

    certs = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          hostName = mkOption {
            type = types.str;
            description = "The hostname for this certificate.";
          };
          
          group = mkOption {
            type = types.str;
            description = "The group that should own the certificate (e.g., 'caddy', 'nginx').";
          };
        };
      });
      default = {};
      description = "Certificate configurations keyed by hostname.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.cloudflare-credentials = {
      file = ../../secrets/cloudflare-credentials.age;
      mode = "0400";
      owner = "acme";
      group = "acme";
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.email;
      certs = mapAttrs (hostname: certCfg: {
        dnsProvider = "cloudflare";
        group = certCfg.group;
        environmentFile = config.age.secrets.cloudflare-credentials.path;
      }) cfg.certs;
    };
  };
}