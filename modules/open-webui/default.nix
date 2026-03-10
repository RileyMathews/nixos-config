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
    services.cloudflare-dns.domains = ["openwebui.rileymathews.com"];

    myNginx.proxies.openwebui = {
        listenHost = "openwebui.rileymathews.com";
        backendHost = "http://127.0.0.1:8080";
    };

    age.secrets.openwebui-credentials-file = {
        file = ../../secrets/openwebui-credentials-file.age;
    };

    virtualisation.oci-containers.containers = {
        open-webui = {
            image = "ghcr.io/open-webui/open-webui:0.8.10";
            ports = ["8080:8080"];
            volumes = [ "openwebui_data:/app/backend/data" ];
            environment = {
                OLLAMA_BASE_URL = "https://ollama.rileymathews.com";
            };
            environmentFiles = [ config.age.secrets.openwebui-credentials-file.path ];
            extraOptions = [
                "--label" "io.containers.autoupdate=registry"
            ];
        };
    };
}
