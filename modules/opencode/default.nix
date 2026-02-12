{ config, lib, pkgs, unstablePkgs, ... }:
{
  imports = [
    ../nginx-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "opencode.rileymathews.com" ];

  myNginx.proxies.opencode = {
    listenHost = "opencode.rileymathews.com";
    backendHost = "http://127.0.0.1:8081";
  };

  environment.systemPackages = [
    pkgs.git
    unstablePkgs.opencode
  ];

  systemd.services.opencode = {
    description = "OpenCode web server";
    after = [ "network.target" "tailscale-ready.service" ];
    wants = [ "tailscale-ready.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "riley";
      Group = "riley";
      WorkingDirectory = "/home/riley";
      StateDirectory = "opencode";
      ExecStart = "${unstablePkgs.opencode}/bin/opencode web --hostname 127.0.0.1 --port 8081";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
