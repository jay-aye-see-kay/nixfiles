{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  fileSystems."/boot" = { device = "/dev/disk/by-uuid/E6F0-A5AA"; fsType = "vfat"; };
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
}
