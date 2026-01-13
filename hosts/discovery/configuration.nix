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
    ./../../modules/mealie
    ./../../modules/docker-registry
    ./../../modules/audiobookshelf
    ./../../modules/searxng
    ./../../modules/karakeep
    ./../../modules/immich
    ./../../modules/paperless
    ./../../modules/homebox
    ./../../modules/miniflux
  ];
  networking.hostName = "discovery";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  systemd.timers."podman-auto-update".wantedBy = ["multi-user.target"];
  # open up PG port as its needed for backup
  networking.firewall.allowedTCPPorts = [80 443 5432];
}
