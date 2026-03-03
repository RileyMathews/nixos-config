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
    ./../../../modules/restic-backup
  ];
  networking.hostName = "thegenerosityco-staging";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.logDriver = "json-file";
  services.resticBackup = {
    enable = true;
    backups.thegenerosityco-database = {
      type = "sqlite-live-copy";
      gatusHealthcheckId = "backups_thegenerosityco-staging-backup";
      databases = [
        "/var/lib/thegenerosityco/database/db.sqlite3"
      ];
    };
  };
}
