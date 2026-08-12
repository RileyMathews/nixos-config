{ config, pkgs, ... }:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
  ];

  networking.hostName = "hermes";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.riley.extraGroups = [ "hermes" ];

  age.secrets = {
    tailscale-credentials.file = ./../../../secrets/hermes-tailscale-credentials.age;
    cloudflare-api-key = {
      file = ./../../../secrets/hermes-cloudflare-api-key.age;
      owner = "tailscale-ddns";
      group = "tailscale-ddns";
      mode = "0400";
    };
    cloudflare-credentials = {
      file = ./../../../secrets/hermes-cloudflare-credentials.age;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };
    hermes-dashboard-env = {
      file = ./../../../secrets/hermes-dashboard-env.age;
      owner = "hermes";
      group = "hermes";
      mode = "0400";
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscale-credentials.path;
  };

  users.users.tailscale-ddns = {
    isSystemUser = true;
    group = "tailscale-ddns";
  };
  users.groups.tailscale-ddns = { };

  systemd.services.cloudflare-dns = let
    python = pkgs.python3.withPackages (ps: [ ps.requests ]);
  in {
    description = "Update hermes.rileymathews.com with the Tailscale IP";
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscaled-autoconnect.service" ];
    requires = [ "tailscaled-autoconnect.service" ];
    path = [ pkgs.tailscale python pkgs.coreutils ];
    environment = {
      ZONE_ID = "652d9eb1838a3157fa1196c9aae4efba";
      API_TOKEN_FILE = config.age.secrets.cloudflare-api-key.path;
      DOMAINS = builtins.toJSON [ "hermes.rileymathews.com" ];
    };
    serviceConfig = {
      Type = "oneshot";
      User = "tailscale-ddns";
      Group = "tailscale-ddns";
      ExecStart = "${python}/bin/python3 ${./../../../modules/dns/cloudflare_dns.py}";
    };
  };

  systemd.services."acme-order-renew-hermes.rileymathews.com" = {
    after = [ "cloudflare-dns.service" ];
    requires = [ "cloudflare-dns.service" ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "dev@rileymathews.com";
    certs."hermes.rileymathews.com" = {
      dnsProvider = "cloudflare";
      group = "caddy";
      environmentFile = config.age.secrets.cloudflare-credentials.path;
      extraLegoFlags = [ "--dns.propagation-wait" "180s" ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."hermes.rileymathews.com" = {
      useACMEHost = "hermes.rileymathews.com";
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9119
      '';
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 443 ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model = {
      provider = "openai-codex";
      default = "gpt-5.4";
    };
  };

  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Web Dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "hermes-agent.service" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.nodejs ];
    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      WorkingDirectory = "/var/lib/hermes/workspace";
      EnvironmentFile = config.age.secrets.hermes-dashboard-env.path;
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open --skip-build";
      Restart = "always";
      RestartSec = 5;
    };
    environment = {
      HOME = "/var/lib/hermes";
      HERMES_HOME = "/var/lib/hermes/.hermes";
    };
  };
}
