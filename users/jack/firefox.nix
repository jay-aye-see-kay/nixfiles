{ pkgs, lib, ... }:
{
  programs.firefox = {
    enable = true;
    # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    #   bitwarden
    #   multi-account-containers
    #   refined-github
    #   sponsorblock
    #   ublock-origin
    #   decentraleyes
    #   clearurls
    #   kristofferhagen-nord-theme
    #   ninja-cookie
    #   old-reddit-redirect
    #   unpaywall
    #   h264ify
    #   privacy-redirect
    # ];
    profiles = {
      default = {
        isDefault = true;
        settings = {
          # Do not save passwords to Firefox...
          "security.ask_for_password" = 0;

          # We handle this elsewhere
          "browser.shell.checkDefaultBrowser" = false;

          # Don't allow websites to prevent use of right-click, or otherwise
          # messing with the context menu.
          "dom.event.contextmenu.enabled" = true;

          # Don't allow websites to prevent copy and paste. Disable
          # notifications of copy, paste, or cut functions. Stop webpage
          # knowing which part of the page had been selected.
          "dom.event.clipboardevents.enabled" = true;

          # Do not track from battery status.
          "dom.battery.enabled" = false;

          # Show punycode. Help protect from character 'spoofing'.
          "network.IDN_show_punycode" = true;

          # Disable site reading installed plugins.
          "plugins.enumerable_names" = "";

          # Use Mozilla instead of Google here.
          "geo.provider.network.url" =
            "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";

          # No speculative content when searching.
          "browser.urlbar.speculativeConnect.enabled" = false;

          # Sends data to servers when leaving pages.
          "beacon.enabled" = false;

          # Informs servers about links that get clicked on by the user.
          "browser.send_pings" = false;

          "browser.tabs.closeWindowWithLastTab" = false;
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.search.defaultenginename" = "DuckDuckGo";

          # Safe browsing
          "browser.safebrowsing.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.downloads.enabled" = false;
          "browser.safebrowsing.provider.google4.updateURL" = "";
          "browser.safebrowsing.provider.google4.reportURL" = "";
          "browser.safebrowsing.provider.google4.reportPhishMistakeURL" = "";
          "browser.safebrowsing.provider.google4.reportMalwareMistakeURL" =
            "";
          "browser.safebrowsing.provider.google4.lists" = "";
          "browser.safebrowsing.provider.google4.gethashURL" = "";
          "browser.safebrowsing.provider.google4.dataSharingURL" = "";
          "browser.safebrowsing.provider.google4.dataSharing.enabled" = false;
          "browser.safebrowsing.provider.google4.advisoryURL" = "";
          "browser.safebrowsing.provider.google4.advisoryName" = "";
          "browser.safebrowsing.provider.google.updateURL" = "";
          "browser.safebrowsing.provider.google.reportURL" = "";
          "browser.safebrowsing.provider.google.reportPhishMistakeURL" = "";
          "browser.safebrowsing.provider.google.reportMalwareMistakeURL" = "";
          "browser.safebrowsing.provider.google.pver" = "";
          "browser.safebrowsing.provider.google.lists" = "";
          "browser.safebrowsing.provider.google.gethashURL" = "";
          "browser.safebrowsing.provider.google.advisoryURL" = "";
          "browser.safebrowsing.downloads.remote.url" = "";

          # Don't call home on new tabs
          "browser.selfsupport.url" = "";
          "browser.aboutHomeSnippets.updateUrL" = "";
          "browser.startup.homepage_override.mstone" = "ignore";
          "browser.startup.homepage_override.buildID" = "";
          "startup.homepage_welcome_url" = "";
          "startup.homepage_welcome_url.additional" = "";
          "startup.homepage_override_url" = "";

          # Firefox experiments...
          "experiments.activeExperiment" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "extensions.pocket.enabled" = false;
          "identity.fxaccounts.enabled" = false;

          # Privacy
          "privacy.donottrackheader.enabled" = true;
          "privacy.donottrackheader.value" = 1;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.firstparty.isolate" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "never";

          # Cookies
          "network.cookie.cookieBehavior" = 1;

          # # Perf
          # "gfx.webrender.all" = true;
          # "media.ffmpeg.vaapi.enabled" = true;
          # "media.ffvpx.enabled" = false;
          # "media.rdd-vpx.enabled" = false;
          # "gfx.webrender.compositor.force-enabled" = true;
          # "media.navigator.mediadatadecoder_vpx_enabled" = true;
          # "webgl.force-enabled" = true;
          # "layers.acceleration.force-enabled" = true;
          # "layers.offmainthreadcomposition.enabled" = true;
          # "layers.offmainthreadcomposition.async-animations" = true;
          # "layers.async-video.enabled" = true;
          # "html5.offmainthread" = true;

          # # Remove those extra empty spaces in both sides
          # "browser.uiCustomization.state" = ''
          #   {"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","urlbar-container","downloads-button","fxa-toolbar-menu-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["developer-button"],"dirtyAreaCache":["nav-bar","PersonalToolbar"],"currentVersion":17,"newElementCount":4}
          # '';
        };
      };
    };
  };
}
