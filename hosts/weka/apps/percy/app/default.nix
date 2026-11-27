# Percy's Node app: the pi SDK agent (src/) plus the Slack socket-mode
# listener, built with npm. tsc compiles src/ to dist/ at build time; the
# npm deps (pi SDK included) are locked in package-lock.json so the build is
# reproducible and `just snap` can track it.
# makeWrapper comes from buildNpmPackage's own nativeBuildInputs
{ lib, buildNpmPackage, nodejs_24 }:
buildNpmPackage {
  pname = "percy";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
      ./tsconfig.json
      ./src
    ];
  };
  nodejs = nodejs_24;
  npmDepsHash = "sha256-BJ6TTEfT7vwWyou89ZRvdkPNGiELIPag3cQ9S+v6l70=";

  # buildPhase runs `npm run build` (tsc, noEmitOnError)
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/percy
    cp -r dist node_modules package.json $out/lib/percy/
    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs_24} $out/bin/percy --add-flags "$out/lib/percy/dist/index.js"
    runHook postInstall
  '';

  meta = {
    description = "Percy, a read-only pi agent reachable in Slack's #percy channel";
    mainProgram = "percy";
  };
}
