{ pkgs, ... }:
let
  dataDir = "/web-service-data/mealie";
  hostName = "mealie.h.jackrose.co.nz";
  localPort = "1501";
in
{
  services.nginx.virtualHosts."${hostName}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${localPort}";
      proxyWebsockets = true;
      extraConfig = "proxy_pass_header Authorization;";
    };
  };

  users.groups.mealie = { };
  users.users.mealie = {
    isSystemUser = true;
    group = "mealie";
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} - mealie mealie -"
  ];

  virtualisation.oci-containers.containers.mealie = {
    autoStart = true;
    /* user = "mealie:mealie"; */
    image = "hkotel/mealie:v0.5.5";
    environment = {
      TZ = "Australia/Melbourne";
      RECIPE_PUBLIC = "true";
      RECIPE_SHOW_NUTRITION = "true";
      RECIPE_SHOW_ASSETS = "true";
      RECIPE_LANDSCAPE_VIEW = "true";
      RECIPE_DISABLE_COMMENTS = "false";
      RECIPE_DISABLE_AMOUNT = "false";
    };
    ports = [
      "${localPort}:80"
    ];
    volumes = [
      "${dataDir}:/app/data"
    ];
  };
}
