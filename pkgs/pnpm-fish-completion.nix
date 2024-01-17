{ fetchFromGitHub, buildFishPlugin }:

buildFishPlugin rec {
  pname = "pnpm-shell-completion";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "g-plane";
    repo = pname;
    rev = version;
    sha256 = "sha256-VCIT1HobLXWRe3yK2F3NPIuWkyCgckytLPi6yQEsSIE=";
  };

  nativeBuildInputs = [ ];

  preInstall = ''
    mkdir -p completions
    cp pnpm-shell-completion.fish completions/
  '';
}
