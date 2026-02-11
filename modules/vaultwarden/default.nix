{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [ ../nas-oci ];

    networking.firewall.allowedTCPPorts = [8222];

    age.secrets.vaultwarden-env-file = {
        file = ../../secrets/vaultwarden-env-file.age;
        # mode = "0400";
        # owner = "vaultwarden";
        # group = "vaultwarden";
    };

    services.nasOci = {
        enable = true;

        mounts.vaultwarden = {
            mountPoint = "/mnt/vaultwarden";
            device = "nas:/vaultwarden";
        };

        containers.vaultwarden = {
            definition = {
                image = "vaultwarden/server:1.35.3";
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
    };
}
