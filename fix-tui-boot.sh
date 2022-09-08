#!/bin/sh

set -eu

if [ "$(hostname)" != "tui" ]; then
	echo "This script should only be run on tui. Exiting."
	exit 1
fi

MOUNT_POINT="/boot"
BOOT_PARTITION="/dev/nvme0n1p3"

echo "==="
echo "About to wipe the boot partition and reformat it"
echo "Assuming boot partition is:  $BOOT_PARTITION"
echo "and that it's mounted at:    $MOUNT_POINT"
echo "and that it's partition number *3*"
echo "==="
echo "lsblk $BOOT_PARTITION:"
lsblk $BOOT_PARTITION
echo "==="
echo ""

echo "Continue? [yes/no]"
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "That's not a yes, exiting..."
  exit 0
fi

echo "Unmounting"
sudo umount $MOUNT_POINT

echo "Deleting a recreating partition"
sudo parted /dev/nvme0n1 -- rm 3
sudo parted /dev/nvme0n1 -- mkpart BOOT fat32 1MB 512MB
sudo parted /dev/nvme0n1 -- set 3 esp on

echo "Formatting partition"
sudo mkfs.fat -F 32 -n BOOT $BOOT_PARTITION

echo "Mounting"
sudo mount $BOOT_PARTITION $MOUNT_POINT

echo "Re-installing bootloader"
nixos-rebuild --use-remote-sudo --install-bootloader switch --flake .#
