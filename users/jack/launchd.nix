{ pkgs, ... }:
{
  #   # not working even though it generates the exact same plist file as AeroSpace generates
  #   launchd.agents.aerospace = {
  #     enable = true;
  #     config = {
  #       Label = "bobko.aerospace";
  #       ProgramArguments = [
  #         "${pkgs.unstable.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  #         "--started-at-login"
  #       ];
  #       RunAtLoad = true;
  #     };
  #   };

  launchd.agents.jankyborders = {
    enable = true;
    config = {
      Label = "github.felixkratz.jankyborders";
      ProgramArguments = [
        "${pkgs.unstable.jankyborders}/bin/borders"
        "width=8"
        "active_color=0xffc2645b"
      ];
      RunAtLoad = true;
    };
  };
}
