{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libva-utils # provides vainfo
    clinfo # provides clinfo (opencl)
    vulkan-tools # provides vulkaninfo
  ];
}
