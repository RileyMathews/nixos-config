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
  };
}

