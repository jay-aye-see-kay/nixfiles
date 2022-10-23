{ config, pkgs, ... }: {
  programs.fish = {
    enable = true;

    shellAbbrs = {
      _ = "sudo";
      g = "git";
      gs = "git status";
      gpr = "git pull --rebase";
      s = "systemctl";
      v = "nvim";
      y = "yarn";
      p = "pnpm";
      d = "docker";
      dc = "docker-compose";
      "~" = "cd ~";
      "-" = "cd -";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
    };

    shellAliases = {
      rg = "rg --hidden";
      sizes = "du -csh * | sort -h";
      whoslistening = "ss -lntup";
      vwt = "nvim -c LogbookToday";
      journal = "nvim $HOME/Documents/journal-2022.org";
      shopping_list =
        "nvim $HOME/Documents/shopping-lists/(date --iso-8601).md";
      vg = ''nvim -c "Git | wincmd k | q"'';
      pbc = "wl-copy";
      pbp = "wl-paste";
    };

    shellInit = ''
      # suppress default greeting
      set -U fish_greeting

      # use bash default to edit line in vim
      bind \cx\ce edit_command_buffer

      # language env set up
      fish_add_path "$HOME/.local/bin" # pip
      fish_add_path "$HOME/.poetry/bin" # poetry
      fish_add_path "(ruby -e 'puts Gem.user_dir')/bin" # ruby
      fish_add_path "$HOME/.npm_global/bin" # npm
      fish_add_path "$HOME/.yarn/bin" # yarn
      fish_add_path "$HOME/.cargo/bin" # rust
      fish_add_path "$HOME/.emacs.d/bin" # doom/emacs

      set -x ANDROID_HOME "$HOME/Android/Sdk"
      [ (uname) = "Darwin" ] && set -x ANDROID_HOME "$HOME/Library/Android/Sdk"
      fish_add_path \
        "$ANDROID_HOME/emulator" \
        "$ANDROID_HOME/tools" \
        "$ANDROID_HOME/tools/bin" \
        "$ANDROID_HOME/platform-tools"

      # nord theme
      set -U fish_color_normal normal
      set -U fish_color_command 81a1c1
      set -U fish_color_quote a3be8c
      set -U fish_color_redirection b48ead
      set -U fish_color_end 88c0d0
      set -U fish_color_error ebcb8b
      set -U fish_color_param eceff4
      set -U fish_color_comment 434c5e
      set -U fish_color_match --background=brblue
      set -U fish_color_selection white --bold --background=brblack
      set -U fish_color_search_match bryellow --background=brblack
      set -U fish_color_history_current --bold
      set -U fish_color_operator 00a6b2
      set -U fish_color_escape 00a6b2
      set -U fish_color_cwd green
      set -U fish_color_cwd_root red
      set -U fish_color_valid_path --underline
      set -U fish_color_autosuggestion 4c566a
      set -U fish_color_user brgreen
      set -U fish_color_host normal
      set -U fish_color_cancel -r
      set -U fish_pager_color_completion normal
      set -U fish_pager_color_description B3A06D yellow
      set -U fish_pager_color_prefix normal --bold --underline
      set -U fish_pager_color_progress brwhite --background=cyan
    '';

    plugins = [{
      name = "foreign-env";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "plugin-foreign-env";
        rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
        sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
      };
    }];
  };
}
