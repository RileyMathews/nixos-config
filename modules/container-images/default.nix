{ lib, ... }:

{
  options.myContainerImages = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      audiobookshelf = "ghcr.io/advplyr/audiobookshelf:2.34.0";
      bookshelf = "ghcr.io/rileymathews/papyrd-server:alpha-6";
      buffer = "registry.rileymathews.com/rileymathews/buffer:0.0.27-alpha";
      copyparty = "copyparty/ac:1.20.6";
      davhome = "registry.rileymathews.com/rileymathews/davhome:0.0.18-alpha";
      docker-registry = "registry:3.0.0";
      dozzle = "docker.io/amir20/dozzle:v10.5.1";
      freshrss = "freshrss/freshrss:1.29.0";
      homeassistant = "linuxserver/homeassistant:version-2026.5.1";
      homebox = "ghcr.io/sysadminsmedia/homebox:0.25.0";
      homebridge = "docker.io/homebridge/homebridge:latest";
      immich-machine-learning = "ghcr.io/immich-app/immich-machine-learning:v2.7.5-cuda";
      immich-postgres = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      immich-server = "ghcr.io/immich-app/immich-server:v2.7.5";
      jellyfin = "lscr.io/linuxserver/jellyfin:latest";
      joplin = "docker.io/joplin/server:latest";
      karakeep = "ghcr.io/karakeep-app/karakeep:0.32.0";
      karakeep-chrome = "gcr.io/zenika-hub/alpine-chrome:124";
      karakeep-meilisearch = "getmeili/meilisearch:v1.13.3";
      komga = "gotson/komga";
      mealie = "ghcr.io/mealie-recipes/mealie:v3.17.0";
      miniflux = "miniflux/miniflux:2.2.17";
      ntfy = "binwiederhier/ntfy:v2.22.0";
      ollama = "ollama/ollama:0.23.2";
      open-webui = "ghcr.io/open-webui/open-webui:0.9.5";
      paperless = "ghcr.io/paperless-ngx/paperless-ngx:2.20.15";
      pinchflat = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
      piper = "lscr.io/linuxserver/piper:latest";
      podman-exporter = "quay.io/navidys/prometheus-podman-exporter:latest";
      radicale = "registry.rileymathews.com/rileymathews/radicale:test2";
      reverse-health-check = "registry.rileymathews.com/rileymathews/reverse-health-check:0.0.1-alpha";
      scraper = "registry.rileymathews.com/rileymathews/scraper:0.0.2";
      searxng = "docker.io/searxng/searxng:latest";
      vaultwarden = "vaultwarden/server:1.36.0";
      vikunja = "vikunja/vikunja:2.3.0";
      webhooks = "registry.rileymathews.com/rileymathews/webhook-processor:0.2.0";
      whisper = "lscr.io/linuxserver/faster-whisper:gpu";
    };
    description = "Shared OCI container image references used by application modules.";
  };
}
