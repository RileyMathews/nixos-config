{
  config,
  modulesPath,
  inputs,
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
    ./../../../modules/caddy-multi-proxy
    ./../../../modules/dns
    inputs.familiar.nixosModules.default
  ];
  networking.hostName = "familiar";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  networking.firewall.allowedTCPPorts = [80 443];

  services.cloudflare-dns = {
    enable = true;
    domains = ["familiar.rileymathews.com"];
  };

  myCaddy.proxies.familiar = {
    listenHost = "familiar.rileymathews.com";
    backendHost = "http://127.0.0.1:3000";
  };

  age.secrets.familiar-env-file = {
    file = ../../../secrets/familiar-env-file.age;
    owner = "familiar";
    group = "familiar";
  };

  services.familiar = {
    enable = true;
    environmentFile = config.age.secrets.familiar-env-file.path;
  };
  programs.zsh.enable = true;
  users.users.familiar.shell = pkgs.zsh;

  systemd.services.familiar-gmail-task = {
    description = "Run Familiar Gmail background task";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    environment = {
      HOME = "/var/lib/familiar";
      RUST_LOG = "info";
      XDG_CONFIG_HOME = "/var/lib/familiar/.config";
      XDG_DATA_HOME = "/var/lib/familiar/.local/share";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "familiar";
      Group = "familiar";
      WorkingDirectory = "/var/lib/familiar";
      EnvironmentFile = config.age.secrets.familiar-env-file.path;
      ExecStart = "${config.services.familiar.package}/bin/familiar-run --task gmail_categorization";
    };
  };

  systemd.timers.familiar-gmail-task = {
    description = "Run Familiar Gmail background task daily";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 12:00:00";
      Persistent = true;
    };
  };
}
