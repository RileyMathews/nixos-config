{
  config,
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/nginx-single-proxy
    ./../../modules/tailscale
    ./../../modules/dns
  ];
  networking.hostName = "git";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  services.rpcbind.enable = true;
  boot.kernelModules = [ "nfs" ];
  boot.supportedFilesystems = [ "nfs" ];
  # fileSystems."/mnt/forgejo" = {
  #   device = "nas:/main/forgejo";
  #   fsType = "nfs";
  #   options = ["defaults"];
  # };
  myNginx = {
    enable = true;
    hostName = "git.rileymathews.com";
    reverseProxyAddress = "http://127.0.0.1:3000";
  };
  services.cloudflare-dns = {
    enable = true;
    domains = [
      "git.rileymathews.com"
    ];
  };

  systemd.mounts = [{
    what = "nas:/main/forgejo";
    where = "/mnt/forgejo";
    type = "nfs";
    options = "defaults";
    
    # Make it wait for Tailscale
    # TODO: does this block shutdown because tailscale service never stops?
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscale-ready.service" ];
    requires = [ "tailscale-ready.service" ];
  }];

  users.users = {
    git = {
      home = "/mnt/forgejo";
      useDefaultShell = true;
      group = "git";
      isSystemUser = true;
    };
  };
  users.groups.git = { };

  age.secrets.forgejo-database-password = {
    file = ../../secrets/forgejo-database-password.age;
    owner = "git";
    group = "git";
    mode = "0400";
  };
  systemd.services.forgejo = {
    unitConfig = {
      Requires = [ "mnt-forgejo.mount" ]; # Replace with your actual mount unit name
      After = [ "mnt-forgejo.mount" ];   # Replace with your actual mount unit name
    };
  };

  services.forgejo = {
    enable = true;
    user = "git";
    group = "git";
    stateDir = "/mnt/forgejo";
    package = unstablePkgs.forgejo;
    settings = {
      server = {
        ROOT_URL = "https://git.rileymathews.com";
        DOMAIN = "git.rileymathews.com";
      };
    };
    database = {
      user = "forgejo";
      type = "postgres";
      host = "pg17.tailscale.rileymathews.com";
      passwordFile = config.age.secrets.forgejo-database-password.path;
      createDatabase = false;
    };
  };
}

