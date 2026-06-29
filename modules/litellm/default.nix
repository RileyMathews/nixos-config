{ config, pkgs, ... }:

let
  tokenDir = "/var/lib/appdata/litellm/chatgpt-tokens";
  litellmConfig = (pkgs.formats.yaml {}).generate "litellm-config.yaml" {
    model_list = [
      {
        model_name = "chatgpt-5.5";
        model_info.mode = "responses";
        litellm_params.model = "chatgpt/gpt-5.5";
      }
    ];

    litellm_settings.drop_params = true;
  };
in
{
  imports = [ ../caddy-multi-proxy ../dns ../container-images ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "litellm.rileymathews.com" ];

  myCaddy.proxies.litellm = {
    listenHost = "litellm.rileymathews.com";
    backendHost = "http://127.0.0.1:4000";
  };

  age.secrets.litellm-env-file = {
    file = ../../secrets/litellm-env-file.age;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/appdata/litellm 0750 root root -"
    "d ${tokenDir} 0700 root root -"
  ];

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.litellm = {
    image = config.myContainerImages.litellm;
    ports = [ "127.0.0.1:4000:4000" ];
    volumes = [
      "${litellmConfig}:/app/config.yaml:ro"
      "${tokenDir}:/var/lib/litellm-chatgpt"
    ];
    environment = {
      CHATGPT_AUTH_FILE = "auth.json";
      CHATGPT_TOKEN_DIR = "/var/lib/litellm-chatgpt";
    };
    environmentFiles = [ config.age.secrets.litellm-env-file.path ];
    cmd = [
      "--config"
      "/app/config.yaml"
      "--port"
      "4000"
    ];
  };

  systemd.services."podman-litellm".serviceConfig = {
    Restart = "always";
    RestartSec = "5s";
  };
}
