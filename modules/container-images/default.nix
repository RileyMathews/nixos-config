{ lib, ... }:

{
  options.myContainerImages = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      audiobookshelf = "ghcr.io/advplyr/audiobookshelf:2.35.1";
      bookshelf = "ghcr.io/rileymathews/papyrd-server:alpha-10";
      buffer = "registry.rileymathews.com/rileymathews/buffer:0.0.27-alpha";
      copyparty = "copyparty/ac:1.20.16";
      davhome = "registry.rileymathews.com/rileymathews/davhome:0.0.18-alpha";
      docker-registry = "registry:3.1.1";
      dozzle = "docker.io/amir20/dozzle:v10.6.7";
      freshrss = "freshrss/freshrss:1.29.1";
      homeassistant = "linuxserver/homeassistant:version-2026.7.1";
      homebox = "ghcr.io/sysadminsmedia/homebox:0.26.2";
      homebridge = "docker.io/homebridge/homebridge:2026-06-24";
      immich-machine-learning = "ghcr.io/immich-app/immich-machine-learning:v3.0.1-cuda";
      immich-postgres = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      immich-server = "ghcr.io/immich-app/immich-server:v3.0.1";
      jellyfin = "lscr.io/linuxserver/jellyfin:10.11.11";
      joplin = "docker.io/joplin/server:3.7.1";
      karakeep = "ghcr.io/karakeep-app/karakeep:0.32.0";
      karakeep-chrome = "gcr.io/zenika-hub/alpine-chrome:124";
      karakeep-meilisearch = "getmeili/meilisearch:v1.48.3";
      komga = "gotson/komga:1.25.0";
      litellm = "docker.litellm.ai/berriai/litellm:v1.90.3@sha256:e4b91a2de9367ab0987baaa767b2283390badd5a361357993de1a05f027edc22";
      mealie = "ghcr.io/mealie-recipes/mealie:v3.20.1";
      miniflux = "miniflux/miniflux:2.3.2";
      ntfy = "binwiederhier/ntfy:v2.25.0";
      ollama = "ollama/ollama:0.31.1";
      open-webui = "ghcr.io/open-webui/open-webui:0.10.2";
      paperless = "ghcr.io/paperless-ngx/paperless-ngx:2.20.15";
      pinchflat = "ghcr.io/kieraneglin/pinchflat:v2025.6.6";
      piper = "lscr.io/linuxserver/piper:2.2.2";
      podman-exporter = "quay.io/navidys/prometheus-podman-exporter:v1.21.2";
      radicale = "registry.rileymathews.com/rileymathews/radicale:test2";
      reverse-health-check = "registry.rileymathews.com/rileymathews/reverse-health-check:0.0.1-alpha";
      scraper = "registry.rileymathews.com/rileymathews/scraper:0.0.2";
      searxng = "docker.io/searxng/searxng:2026.7.3-c5cd510d8";
      vaultwarden = "vaultwarden/server:1.36.0";
      vikunja = "vikunja/vikunja:2.3.0";
      webhooks = "registry.rileymathews.com/rileymathews/webhook-processor:0.2.0";
      whisper = "lscr.io/linuxserver/faster-whisper:3.3.1-gpu";
    };
    description = "Shared OCI container image references used by application modules.";
  };
}
