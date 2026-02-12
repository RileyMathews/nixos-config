{ config, lib, ... }:
{
    imports = [
        ../nginx-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "whisper.rileymathews.com" ];

    myNginx.proxies.whisper = {
        listenHost = "whisper.rileymathews.com";
        backendHost = "http://127.0.0.1:10300";
    };

    networking.firewall.allowedTCPPorts = [10300];

    virtualisation.oci-containers.containers.whisper = {
        image = "lscr.io/linuxserver/faster-whisper:gpu";
        ports = [ "10300:10300" ];
        volumes = [ "/var/lib/appdata/whisper/config:/config:rw" ];
        environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/Chicago";
            WHISPER_MODEL = "small";
            NVIDIA_VISIBLE_DEVICES = "all";
            NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
        };
        extraOptions = [
            "--label" "io.containers.autoupdate=registry"
            "--device=nvidia.com/gpu=all"
            "--security-opt=label=disable"
        ];
    };

}
