{ config, lib, ... }:
{
    imports = [
        ../nginx-multi-proxy
        ../dns
        ../restic-backup
    ];

    networking.firewall.allowedTCPPorts = [10200];

    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.piper = {
        image = "lscr.io/linuxserver/piper:latest";
        ports = [ "10200:10200" ];
        volumes = [ "/var/lib/appdata/piper/config:/config:rw" ];
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
}
