{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["karakeep.rileymathews.com"];

    myNginx.proxies.karakeep = {
        listenHost = "karakeep.rileymathews.com";
        backendHost = "http://127.0.0.1:3000";
    };

    services.karakeep.enable = true;
    age.secrets.karakeep-env = {
        file = ../../secrets/karakeep-env.age;
        mode = "0400";
        owner = "karakeep";
        group = "karakeep";
    };
    services.karakeep.environmentFile = config.age.secrets.karakeep-env.path;
    systemd.services."karakeep".after = [ "network.target" "run-agenix.d.mount" ];
    systemd.services."karakeep".requires = [ "run-agenix.d.mount" ];
}
