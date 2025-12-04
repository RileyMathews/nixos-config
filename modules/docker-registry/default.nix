{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["registry.rileymathews.com"];

    myNginx.proxies.registry = {
        listenHost = "registry.rileymathews.com";
        backendHost = "http://127.0.0.1:5000";
    };

    fileSystems."/mnt/registry" = {
        device = "nas:/main/docker_images";
        fsType = "nfs";
        options = ["defaults"];
    };

    systemd.services."podman-registry".unitConfig = {
        Requires = [ "mnt-registry.mount" ];
        After = [ "mnt-registry.mount" ];
    };

    virtualisation.oci-containers.containers = {
        registry = {
            image = "registry:3.0.0";
            ports = ["5000:5000"];
            volumes = [ "/mnt/registry:/var/lib/registry" ];
        };
    };
}
