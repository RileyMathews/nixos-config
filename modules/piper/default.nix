{ config, lib, ... }:
{
    imports = [
        ../nas-oci
        ../nginx-multi-proxy
        ../dns
    ];

    networking.firewall.allowedTCPPorts = [10200];

    services.nasOci = {
        enable = true;

        mounts.piper = {
            mountPoint = "/mnt/piper";
            device = "nas:/piper";
        };

        containers.piper = {
            definition = {
                image = "lscr.io/linuxserver/piper:latest";
                ports = [ "10200:10200" ];
                volumes = [ "/mnt/piper/config:/config:rw" ];
                environment = {
                    PUID = "1000";
                    PGID = "1000";
                    TZ = "America/Chicago";
                    PIPER_VOICE = "en_US-lessac-medium";
                };
                extraOptions = [
                    "--label" "io.containers.autoupdate=registry"
                ];
            };
        };
    };
}

