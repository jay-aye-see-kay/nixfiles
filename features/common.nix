{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = 
    import ./cli-utils.nix { inherit pkgs; };
}
