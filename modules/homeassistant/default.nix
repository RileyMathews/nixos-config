{
    config,
    modulesPath,
    lib,
    pkgs,
    unstablePkgs,
    ...
}:
let
    haConfigFile = pkgs.writeText "configuration.yaml" (builtins.readFile ./configuration.yaml);
in
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["home.rileymathews.com"];
    services.rpcbind.enable = true;
    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];

    myNginx.proxies.homeassistant = {
        listenHost = "home.rileymathews.com";
        backendHost = "http://127.0.0.1:8123";
    };

    systemd.mounts = [{
        what = "nas:/main/homeassistant";
        where = "/mnt/homeassistant";
        type = "nfs";
        options = "defaults";

        # Make it wait for Tailscale
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale-ready.service" ];
        requires = [ "tailscale-ready.service" ];
    }];

    systemd.services."podman-homeassistant".unitConfig = {
        Requires = [ "mnt-homeassistant.mount" ];
        After = [ "mnt-homeassistant.mount" ];
    };

    environment.etc."configuration.yaml" = {
        source = ./configuration.yaml;
    };

    age.secrets.homeassistant-secrets-file = {
        file = ../../secrets/homeassistant-secrets-file.age;
    };

    virtualisation.oci-containers.containers = {
        homeassistant = {
            image = "linuxserver/homeassistant:version-2026.1.3";
            extraOptions = [ "--network=host" ];
            volumes = [ 
                "/mnt/homeassistant/config:/config"
                "${haConfigFile}:/config/configuration.yaml"
                "${config.age.secrets.homeassistant-secrets-file.path}:/config/secrets.yaml"
                "/mnt/homeassistant/media:/media"
            ];
            devices = [ "/dev/ttyACM0:/dev/ttyACM0" ];
            environment = {
                PUID = "1000";
                GUID = "1000";
                TZ = "America/Chicago";
            };
        };
    };
}
