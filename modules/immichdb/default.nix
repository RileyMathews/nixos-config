{
    config,
    lib,
    ...
}:
{
    imports = [../dns ../container-images];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["immichdb.rileymathews.com"];
    age.secrets.immich-credentials-file = {
        file = ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        database = {
            image = config.myContainerImages.immich-postgres;
            ports = [ "5432:5432" ];
            volumes = [ "immich_db_data_volume:/var/lib/postgresql/data" ];
            environment = {
                POSTGRES_INITDB_ARTGS = "--data-checksums";
                POSTGRES_USER = "immich";
                POSTGRES_DATABASE = "immich";
            };
            environmentFiles = [ config.age.secrets.immich-credentials-file.path ];
        };
    };
}
