{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    networking.firewall.allowedTCPPorts = [8222];

    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];

    systemd.mounts = [{
        what = "nas:/main/vaultwarden";
        where = "/mnt/vaultwarden";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    age.secrets.vaultwarden-env-file = {
        file = ../../secrets/vaultwarden-env-file.age;
        # mode = "0400";
        # owner = "vaultwarden";
        # group = "vaultwarden";
    };
    systemd.services."podman-vaultwarden".after = [ "network.target" "run-agenix.d.mount" "mnt-vaultwarden.mount" ];
    systemd.services."podman-vaultwarden".requires = [ "run-agenix.d.mount" "mnt-vaultwarden.mount" ];
    virtualisation.oci-containers.containers = {
        vaultwarden = {
            image = "vaultwarden/server:1.35.1";
            ports = ["8222:8222"];
            volumes = [ "/mnt/vaultwarden/data:/data" ];
            user = "1000:1000";
            environment = {
                DOMAIN = "https://vaultwarden.rileymathews.com";
                SIGNUPS_ALLOWED = "true";
                ROCKET_ADDRESS = "0.0.0.0";
                ROCKET_PORT = "8222";
            };
            environmentFiles = [ config.age.secrets.vaultwarden-env-file.path ];
        };
    };
}
