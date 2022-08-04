set -eu -o pipefail

nix-shell -p nodePackages.node2nix --run \
  "node2nix -i node-packages.json --pkg-name nodejs-14_x"
