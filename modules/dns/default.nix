{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cloudflare-dns;
  
  # Define Python environment with required packages
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    requests
  ]);
  
  # Reference the external Python script
  updateScript = ./cloudflare_dns.py;
in
{
  options.services.cloudflare-dns = {
    enable = mkEnableOption "Tailscale Cloudflare DDNS service";

    domains = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of domain names to update";
      example = [ "server.example.com" "api.example.com" ];
    };

    zoneId = mkOption {
      type = types.str;
      description = "Cloudflare Zone ID";
      default = "652d9eb1838a3157fa1196c9aae4efba";
    };

    tailscaleInterface = mkOption {
      type = types.str;
      default = "tailscale0";
      description = "Tailscale network interface name";
    };
  };

  config = mkIf cfg.enable {
    # Ensure Tailscale is enabled
    services.tailscale.enable = mkDefault true;

    # Configure age secret for Cloudflare credentials
    age.secrets.cloudflare-api-key = {
      file = ../../secrets/cloudflare-api-key.age;
      owner = "tailscale-ddns";
      group = "tailscale-ddns";
      mode = "0400";
    };

    # Install required packages
    environment.systemPackages = with pkgs; [
      tailscale
      pythonEnv
    ];

    # Create the update service
    systemd.services.cloudflare-dns = {
      description = "Update Cloudflare DNS with Tailscale IP";
      path = with pkgs; [
        tailscale
        pythonEnv
        coreutils  # for basic commands like cat, echo, etc.
      ];
      
      environment = {
        ZONE_ID = cfg.zoneId;
        API_TOKEN_FILE = config.age.secrets.cloudflare-api-key.path;
        DOMAINS = builtins.toJSON cfg.domains;
        # PATH = lib.makeBinPath [ pkgs.tailscale pythonEnv ];
      };
      
      serviceConfig = {
        Type = "oneshot";
        User = "tailscale-ddns";
        Group = "tailscale-ddns";
        ExecStart = "${pythonEnv}/bin/python3 ${updateScript}";
        
        # Security settings
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        
        # Network access required
        PrivateNetwork = false;
      };

      # Ensure dependencies are available
      after = [ "tailscaled.service" "tailscale-ready.service" ];
      wants = [ "tailscaled.service" "tailscale-ready.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    # Create dedicated user for the service
    users.users.tailscale-ddns = {
      isSystemUser = true;
      group = "tailscale-ddns";
      description = "Tailscale DDNS service user";
    };

    users.groups.tailscale-ddns = {};
  };
}
