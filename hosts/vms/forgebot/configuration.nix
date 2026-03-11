{
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  config,
  forgebot,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    ./../../../modules/dns
    ./../../../modules/caddy-multi-proxy
    forgebot.nixosModules.forgebot
  ];
  services.cloudflare-dns = {
    enable = true;
    domains = ["forgebot.rileymathews.com" "forgebot-webui.rileymathews.com"];
  };
  myCaddy.proxies.forgebot = {
    listenHost = "forgebot.rileymathews.com";
    backendHost = "http://127.0.0.1:8765";
  };
  myCaddy.proxies.forgebot-webui = {
    listenHost = "forgebot-webui.rileymathews.com";
    backendHost = "http://127.0.0.1:4096";
  };
  networking.hostName = "forgebot";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  age.secrets.forgebot-credentials-file = {
      file = ../../../secrets/forgebot-credentials-file.age;
  };
  age.secrets.forgebot-opencode-auth-json = {
      file = ../../../secrets/forgebot-opencode-auth.json.age;
      owner = "forgebot";
      group = "forgebot";
  };

  services.forgebot = {
    enable = true;

    opencodeWebServer = {
      enabled = true;
      port = 4096;
      host = "https://forgebot-webui.rileymathews.com";
    };
    
    forgejo.url = "https://git.rileymathews.com";
    server.forgeBotHost = "https://forgebot.rileymathews.com";
    secretsFilePath = config.age.secrets.forgebot-credentials-file.path;
    opencode.credentialsFile = config.age.secrets.forgebot-opencode-auth-json.path;
  };
}
