{
  config,
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
    ./../../../modules/vms/swap-config.nix
    ./../../../modules/tailscale
    ./../../../modules/docker-registry
    ./../../../modules/freshrss
    ./../../../modules/karakeep
    ./../../../modules/joplin
    ./../../../modules/buffer
    ./../../../modules/bookshelf
    ./../../../modules/podman-exporter
    ./../../../modules/tedlib
    ./../../../modules/agent
    ./../../../modules/dozzle/agent.nix
  ];
  networking.hostName = "defiant";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  users.users.riley.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAoPiVN/y4XLQA8DlOF7gXxcEewMra/YLsUK4o0omAdj forgejo-runner@lab"
  ];
  networking.firewall.allowedTCPPorts = [80 443];
  virtualisation.podman.enable = true;
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
}
