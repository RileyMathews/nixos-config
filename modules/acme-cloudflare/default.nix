{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myAcme;
  providers = {
    cloudflare = {
      credentialsSecret = "cloudflare-credentials";
      credentialsFile = ../../secrets/cloudflare-credentials.age;
    };
    godaddy = {
      credentialsSecret = "godaddy-credentials";
      credentialsFile = ../../secrets/godaddy-credentials.age;
    };
  };
  usedProviderNames = unique (mapAttrsToList (_: certCfg: certCfg.dnsProvider) cfg.certs);
  mkProviderSecret = providerName:
    let
      provider = providers.${providerName};
    in
    nameValuePair provider.credentialsSecret {
      file = provider.credentialsFile;
      mode = "0400";
      owner = "acme";
      group = "acme";
    };
in
{
  options.myAcme = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the custom ACME DNS-01 configuration.";
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

          dnsProvider = mkOption {
            type = types.enum (attrNames providers);
            default = "cloudflare";
            description = "DNS provider to use for ACME DNS-01 certificate provisioning.";
          };
        };
      });
      default = {};
      description = "Certificate configurations keyed by hostname.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets = listToAttrs (map mkProviderSecret usedProviderNames);

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.email;
      certs = mapAttrs
        (hostname: certCfg:
          let
            provider = providers.${certCfg.dnsProvider};
          in
          {
            dnsProvider = certCfg.dnsProvider;
            group = certCfg.group;
            environmentFile = config.age.secrets.${provider.credentialsSecret}.path;
            extraLegoFlags = [
              "--dns.propagation-wait"
              "180s"
            ];
          })
        cfg.certs;
    };
  };
}
