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

  # gatus service tries to use systemd dynamic users
  # to provision a user but we cannot use this as
  # we need to give agenix secrets permissions to the user
  # before the service starts
  users.groups.gatus = { };
  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
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
  systemd.services."gatus".after = [ "network.target" "run-agenix.d.mount" ];
  systemd.services."gatus".requires = [ "run-agenix.d.mount" ];
}
