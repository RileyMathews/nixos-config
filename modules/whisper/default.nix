{ config, lib, ... }:
{
    imports = [
        ../nas-oci
        ../nginx-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "whisper.rileymathews.com" ];

    myNginx.proxies.whisper = {
        listenHost = "whisper.rileymathews.com";
        backendHost = "http://127.0.0.1:10300";
    };

    services.nasOci = {
        enable = true;

        mounts.whisper = {
            mountPoint = "/mnt/whisper";
            device = "nas:/whisper";
        };

        containers.whisper = {
            definition = {
                image = "lscr.io/linuxserver/faster-whisper:latest";
                ports = [ "10300:10300" ];
                volumes = [ "/mnt/whisper/config:/config:rw" ];
                environment = {
                    PUID = "1000";
                    PGID = "1000";
                    TZ = "America/Chicago";
                    WHISPER_MODEL = "tiny-int8";
                };
                extraOptions = [
                    "--label" "io.containers.autoupdate=registry"
                ];
            };
        };
    };
}

