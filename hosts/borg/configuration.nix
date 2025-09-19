{
  config,
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/tailscale
    ./../../modules/dns
    ./../../modules/nginx-multi-proxy
    ./../../modules/gatus
    ./../../modules/karakeep
    ./../../modules/searxng
  ];
  networking.hostName = "borg";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  services.cloudflare-dns = {
    enable = true;
    domains = [
      "betasearch.rileymathews.com"
      # "bgatus.rileymathews.com"
    ];
  };

  myNginx.proxies.searxng = {
    listenHost = "betasearch.rileymathews.com";
    backendHost = "http://127.0.0.1:8000";
  };

  virtualisation.podman.enable = true;

  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];

  virtualisation.oci-containers.containers = {
    searxng = {
      image = "docker.io/searxng/searxng:latest";
      ports = ["8000:8080"];
      extraOptions = [
        "--label" "io.containers.autoupdate=registry"
      ];
    };
  };

  # myNginx.proxies.gatus = {
  #     listenHost = "bgatus.rileymathews.com";
  #     backendHost = "http://127.0.0.1:8020";
  # };
  #
  # services.gatus.enable = true;
  # services.gatus.settings.webPort = 8020;
  # services.gatus.configFile = ./../../modules/gatus/config.yml;
  # age.secrets.gatus-credentials = {
  #     file = ../../secrets/gatus-credentials.age;
  #     mode = "0400";
  #     owner = "acme";
  #     group = "acme";
  # };
  # services.gatus.environmentFile = config.age.secrets.gatus-credentials.path;
}
