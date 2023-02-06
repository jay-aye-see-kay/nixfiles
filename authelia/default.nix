# From this unmerged PR: https://github.com/NixOS/nixpkgs/pull/180469

{ lib, fetchFromGitHub, buildGoModule, installShellFiles, fetchurl, ... }:

buildGoModule rec {
  pname = "authelia";
  version = "4.37.5";

  src = fetchFromGitHub {
    owner = "authelia";
    repo = "authelia";
    rev = "v${version}";
    sha256 = "sha256-xsdBnyPHFIimhp2rcudWqvVR36WN4vBXbxRmvgqMcDw=";
  };
  vendorSha256 = "sha256-mzGE/T/2TT4+7uc2axTqG3aeLMnt1r9Ya7Zj2jIkw/w=";

  nativeBuildInputs = [ installShellFiles ];

  ui = fetchurl {
    url = "https://github.com/authelia/authelia/releases/download/v${version}/authelia-v${version}-public_html.tar.gz";
    sha256 = "sha256-bU+0GC3Nn9OrwQ+dW5f2rTHOrZdaqNUvfHKjQvOEM5g=";
  };


  postPatch = ''
    rm -r internal/server/public_html
    tar -C internal/server -xzf ${ui}
  '';

  subPackages = [ "cmd/authelia" ];

  ldflags =
    let
      p = "github.com/authelia/authelia/v${lib.versions.major version}/internal/utils";
    in
    [
      "-s"
      "-w"
      "-X ${p}.BuildTag=v${version}"
      "-X '${p}.BuildState=tagged clean'"
      "-X ${p}.BuildBranch=v${version}"
      "-X ${p}.BuildExtra=nixpkgs"
    ];

  # several tests with networking and several that want chromium
  doCheck = false;

  postInstall = ''
    mkdir -p $out/etc/authelia
    cp config.template.yml $out/etc/authelia
    installShellCompletion --cmd authelia \
      --bash <($out/bin/authelia completions bash) \
      --fish <($out/bin/authelia completions fish) \
      --zsh <($out/bin/authelia completions zsh)
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/authelia --help
    $out/bin/authelia --version | grep "v${version}"
    $out/bin/authelia build-info | grep 'v${version}\|nixpkgs'
    runHook postInstallCheck
  '';

  passthru = {
    # if overriding replace the postFetch to put your UI config in internal/server/public_html
    # or use finalAttrs
    inherit ui;
    updateScript = ./update.sh;
  };

  meta = with lib; {
    homepage = "https://www.authelia.com/";
    changelog = "https://github.com/authelia/authelia/releases/tag/v${version}";
    description = "A Single Sign-On Multi-Factor portal for web apps";
    longDescription = ''
      Authelia is an open-source authentication and authorization server
      providing two-factor authentication and single sign-on (SSO) for your
      applications via a web portal. It acts as a companion for reverse proxies
      like nginx, Traefik, caddy or HAProxy to let them know whether requests
      should either be allowed or redirected to Authelia's portal for
      authentication.
    '';
    license = licenses.asl20;
    maintainers = [];
  };
}

