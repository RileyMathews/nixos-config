{
    config,
    lib,
    ...
}:
{
    imports = [../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["immichdb.rileymathews.com"];
    age.secrets.immich-credentials-file = {
        file = ../../secrets/immich-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        database = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
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
