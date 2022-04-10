{ config, pkgs, ... }:
{
  fonts = {
    # Enable a basic set of fonts providing several font styles and families
    # and reasonable coverage of Unicode.
    enableDefaultFonts = true;

    fonts = with pkgs; [
      awesome
      cantarell-fonts
      corefonts
      dejavu_fonts
      fira-code
      fira-code-symbols
      font-awesome
      hack-font
      inconsolata
      liberation_ttf
      nerdfonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      proggyfonts
      ubuntu_font_family
    ];

    # fontconfig = {
    #   defaultFonts = {
    #     serif = [ "NotoSerif Nerd Font" ];
    #     sansSerif = [ "NotoSans Nerd Font" ];
    #     monospace = [ "NotoSansMono Nerd Font" ];
    #     emoji = [ "NotoColorEmoji" ];
    #   };
    # };
  };
}
