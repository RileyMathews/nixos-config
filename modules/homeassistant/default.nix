{
    config,
    pkgs,
    ...
}:
let
    haConfigFile = pkgs.writeText "configuration.yaml" (builtins.readFile ./configuration.yaml);
in
{
    imports = [../nginx-multi-proxy ../dns ../restic-backup];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["home.rileymathews.com"];

    myNginx.proxies.homeassistant = {
        listenHost = "home.rileymathews.com";
        backendHost = "http://127.0.0.1:8123";
    };

    environment.etc."configuration.yaml" = {
        source = ./configuration.yaml;
    };

    age.secrets.homeassistant-secrets-file = {
        file = ../../secrets/homeassistant-secrets-file.age;
    };

    virtualisation.oci-containers.containers = {
        homeassistant = {
            image = "linuxserver/homeassistant:version-2026.3.1";
            extraOptions = [ "--network=host" ];
            volumes = [ 
                "/var/lib/appdata/homeassistant/config:/config"
                "${haConfigFile}:/config/configuration.yaml"
                "${config.age.secrets.homeassistant-secrets-file.path}:/config/secrets.yaml"
                "/var/lib/appdata/homeassistant/media:/media"
            ];
            devices = [ "/dev/ttyACM0:/dev/ttyACM0" ];
            environment = {
                PUID = "1000";
                GUID = "1000";
                TZ = "America/Chicago";
            };
        };
    };

    services.resticBackup = {
        enable = true;
        backups.homeassistant-data = {
            type = "path-list";
            gatusHealthcheckId = "backups_homeassistant-backup";
            paths = [
                "/var/lib/appdata/homeassistant/config"
                "/var/lib/appdata/homeassistant/media"
            ];
        };
    };
}
