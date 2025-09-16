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
                    type = lib.types.string;
                    default = "localhost";
                    description = "Host to listen on.";
                };

                backendHost = lib.mkOption {
                    type = lib.types.string;
                    default = "http://localhost:8080";
                    description = "Backend host to proxy to.";
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

            virtualHosts = lib.mapAttrs'
                (name: proxyConfig: lib.nameValuePair proxyConfig.listenHost {
                    useACMEHost = proxyConfig.listenHost;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = proxyConfig.backendHost;
                        proxyWebsockets = true;
                    };
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
