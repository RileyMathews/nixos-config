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
    services.cloudflare-dns.domains = ["bvaultwarden.rileymathews.com"];

    myNginx.proxies.vaultwarden = {
        listenHost = "bvaultwarden.rileymathews.com";
        backendHost = "http://127.0.0.1:8222";
    };

    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];
    fileSystems."/mnt/vaultwarden" = {
        device = "nas:/main/vaultwarden";
        fsType = "nfs";
        options = ["defaults"];
    };

    services.vaultwarden.enable = true;
    age.secrets.vaultwarden-env-file = {
        file = ../../secrets/vaultwarden-env-file.age;
        mode = "0400";
        owner = "vaultwarden";
        group = "vaultwarden";
    };
    services.vaultwarden.package = unstablePkgs.vaultwarden;
    services.vaultwarden.webVaultPackage = unstablePkgs.vaultwarden.webvault;
    services.vaultwarden.environmentFile = config.age.secrets.vaultwarden-env-file.path;
    services.vaultwarden.dbBackend = "postgresql";
    services.vaultwarden.config = {
        DOMAIN = "https://bvaultwarden.rileymathews.com";
        SIGNUPS_ALLOWED = true;
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = "8222";
        DATA_FOLDER = "/mnt/vaultwarden/data";
    };
    systemd.services."vaultwarden".after = [ "network.target" "run-agenix.d.mount" "mnt-vaultwarden.mount" ];
    systemd.services."vaultwarden".requires = [ "run-agenix.d.mount" "mnt-vaultwarden.mount" ];
}
