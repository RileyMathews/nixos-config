{
    config,
    modulesPath,
    lib,
    unstablePkgs,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns ../restic-backup];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["homebox.rileymathews.com"];

    myNginx.proxies.homebox = {
        listenHost = "homebox.rileymathews.com";
        backendHost = "http://127.0.0.1:7745";
    };

    age.secrets.homebox-credentials-file = {
        file =  ../../secrets/homebox-credentials-file.age;
    };

    services.resticBackup = {
        enable = true;
        backups.homebox-data = {
            type = "path-list";
            gatusHealthcheckId = "backups_homebox-backup";
            paths = [ "/var/lib/appdata/homebox/data" ];
        };
    };

    virtualisation.oci-containers.containers = {
        homebox = {
            image = "ghcr.io/sysadminsmedia/homebox:0.24.1";
            ports = ["7745:7745"];
            volumes = [ "/var/lib/appdata/homebox/data:/data" ];
            user = "1000:1000";
            environment = {
                HBOX_LOG_LEVEL = "info";
                HBOX_LOG_FORMAT = "text";
                HBOX_WEB_MAX_UPLOAD_SIZE = "10";
                HBOX_OPTIONS_ALLOW_ANALYTICS = "false";
                HBOX_DATABASE_DRIVER = "postgres";
                HBOX_DATABASE_HOST = "pg17.tailscale.rileymathews.com";
                HBOX_DATABASE_PORT = "5432";
                HBOX_DATABASE_USERNAME = "homebox";
                HBOX_DATABASE_DATABASE = "homebox";
                HBOX_OPTIONS_HOSTNAME = "homebox.rileymathews.com";
                HBOX_DATABASE_SSL_MODE = "disable";
            };
            environmentFiles = [ config.age.secrets.homebox-credentials-file.path ];
        };
    };
}
