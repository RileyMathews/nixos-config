{
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    ./../../../modules/restic-local-appdata
  ];
  networking.hostName = "thegenerosityco-staging";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.logDriver = "json-file";
  services.resticLocalAppdata = {
      enable = true;
      paths = [
          "/var/lib/thegenerosityco/database"
      ];
      gatusHealthcheckId = "backups_thegenerosityco-staging-backup";
  };
}
