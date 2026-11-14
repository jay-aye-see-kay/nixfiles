# The machine itself: disks, pools, power, and unlocking the root pool at boot.
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./unlock.nix
    ./tank1.nix
    ./ups.nix
  ];
}
