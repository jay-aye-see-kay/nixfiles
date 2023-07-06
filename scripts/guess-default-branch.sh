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

# Use the fallback if no remotes folder
if [ ! -e .git/refs/remotes ]; then
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
