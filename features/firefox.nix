{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    # these policies are documented https://github.com/mozilla/policy-templates
    policies = {
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "never";
      OfferToSaveLogins = false;
      NoDefaultBookmarks = true;
      Permissions = {
        Location.BlockNewRequests = true;
        Notifications.BlockNewRequests = true;
      };
      PictureInPicture.Enabled = false;
      NewTabPage = false;
      Preferences = {
        "extensions.webextensions.restrictedDomains".Value = "";
        "dom.battery.enabled".Value = false;
      };
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "@ublacklist" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4055496/ublacklist/latest.xpi";
        };
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4040641/1password_x_password_manager/latest.xpi";
        };
      };
    };
  };

}
