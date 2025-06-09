{ pkgs, ... }:
{
  fonts = {
    # Enable a basic set of fonts providing several font styles and families
    # and reasonable coverage of Unicode.
    enableDefaultPackages = true;

    packages = with pkgs; [
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
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      proggyfonts
      ubuntu_font_family

      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.noto
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
