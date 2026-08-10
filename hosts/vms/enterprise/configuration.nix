{
  modulesPath,
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.vikunja-project-reset.nixosModules.default
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    ./../../../modules/searxng
    ./../../../modules/paperless
    ./../../../modules/homebox
    ./../../../modules/vikunja
    ./../../../modules/webhooks
    ./../../../modules/podman-exporter
    ./../../../modules/dozzle/agent.nix
    ./../../../modules/mealie
    ./../../../modules/radicale
  ];
  networking.hostName = "enterprise";
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  networking.firewall.allowedTCPPorts = [80 443];

  age.secrets.vikunja-project-reset = {
    file = ./../../../secrets/vikunja-project-reset.age;
  };

  services.vikunja-project-reset = {
    enable = true;
    tokenFile = config.age.secrets.vikunja-project-reset.path;
  };

  systemd.services.vikunja-project-reset.restartTriggers = [
    config.age.secrets.vikunja-project-reset.file
  ];

  myCaddy.proxies.vikunja-project-reset = {
    listenHost = "taskreset.rileymathews.com";
    backendHost = "http://127.0.0.1:3000";
  };

  services.cloudflare-dns.domains = [ "taskreset.rileymathews.com" ];
}
