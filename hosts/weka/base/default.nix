# The machine itself: disks, pools, network, power, and unlocking the root
# pool at boot.
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./network.nix
    ./unlock.nix
    ./tank1.nix
    ./ups.nix
  ];
}
