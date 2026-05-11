{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [ ../restic-backup ../container-images ];

    networking.firewall.allowedTCPPorts = [8222];

    systemd.tmpfiles.rules = [
        "d /var/lib/appdata/vaultwarden 0755 riley riley -"
        "d /var/lib/appdata/vaultwarden/data 0755 riley riley -"
        "Z /var/lib/appdata/vaultwarden/data - riley riley -"
    ];

    age.secrets.vaultwarden-env-file = {
        file = ../../secrets/vaultwarden-env-file.age;
        # mode = "0400";
        # owner = "vaultwarden";
        # group = "vaultwarden";
    };

    virtualisation.oci-containers.containers = {
        vaultwarden = {
            image = config.myContainerImages.vaultwarden;
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
