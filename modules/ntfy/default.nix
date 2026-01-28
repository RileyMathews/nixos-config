{
config,
modulesPath,
lib,
...
}:
{
  imports = [../nginx-multi-proxy ../dns];
  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = ["ntfy.rileymathews.com"];

  myNginx.proxies.ntfy = {
    listenHost = "ntfy.rileymathews.com";
    backendHost = "http://127.0.0.1:8021";
  };

  environment.etc."ntfy/server.yml".text = ''
    base-url: "https://ntfy.rileymathews.com"
    listen-http: ":8021"
  '';

  virtualisation.oci-containers.containers.ntfy = {
    image = "binwiederhier/ntfy:v2.16.0";
    volumes = [ "/etc/ntfy/server.yml:/etc/ntfy/server.yml:ro" ];
    ports = [ "8021:8021" ];
    cmd = ["serve"];
  };
}
