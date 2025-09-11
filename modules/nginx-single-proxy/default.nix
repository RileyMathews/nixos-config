{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myNginx;
in
{
  imports = [ ../acme-cloudflare ];
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

    myAcme = {
      enable = true;
      certs.${cfg.hostName} = {
        hostName = cfg.hostName;
        group = "nginx";
      };
    };
  };
}

