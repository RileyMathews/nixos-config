{ pkgs, ... }:
{
  services.postgresql = {
    package = pkgs.postgresql_13;
    enable = true;
    enableJIT = false;
    enableTCPIP = false;
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    settings = {
      timezone = "UTC";
      log_timezone = "UTC";
      shared_buffers = "128MB";
      max_locks_per_transaction = 1024;
      max_connections = 5000;
      fsync = false;
      synchronous_commit = false;
      full_page_writes = false;
      shared_preload_libraries = "pg_stat_statements";
    };
    extraPlugins = [
      pkgs.postgresql_13.pkgs.postgis
    ];
  };
}
