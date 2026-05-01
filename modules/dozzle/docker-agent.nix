{ config, ... }:

{
  virtualisation.oci-containers.backend = "docker";

  networking.firewall.allowedTCPPorts = [ 7007 ];

  virtualisation.oci-containers.containers.dozzle-agent = {
    image = "docker.io/amir20/dozzle:v10.5.1";
    cmd = [ "agent" ];
    ports = [ "7007:7007" ];
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
    environment = {
      DOZZLE_HOSTNAME = config.networking.hostName;
      DOZZLE_NO_ANALYTICS = "true";
    };
  };

  systemd.services."docker-dozzle-agent" = {
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
