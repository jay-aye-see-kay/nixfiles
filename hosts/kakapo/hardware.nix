# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [
    # modules supplied by generate-config
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
    # my network driver so I can ssh in to unlock hard disk
    "r8169"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/boot" = { device = "/dev/disk/by-uuid/76E0-E849"; fsType = "vfat"; };
  fileSystems."/" = { device = "rpool/system/root"; fsType = "zfs"; };

  fileSystems."/nix" = { device = "rpool/system/nix-store"; fsType = "zfs"; };

  fileSystems."/media" = { device = "apool/media/root"; fsType = "zfs"; };

  # new home server data dir, TODO migrate everything except media here
  fileSystems."/hs" = { device = "apool/hs"; fsType = "zfs"; };

  fileSystems."/home" = { device = "rpool/user/home"; fsType = "zfs"; };

  swapDevices = [{
    device = "/dev/disk/by-id/nvme-WD_Red_SN700_250GB_214912800092-part2";
    randomEncryption = true;
  }];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
