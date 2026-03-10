{ config, lib, ... }:
{
  xdg.configFile."openpeon/config.json".source = ./openpeon/config.json;

  home.activation.openpeonDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.local/share/openpeon/packs"
  '';
}
