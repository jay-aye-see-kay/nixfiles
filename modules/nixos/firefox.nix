{ config, lib, pkgs, ... }:
let
  cfg = config.modules.firefox;
in
{
  options.modules.firefox = {
    enable = lib.mkEnableOption "Firefox web browser with custom policies";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      # use autoConfig for policies that can't be touched with policies.Preferences
      # @see: https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig
      autoConfig = ''
        // hide the webcam popup thing when in video calls
        pref("privacy.webrtc.legacyGlobalIndicator", false);
        pref("privacy.webrtc.hideGlobalIndicator", true);

        // allow extensions on mozilla sites
        pref("extensions.webextensions.restrictedDomains", "");
        pref("privacy.resistFingerprinting.block_mozAddonManager", true);
      '';
      # @see: https://github.com/mozilla/policy-templates
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
  };
}
