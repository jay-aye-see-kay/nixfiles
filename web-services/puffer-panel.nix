{ pkgs, config, ... }:
let
  dataDir = "/web-service-data/mealie";
  hostName = "puffer-panel.h.jackrose.co.nz";
  localPort = "1502";
in
{
  services.nginx.virtualHosts."${hostName}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${localPort}";
    };
  };

  virtualisation.oci-containers.containers.puffer-panel = {
    autoStart = true;
    image = "pufferpanel/pufferpanel";
    ports = [
      "${localPort}:8080"
    ];
    volumes = [
      "/data/puffer-panel/config:/etc/pufferpanel"
      "/data/puffer-panel/data:/var/lib/pufferpanel"
    ];
  };
}
