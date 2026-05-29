{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dockerRegistryPrune;
  pruneTags = pkgs.writeText "docker-registry-prune-tags.py" (builtins.readFile ./prune-tags.py);

  pruneRegistry = pkgs.writeShellScript "docker-registry-prune" ''
    set -euo pipefail

    ${pkgs.python3}/bin/python3 ${pruneTags}

    registry_was_active=0
    if ${pkgs.systemd}/bin/systemctl is-active --quiet podman-registry.service; then
      registry_was_active=1
    fi

    cleanup() {
      if [ "$registry_was_active" -eq 1 ]; then
        ${pkgs.systemd}/bin/systemctl start podman-registry.service
      fi
    }
    trap cleanup EXIT

    ${pkgs.systemd}/bin/systemctl stop podman-registry.service

    ${pkgs.podman}/bin/podman run --rm --network=none \
      -v "$REGISTRY_STORAGE_PATH:/var/lib/registry" \
      ${lib.escapeShellArg config.myContainerImages.docker-registry} \
      registry garbage-collect --delete-untagged /etc/distribution/config.yml
  '';
in
{
  imports = [../caddy-multi-proxy ../dns ../container-images];

  options.services.dockerRegistryPrune = {
    enable = lib.mkEnableOption "periodic Docker registry tag pruning and garbage collection";

    registryUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:5000";
      description = "Local registry URL used for manifest deletion.";
    };

    storagePath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/appdata/docker-registry";
      description = "Host path mounted as /var/lib/registry in the registry container.";
    };

    keepNewestShaTags = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 2;
      description = "Number of newest SHA-like tags to retain per repository.";
    };

    prunableTagPattern = lib.mkOption {
      type = lib.types.str;
      default = "^[0-9a-f]{40}$";
      description = "Regular expression for tags eligible for pruning.";
    };

    protectedTagPattern = lib.mkOption {
      type = lib.types.str;
      default = "^latest($|[-_.])";
      description = "Regular expression for tags that must never be pruned.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd calendar expression for registry pruning.";
    };
  };

  config = {
    services.cloudflare-dns.enable = true;
    services.cloudflare-dns.domains = ["registry.rileymathews.com"];
    services.dockerRegistryPrune.enable = lib.mkDefault true;

    myCaddy.proxies.registry = {
      listenHost = "registry.rileymathews.com";
      backendHost = "http://127.0.0.1:5000";
    };

    virtualisation.oci-containers.containers = {
      registry = {
        image = config.myContainerImages.docker-registry;
        environment = {
          REGISTRY_STORAGE_DELETE_ENABLED = "true";
        };
        ports = ["5000:5000"];
        volumes = [ "${cfg.storagePath}:/var/lib/registry" ];
      };
    };

    systemd.services.docker-registry-prune = lib.mkIf cfg.enable {
      description = "Prune old Docker registry tags and garbage collect blobs";
      wants = ["podman-registry.service"];
      after = ["podman-registry.service"];
      environment = {
        REGISTRY_URL = cfg.registryUrl;
        REGISTRY_STORAGE_PATH = cfg.storagePath;
        KEEP_NEWEST_TAGS = toString cfg.keepNewestShaTags;
        PRUNABLE_TAG_PATTERN = cfg.prunableTagPattern;
        PROTECTED_TAG_PATTERN = cfg.protectedTagPattern;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pruneRegistry;
        TimeoutStartSec = "30m";
      };
    };

    systemd.timers.docker-registry-prune = lib.mkIf cfg.enable {
      description = "Run Docker registry pruning";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
