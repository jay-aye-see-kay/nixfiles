{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ./main.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.secrets = {
    autheliaJwtSecret = { };
    autheliaSessionSecret = { };
    autheliaStorageEncryptionKey = { };
    borgPassword = { };
    mullvadPrivateKey = { };
    nextcloudAdminPassword = { owner = "nextcloud"; };
    serviceMailAccountPassword = { };
  };
}
