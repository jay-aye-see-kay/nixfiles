{ config, pkgs, ... }:
{
  sops.defaultSopsFile = ./main.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.secrets = {
    borgPassword = { };
  };
}
