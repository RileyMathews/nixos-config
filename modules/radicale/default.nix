{ config, ... }:
{
  imports = [
    ../nginx-multi-proxy
    ../dns
    ../restic-backup
    ../container-images
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "calendar.rileymathews.com" ];

  myNginx.proxies.radicale = {
    listenHost = "calendar.rileymathews.com";
    backendHost = "http://127.0.0.1:5232";
  };

  environment.etc."radicale/config".text = ''
    [server]
    hosts = 0.0.0.0:5232

    [auth]
    type = htpasswd
    htpasswd_filename = /etc/radicale/users
    htpasswd_encryption = autodetect

    [storage]
    filesystem_folder = /var/lib/radicale/collections

    [hook]
    type = rabbitmq
    rabbitmq_endpoint = amqp://radicale:radicale-rabbitmq@rabbitmq:5672/
    rabbitmq_topic = radicale
    rabbitmq_queue_type = classic

    [sharing]
    type = files
    collection_by_token = true
    collection_by_map = true
    permit_create_token = true
    permit_create_map = true
    permit_properties_overlay = true
  '';

  age.secrets.radicale-users = {
    file = ../../secrets/radicale-users.age;
    owner = "riley";
    group = "riley";
    mode = "0440";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/appdata/radicale 0750 riley riley -"
    "d /var/lib/appdata/radicale/data 0750 riley riley -"
  ];

  services.resticBackup = {
    enable = true;
    backups.radicale-data = {
      type = "path-list";
      gatusHealthcheckId = "backups_radicale-backup";
      paths = [
        "/var/lib/appdata/radicale/data"
      ];
    };
  };

  virtualisation.oci-containers.containers.radicale = {
    image = config.myContainerImages.radicale;
    ports = [ "5232:5232" ];
    volumes = [
      "/etc/radicale/config:/etc/radicale/config:ro"
      "${config.age.secrets.radicale-users.path}:/etc/radicale/users:ro"
      "/var/lib/appdata/radicale/data:/var/lib/radicale"
    ];
  };
}
