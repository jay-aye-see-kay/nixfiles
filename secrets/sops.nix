{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ./main.yaml;
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";
  sops.secrets = {
    borgPassword = { };
  };
}
