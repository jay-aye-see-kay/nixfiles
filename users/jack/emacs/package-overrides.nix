{ pkgs, epkgs, ... }: {
  prisma-mode =
    let
      # The version of prisma-mode in nixpkgs (22.05 and unstable) will
      # fail to load without lsp-mode. The current latest seems to work fine.
      rev = "f7744a995e84b8cf51265930ce18f6a6b26dade7";
      sha256 = "sha256-0TYKfOjGWUwXdjFgOpD7S2EQQrexcpOGosOijYfFz9Y=";
    in
    epkgs.prisma-mode.overrideAttrs (oldAttrs: {
      version = "20220707.0";
      commit = rev;
      src = pkgs.fetchFromGitHub {
        inherit rev sha256;
        owner = "pimeys";
        repo = "emacs-prisma-mode";
      };
    });
}
