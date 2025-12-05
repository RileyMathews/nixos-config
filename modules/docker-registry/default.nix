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

    systemd.mounts = [{
        what = "nas:/main/docker_images";
        where = "/mnt/docker_images";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    systemd.services."podman-registry".unitConfig = {
        Requires = [ "mnt-docker_images.mount" ];
        After = [ "mnt-docker_images.mount" ];
    };

    virtualisation.oci-containers.containers = {
        registry = {
            image = "registry:3.0.0";
            ports = ["5000:5000"];
            volumes = [ "/mnt/docker_images:/var/lib/registry" ];
        };
    };
}
