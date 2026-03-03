{ config, lib, ... }:
{
    imports = [
        ../nginx-multi-proxy
        ../dns
    ];

    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = [ "ollama.rileymathews.com" ];

    myNginx.proxies.ollama = {
        listenHost = "ollama.rileymathews.com";
        backendHost = "http://127.0.0.1:11434";
    };

    virtualisation.oci-containers.containers.ollama = {
        image = "ollama/ollama:0.17.5";
        ports = [ "11434:11434" ];
        environment = {
            OLLAMA_HOST = "0.0.0.0:11434";
            NVIDIA_VISIBLE_DEVICES = "all";
            NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
        };
        extraOptions = [
            "--device=nvidia.com/gpu=all"
            "--security-opt=label=disable"
        ];
    };
}
