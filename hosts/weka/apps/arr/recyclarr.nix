# Recyclarr: quality profiles, custom formats and quality sizes for Sonarr
# and Radarr, from the TRaSH Guides. Runs daily (a timer), so changes to the
# guides arrive by themselves. Lidarr isn't supported.
#
# Each profile is a guide profile by trash_id, which brings its default
# custom format groups along. Recyclarr owns these profiles and their
# scores: edits made to them in the UI are put back on the next run.
# Profiles it didn't create are left alone.
#
# Runs on the host, not in the VPN namespace: it fetches the guides from
# GitHub, and only talks to the *arrs at the namespace's address.
# @see: https://recyclarr.dev/wiki/yaml/config-reference/
# @see: https://github.com/recyclarr/config-templates (profiles and trash_ids)
{ config, ... }:
let
  ns = config.vpnNamespaces.vpn;
  instance = app: {
    base_url = "http://${ns.namespaceAddress}:${toString config.services.${app}.settings.server.port}";
    api_key._secret = config.sops.secrets."${app}_api_key".path;
  };
  profile = trash_id: {
    inherit trash_id;
    # Scores for custom formats the profile doesn't use are zeroed, so
    # leftovers from a previous profile don't skew it
    reset_unmatched_scores.enabled = true;
  };
in
{
  services.recyclarr = {
    enable = true;
    configuration = {
      sonarr.sonarr = instance "sonarr" // {
        quality_definition.type = "series";
        # WEB-1080p
        quality_profiles = [ (profile "72dae194fc92bf828f32cde7744e51a1") ];
      };
      radarr.radarr = instance "radarr" // {
        quality_definition.type = "movie";
        # HD Bluray + WEB
        quality_profiles = [ (profile "d1d67249d3890e49bc12e275d989a7e9") ];
      };
    };
  };

  systemd.services.recyclarr = {
    # Settle the apps first when they all start together
    after = [ "sonarr.service" "radarr.service" ];
    # The module writes config.yml, API keys included, into the state dir
    # with the default umask, which leaves it world-readable
    serviceConfig.UMask = "0077";
  };
}
