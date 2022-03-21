{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ./main.yaml;
  sops.secrets = {
    autheliaJwtSecret = { };
    autheliaSessionSecret = { };
    autheliaStorageEncryptionKey = { };
    borgPassword = { };
    mullvadPrivateKey = { };
    serviceMailAccountPassword = { };
  };
}
