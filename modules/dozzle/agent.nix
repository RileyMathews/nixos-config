{ config, lib, pkgs, ... }:

let
  engineIdHash = builtins.hashString "sha256" config.networking.hostName;
  podmanEngineId = lib.concatStringsSep "-" [
    (builtins.substring 0 8 engineIdHash)
    (builtins.substring 8 4 engineIdHash)
    (builtins.substring 12 4 engineIdHash)
    (builtins.substring 16 4 engineIdHash)
    (builtins.substring 20 12 engineIdHash)
  ];
in
{
  imports = [ ../container-images ];

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  networking.firewall.allowedTCPPorts = [ 7007 ];

  systemd.services.dozzle-podman-engine-id = {
    description = "Ensure stable Podman engine ID for Dozzle";
    before = [ "podman-dozzle-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ensure-dozzle-podman-engine-id" ''
        set -eu
        ${pkgs.coreutils}/bin/install -d -m 0755 /var/lib/docker
        if [ ! -s /var/lib/docker/engine-id ]; then
          ${pkgs.coreutils}/bin/printf '%s\n' '${podmanEngineId}' > /var/lib/docker/engine-id
        fi
        ${pkgs.coreutils}/bin/chmod 0644 /var/lib/docker/engine-id
      '';
    };
  };

  virtualisation.oci-containers.containers.dozzle-agent = {
    image = config.myContainerImages.dozzle;
    cmd = [ "agent" ];
    ports = [ "7007:7007" ];
    volumes = [ "/run/podman/podman.sock:/var/run/docker.sock:ro" ];
    environment = {
      DOZZLE_HOSTNAME = config.networking.hostName;
      DOZZLE_NO_ANALYTICS = "true";
    };
    extraOptions = [
      "--security-opt=label=disable"
    ];
  };

  systemd.services."podman-dozzle-agent" = {
    after = [ "podman.socket" "dozzle-podman-engine-id.service" ];
    requires = [ "podman.socket" "dozzle-podman-engine-id.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
