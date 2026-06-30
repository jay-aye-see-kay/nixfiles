# Short git aliases — single source of truth, consumed by:
#   - fish.nix  -> g-prefixed fish abbrs:  gco -> "git checkout"
#   - home.nix  -> real git aliases:       git co -> git checkout
#
# Values are the bare git subcommand. Entries containing a `$()` command
# substitution are run through a shell when used as a git alias (auto-detected
# in home.nix and prefixed with `!git`); fish accepts `$()` as-is.
#
# Aliases that introduce a new concept (unstage, uncommit, ...) are intentionally
# NOT here — they live only in home.nix's git config and get no g* abbr.
{
  st = "status";
  co = "checkout";
  cob = "checkout -b";
  cod = "checkout develop";
  com = ''checkout "$(git guess-default-branch)"'';
  "-" = "checkout -"; # fish g- only; "-" is not a valid git alias name
  aa = "add .";
  ci = "commit";
  cia = "commit -a";
  d = "diff";
  df = "diff";
  dfs = "diff --staged";
  dm = ''diff "$(git merge-base "$(git guess-default-branch)" HEAD)"'';
  pr = "pull --rebase";
  pu = "push -u";
  pfl = "push --force-with-lease";
  pop = "stash pop";
  cp = "cherry-pick";
  rb = "rebase";
  sw = "switch";
  l = "log";
}
