{ config, lib, ... }:
{
    systemd.services."podman-podman-exporter" = {
        after = [ "podman.socket" ];
        requires = [ "podman.socket" ];
    };

    virtualisation.oci-containers.containers.podman-exporter = {
        image = "quay.io/navidys/prometheus-podman-exporter:latest";
        user = "root";
        environment = {
            CONTAINER_HOST = "unix:///run/podman/podman.sock";
        };
        volumes = [
            "/run/podman/podman.sock:/run/podman/podman.sock"
        ];
        ports = [
            "9882:9882"
        ];
        extraOptions = [
            "--security-opt=label=disable"
        ];
    };
}
