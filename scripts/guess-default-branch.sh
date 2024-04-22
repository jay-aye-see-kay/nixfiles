#!/bin/sh

set -e

# Exit if not in toplevel of git dir, git-cli will print to stderr, cd to it otherwise
TOPLEVEL_DIR=$(git rev-parse --show-toplevel)
if [ -z "$TOPLEVEL_DIR" ]; then
  exit 1
fi
cd "$TOPLEVEL_DIR"

# Figure out which branch to use as a guess if no remote is found
LOCAL_FALLBACK="master"
DEFAULT_BRANCH="$(git config init.defaultbranch)"
if [ -z "$DEFAULT_BRANCH" ]; then
  LOCAL_FALLBACK=$DEFAULT_BRANCH
fi
if git show-ref --quiet refs/heads/master; then
  LOCAL_FALLBACK="master"
fi
if git show-ref --quiet refs/heads/main; then
  LOCAL_FALLBACK="main"
fi

# workaround for when you've created a repo and pushed it, you'll have a remote
# but no `.git/refs/remotes/.../HEAD` file
#
# only known other option is `git remote show origin | grep 'HEAD branch' | cut -d' ' -f5`
# which makes network request, so over 2 secs
NO_REMOTE_HEADS=false
for remote in .git/refs/remotes/*; do
  if [ ! -f "$remote/HEAD" ]; then
    NO_REMOTE_HEADS=true
  fi
done

# Use the fallback if no remotes folder
if [ "$NO_REMOTE_HEADS" = "true" ] || [ ! -e .git/refs/remotes ]; then
  echo "$LOCAL_FALLBACK"
  exit 0
fi

if [ -e .git/refs/remotes ]; then
  REMOTE_HEADS=$(cat .git/refs/remotes/*/HEAD | sed 's%^ref: refs/remotes/%%')
  REMOTE_HEADS_COUNT=$(echo "$REMOTE_HEADS" | wc -l)
else
  REMOTE_HEADS_COUNT="0"
fi

if [ "$REMOTE_HEADS_COUNT" = "0" ]; then
  echo "$LOCAL_FALLBACK"
  exit 0
elif [ "$REMOTE_HEADS_COUNT" = "1" ]; then
  echo "$REMOTE_HEADS" | sed 's%^.*/%%'
  exit 0
else
  # FIXME do something smarter here (i.e. look at origin and upstream first)
  echo "$REMOTE_HEADS" | head -n 1 | sed 's%^.*/%%'
  exit 0
fi
