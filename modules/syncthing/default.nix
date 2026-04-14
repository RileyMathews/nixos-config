{ ... }:
{
  imports = [
    ../caddy-multi-proxy
    ../dns
  ];

  services.cloudflare-dns.enable = true;
  services.cloudflare-dns.domains = [ "syncthing.rileymathews.com" ];

  myCaddy.proxies.syncthing = {
    listenHost = "syncthing.rileymathews.com";
    backendHost = "http://127.0.0.1:8384";
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    settings = {
      gui = {
        address = "127.0.0.1:8384";
        insecureSkipHostcheck = true;
      };
    };

    devices = {
      "ds9" = { id = "JSFGUXS-BY7JCZN-LA6XNR3-EKJOTTR-GMJITVW-S6BNX7V-2WJ7RQA-KVAJHA7"; addresses = ["tcp://ds9.tailf1cbe3.ts.net:22000"]; };
      "pixel9a" = { id = "EZKOKUC-EQDRSUG-DVB7BFZ-VBQOCV2-WOATBFK-5REERDU-7J4ZQLI-CKEZAQT"; addresses = ["tcp://pixel-9a.tailf1cbe3.ts.net:22000"]; };
    };

    folders = {
      "obsidian" = {
        path = "/main/obsidian";
        devices = ["ds9" "pixel9a"];
      };
    };
  };
}
