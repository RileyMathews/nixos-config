{
    config,
    modulesPath,
    lib,
    ...
}:
{
    imports = [../nginx-multi-proxy ../dns];
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["bgatus.rileymathews.com"];

    myNginx.proxies.gatus = {
      listenHost = "bgatus.rileymathews.com";
      backendHost = "http://127.0.0.1:8020";
    };

    services.gatus.enable = true;
    services.gatus.settings.webPort = 8020;
    services.gatus.configFile = ./../../modules/gatus/config.yml;
    age.secrets.gatus-credentials = {
      file = ../../secrets/gatus-credentials.age;
      mode = "0400";
      owner = "gatus";
      group = "gatus";
    };
    services.gatus.environmentFile = config.age.secrets.gatus-credentials.path;
}
