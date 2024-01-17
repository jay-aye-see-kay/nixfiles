{ pkgs, ... }: {
  pnpm-fish-completion = pkgs.callPackage ./pnpm-fish-completion.nix { };
}
