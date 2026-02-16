{ pkgs, ... }:
let
  confFile = pkgs.writeText "configuration.yaml" (builtins.readFile ./copyparty.conf);
in
{
  imports = [
    ../nas-oci
    ../nginx-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "copyparty.rileymathews.com" ];

  myNginx.proxies.copyparty = {
    listenHost = "copyparty.rileymathews.com";
    backendHost = "http://127.0.0.1:3923";
  };

  services.nasOci = {
    enable = true;

    mounts.copyparty = {
      mountPoint = "/mnt/copyparty";
      device = "10.0.0.110:/copyparty";
    };

    containers.copyparty = {
      definition = {
        image = "copyparty/ac:1.20.6";
        ports = [ "127.0.0.1:3923:3923" ];
        volumes = [
          "/mnt/copyparty/data:/w"
          "/mnt/copyparty/hists:/cfg/hists"
          "${confFile}:/cfg/copyparty.conf:ro"
        ];
        user = "1000:1000";
        environment = {
          PYTHONUNBUFFERED = "1";
        };
        cmd = [
          "--http-only"
          "--no-crt"
          "--xff-src=lan"
          "--rproxy=1"
          "--site=https://copyparty.rileymathews.com/"
        ];
        extraOptions = [
          "--health-cmd=wget --spider -q http://127.0.0.1:3923/?reset=/._ || exit 1"
          "--health-interval=60s"
          "--health-timeout=5s"
          "--health-retries=5"
          "--health-start-period=15s"
        ];
      };
    };
  };
}
