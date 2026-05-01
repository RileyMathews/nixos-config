{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
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
}
