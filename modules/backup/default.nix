# backup.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.backup;
  backupScriptPath = pkgs.writeScript "backup-script.sh" cfg.backupScript;
in
{
  #### Define Options ####
  options.services.backup = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the backup service and timer.";
    };

    backupScript = mkOption {
      type = types.lines;
      default = builtins.readFile(./backup.sh);
      description = "The backup script content.";
    };
  };

  #### Configure the Service and Timer ####
  config = mkIf cfg.enable ({
    # Write the backup script to the Nix store

    # Define the systemd service
    systemd.services.backup = {
      description = "Backup Service";
      path = with pkgs; [bash];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${backupScriptPath}";
      };
    };

    # Define the systemd timer
    # systemd.timers.backup = {
    #   description = "Backup Timer";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Persistent = true;
    #   };
    #   unitConfig.Unit = "backup.service";
    # };
  });
}

