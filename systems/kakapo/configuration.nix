{ config, pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes; # or versioned attributes like nix_2_7
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS boot settings.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";
  boot.zfs.requestEncryptionCredentials = true;

  networking.hostName = "kakapo";
  networking.hostId = "e319c2ad"; # for zfs; 'hostname | md5sum | head -c 8'

  boot = {
    # see: https://nixos.wiki/wiki/ZFS#Unlock_encrypted_zfs_via_ssh_on_boot
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ /root/.ssh/boot_ed25519_key ];
        authorizedKeys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhM9hxQe+Mcu42h2PTZqbDK2l81VLNs+EfIyOOPoRRKIDVsF/7fgc/ZHXBXSlaQbC+b6xvsVxUl/ordDVBtaLYupG2XqZltAvRPe+2wzA/kTDmZZ6V/ZxAeUgJdrKr+X3h6dKAU8dBSgWmeZAo1CyBTCf0cX/wh0VPxE09zd35kIfvJBocJXFuwdH0qNYpOm3Ce44sV+8hmngCfXQt09qQhvdBS6UQMMsQ+1WBEGA07Wo5BXfyBwn9aYdxnEBWUlLZ3RxHoeqHq0h40GRpmNJGbP+k7kr2KXeN13prLiK6t/YnfwxJU7GnPZaro02SES3P56CDtsr9KN9Apm2W9nm9cHcMu4ZdA3DAHN0ym8EONZGgFhfYDM5YQDXyxdQ5QVlMuB0QEn7f6XxJx3GhWrgVjlYjJXg9HZtux6+epNNuf9CaJHZC5d3Xa6QwaH93tUM2xdMiDZQ32lm4ChpmtewPpebtoQJCyWMmdTDuSEJCX4/u0aLJTM6zWPo7rg6Je+U= jackderryrose@gmail.com" ];
      };
      postCommands = ''
        cat <<EOF > /root/.profile
        if pgrep -x "zfs" > /dev/null
        then
          zfs load-key -a
          killall zfs
        else
          echo "zfs not running -- maybe the pool is taking some time to load for some unforseen reason."
        fi
        EOF
      '';
    };
  };

  time.timeZone = "Australia/Melbourne";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = true;

  users.users.jack = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    fd
    ripgrep
    age
    sops
    docker-compose
    pwgen
    pciutils # provides lspci
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
