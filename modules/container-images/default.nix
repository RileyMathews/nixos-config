{ lib, ... }:

{
  options.myContainerImages = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      audiobookshelf = "ghcr.io/advplyr/audiobookshelf:2.35.1";
      bookshelf = "ghcr.io/rileymathews/papyrd-server:alpha-11";
      buffer = "registry.rileymathews.com/rileymathews/buffer:0.0.27-alpha";
      copyparty = "copyparty/ac:1.20.18";
      docker-registry = "registry:3.1.1";
      dozzle = "docker.io/amir20/dozzle:v10.6.11";
      freshrss = "freshrss/freshrss:1.29.1";
      homeassistant = "linuxserver/homeassistant:version-2026.7.2";
      homebox = "ghcr.io/sysadminsmedia/homebox:0.26.2";
      homebridge = "docker.io/homebridge/homebridge:2026-07-20";
      immich-machine-learning = "ghcr.io/immich-app/immich-machine-learning:v3.0.3-cuda";
      immich-postgres = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      immich-server = "ghcr.io/immich-app/immich-server:v3.0.3";
      jellyfin = "lscr.io/linuxserver/jellyfin:10.11.11";
      joplin = "docker.io/joplin/server:3.7.1";
      karakeep = "ghcr.io/karakeep-app/karakeep:0.32.0";
      karakeep-chrome = "gcr.io/zenika-hub/alpine-chrome:124";
      karakeep-meilisearch = "getmeili/meilisearch:v1.48.3";
      litellm = "docker.litellm.ai/berriai/litellm:v1.93.0@sha256:a1745e629abfb17d434426ff48b115f54f4f4c4a0f5af241de569e93c63c411e";
      mealie = "ghcr.io/mealie-recipes/mealie:v3.20.1";
      miniflux = "miniflux/miniflux:2.3.2";
      ntfy = "binwiederhier/ntfy:v2.26.3";
      ollama = "ollama/ollama:0.32.1";
      open-webui = "ghcr.io/open-webui/open-webui:0.10.2";
      paperless = "ghcr.io/paperless-ngx/paperless-ngx:2.20.15";
      pinchflat = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
      piper = "lscr.io/linuxserver/piper:2.3.1";
      podman-exporter = "quay.io/navidys/prometheus-podman-exporter:v1.21.2";
      radicale = "registry.rileymathews.com/rileymathews/radicale:test2";
      reverse-health-check = "registry.rileymathews.com/rileymathews/reverse-health-check:0.0.1-alpha";
      searxng = "docker.io/searxng/searxng:2026.7.19-6da6eee26";
      vaultwarden = "vaultwarden/server:1.36.0";
      vikunja = "vikunja/vikunja:2.4.0";
      webhooks = "registry.rileymathews.com/rileymathews/webhook-processor:0.2.0";
      whisper = "lscr.io/linuxserver/faster-whisper:3.5.0-gpu";
    };
    description = "Shared OCI container image references used by application modules.";
  };
}
