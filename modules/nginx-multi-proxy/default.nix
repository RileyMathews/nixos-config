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
            recommendedTlsSettings = true;
            clientMaxBodySize = "20g";

            virtualHosts = lib.mapAttrs'
                (name: proxyConfig: lib.nameValuePair proxyConfig.listenHost {
                    useACMEHost = proxyConfig.listenHost;
                    forceSSL = true;
                    locations."/" = {
                        proxyPass = proxyConfig.backendHost;

                        # We’re being explicit in extraConfig, so this is optional.
                        # Leaving it true is fine, but redundant.
                        proxyWebsockets = false;

                        extraConfig = ''
                            # --- inlined from services.nginx.recommendedProxySettings ---
                            proxy_redirect off;

                            # Proxmox/noVNC likes long-lived connections; 60s often causes console breakage/disconnects.
                            proxy_connect_timeout 3600s;
                            proxy_send_timeout    3600s;
                            proxy_read_timeout    3600s;
                            send_timeout          3600s;

                            proxy_http_version 1.1;

                            # Don't let clients close upstream keepalives (this is what NixOS sets globally)
                            proxy_set_header Connection "";

                            # --- inlined from the NixOS "recommendedProxyConfig" include ---
                            # IMPORTANT: since we set proxy_set_header in this location, we must set ALL needed headers here.
                            proxy_set_header Host              $host;
                            proxy_set_header X-Real-IP         $remote_addr;
                            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
                            proxy_set_header X-Forwarded-Proto $scheme;
                            proxy_set_header X-Forwarded-Host  $host;
                            proxy_set_header X-Forwarded-Server $hostname;

                            # --- Proxmox noVNC console (WebSocket) ---
                            proxy_set_header Upgrade    $http_upgrade;
                            proxy_set_header Connection $connection_upgrade;

                            # Avoid buffering/caching VNC websocket streams
                            proxy_buffering off;
                            proxy_request_buffering off;
                        '';
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
