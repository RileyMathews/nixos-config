{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myCaddy;
in
{
  imports = [ ../acme-cloudflare ];
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
  };

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

    myAcme = {
      enable = true;
      certs.${cfg.hostName} = {
        hostName = cfg.hostName;
        group = "caddy";
      };
    };
  };
}

