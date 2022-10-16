#!/bin/sh

home-manager switch --flake ".#$(whoami)@$(hostname)"

# Copy all these files to the the user `hud`s home directory and run from there
# as that user to install, but don't run this part again once we're running
# this script as `hud`
if [ "$(hostname)" = "kakapo" ] && [ "$(whoami)" != "hud" ]; then
  sudo rsync -r /home/jack/nixfiles /home/hud/
  sudo -u hud bash -c "cd ~/nixfiles && ./home-switch.sh"
fi
