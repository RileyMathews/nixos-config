{ config, lib, pkgs, ... }:

{
    imports = [ ../acme-cloudflare ];
    options.myNginx.proxies = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ config, name, ... }: {
            options = {
                enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Whether to enable the service.";
                };

                listenHost = lib.mkOption {
                    type = lib.types.str;
                    default = "localhost";
                    description = "Host to listen on.";
                };

                backendHost = lib.mkOption {
                    type = lib.types.str;
                    default = "http://localhost:8080";
                    description = "Backend host to proxy to.";
                };

                proxyProtocol = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Whether to enable proxy protocol.";
                };
            };
        }));

        default = {};
        description = "Nginx proxies configuration.";
    };

    config = {
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            clientMaxBodySize = "20g";

            virtualHosts = lib.mapAttrs'
                (name: proxyConfig: lib.nameValuePair proxyConfig.listenHost {
                    useACMEHost = proxyConfig.listenHost;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = proxyConfig.backendHost;
                        proxyWebsockets = true;
                    };
                    listen = [
                        { addr = "0.0.0.0"; port = 80; proxyProtocol = proxyConfig.proxyProtocol; }
                        { addr = "0.0.0.0"; port = 443; proxyProtocol = proxyConfig.proxyProtocol; ssl = true; }
                    ];
                })
                (lib.filterAttrs (name: proxyConfig: proxyConfig.enable) config.myNginx.proxies);
        };

        myAcme = {
            enable = true;
            certs = lib.mapAttrs'
                (name: proxyConfig: lib.nameValuePair proxyConfig.listenHost {
                    hostName = proxyConfig.listenHost;
                    group = "nginx";
                })
                (lib.filterAttrs (name: proxyConfig: proxyConfig.enable) config.myNginx.proxies);
        };
    };
}
