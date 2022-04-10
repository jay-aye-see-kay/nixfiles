{ config, pkgs, ... }:
{
  fonts = {
    # Enable a basic set of fonts providing several font styles and families
    # and reasonable coverage of Unicode.
    enableDefaultFonts = true;

    fonts = with pkgs; [
      font-awesome
      fira-code
      fira-code-symbols
      cantarell-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "Noto" ]; })
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "NotoSerif Nerd Font" ];
        sansSerif = [ "NotoSans Nerd Font" ];
        monospace = [ "NotoSansMono Nerd Font" ];
        emoji = [ "NotoColorEmoji" ];
      };
    };
  };
}
