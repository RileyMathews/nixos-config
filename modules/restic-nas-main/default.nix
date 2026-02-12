{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.resticNasMain;
  backupScript = pkgs.writeShellScript "restic-nas-main-backup.sh" (builtins.readFile ./backup.sh);
in
{
  options.services.resticNasMain = {
    enable = mkEnableOption "restic backup for NAS /main datasets";

    onCalendar = mkOption {
      type = types.str;
      default = "daily";
      description = "systemd OnCalendar schedule for NAS backups.";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];

    fileSystems."/mnt/nas-main" = {
      device = "nas:/";
      fsType = "nfs";
      options = [
        "vers=4.2"
        "proto=tcp"
        "_netdev"
        "nofail"
        "soft"
        "timeo=600"
        "retrans=2"
        "x-systemd.requires=tailscale-ready.service"
        "x-systemd.after=tailscale-ready.service"
      ];
    };

    age.secrets.aws-access-key = {
      file = ../../secrets/aws-access-key.age;
      mode = "0400";
      owner = "backup";
      group = "backup";
    };

    age.secrets.restic-password = {
      file = ../../secrets/restic-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    systemd.services.restic-nas-main-backup = {
      description = "Backup NAS /main directories to restic";
      path = with pkgs; [ restic curl util-linux ];
      environment = {
        AWS_SECRET_ACCESS_KEY_FILE = config.age.secrets.aws-access-key.path;
        RESTIC_PASSWORD_FILE = config.age.secrets.restic-password.path;
        RESTIC_CACHE_DIR = "/var/cache/restic-nas-main";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = backupScript;
        CacheDirectory = "restic-nas-main";
      };
      unitConfig = {
        RequiresMountsFor = [ "/mnt/nas-main" ];
        Wants = [ "tailscale-ready.service" ];
        After = [ "tailscale-ready.service" ];
      };
    };

    systemd.timers.restic-nas-main-backup = {
      description = "Run NAS /main restic backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "30m";
        Unit = "restic-nas-main-backup.service";
      };
    };
  };
}
