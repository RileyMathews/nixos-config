{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myTailscale;
in
{
  options.myTailscale = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the custom Caddy virtual host.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.tailscale-credentials.file = ../../secrets/tailscale-credentials.age;
    services.tailscale.enable = true;
    services.tailscale.authKeyFile = config.age.secrets.tailscale-credentials.path;
    systemd.services.tailscaled = {
      unitConfig.RequiresMountsFor = [ config.age.secrets.tailscale-credentials.path ];
      requires = [ "run-agenix.d.mount" ];
      after = [ "network.target" "run-agenix.d.mount" ];
    };
    systemd.services.tailscaled-autoconnect = {
      unitConfig.RequiresMountsFor = [ config.age.secrets.tailscale-credentials.path ];
      requires = [ "run-agenix.d.mount" ];
      after = [ "network.target" "run-agenix.d.mount" ];
    };
    systemd.services.tailscale-ready = {
      description = "Wait for Tailscale to be fully connected";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "300"; # 5 minute timeout
        ExecStart = pkgs.writeShellScript "wait-tailscale-ready" ''
          set -e
          
          echo "Waiting for Tailscale to be fully connected..."
          
          # Wait for tailscale to be responsive
          while ! ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; do
            echo "Tailscale daemon not ready yet, waiting..."
            sleep 2
          done
          
          # Wait for actual connectivity (not just "Starting" state)
          while true; do
            status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null || echo '{}')
            backend_state=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"')
            
            echo "Current Tailscale state: $backend_state"
            
            case "$backend_state" in
              "Running")
                echo "Tailscale is running and connected!"
                break
                ;;
              "NeedsLogin")
                echo "ERROR: Tailscale needs authentication. Please run 'tailscale up'"
                exit 1
                ;;
              "Stopped")
                echo "ERROR: Tailscale is stopped"
                exit 1
                ;;
              *)
                echo "Waiting for connection... (current state: $backend_state)"
                sleep 3
                ;;
            esac
          done
          
          echo "Tailscale is fully ready!"
        '';
      };
    };
  };
}

