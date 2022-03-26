# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [
    # modules supplied by generate-config
    "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"
    # my network driver so I can ssh in to unlock hard disk
    "r8169"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "rpool/system/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "rpool/system/nix-store";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "rpool/user/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3F44-CE05";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/dev/disk/by-id/wwn-0x5001b448ba0c2403-part2";
      randomEncryption = true;
    }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
