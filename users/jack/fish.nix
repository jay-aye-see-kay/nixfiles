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

      # TokyoNight Color Palette
      set -l foreground c0caf5
      set -l selection 33467c
      set -l comment 565f89
      set -l red f7768e
      set -l orange ff9e64
      set -l yellow e0af68
      set -l green 9ece6a
      set -l purple 9d7cd8
      set -l cyan 7dcfff
      set -l pink bb9af7

      # Syntax Highlighting Colors
      set -g fish_color_normal $foreground
      set -g fish_color_command $cyan
      set -g fish_color_keyword $pink
      set -g fish_color_quote $yellow
      set -g fish_color_redirection $foreground
      set -g fish_color_end $orange
      set -g fish_color_error $red
      set -g fish_color_param $purple
      set -g fish_color_comment $comment
      set -g fish_color_selection --background=$selection
      set -g fish_color_search_match --background=$selection
      set -g fish_color_operator $green
      set -g fish_color_escape $pink
      set -g fish_color_autosuggestion $comment

      # Completion Pager Colors
      set -g fish_pager_color_progress $comment
      set -g fish_pager_color_prefix $cyan
      set -g fish_pager_color_completion $foreground
      set -g fish_pager_color_description $comment
      set -g fish_pager_color_selected_background --background=$selection
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
