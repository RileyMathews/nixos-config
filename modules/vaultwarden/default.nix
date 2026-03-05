{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [ ../restic-backup ];

    networking.firewall.allowedTCPPorts = [8222];

    age.secrets.vaultwarden-env-file = {
        file = ../../secrets/vaultwarden-env-file.age;
        # mode = "0400";
        # owner = "vaultwarden";
        # group = "vaultwarden";
    };

    virtualisation.oci-containers.containers = {
        vaultwarden = {
            image = "vaultwarden/server:1.35.4";
            ports = ["8222:8222"];
            volumes = [ "/var/lib/appdata/vaultwarden/data:/data" ];
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

    services.resticBackup = {
        enable = true;
        backups.vaultwarden-data = {
            type = "path-list";
            gatusHealthcheckId = "backups_vaultwarden-backup";
            paths = [
                "/var/lib/appdata/vaultwarden/data"
            ];
        };
    };
}
