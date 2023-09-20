{ pkgs, lib, ... }:
let
  ifDarwin = lib.mkIf pkgs.stdenv.isDarwin;

  # has to be at least 2.15 to get the `ssl-cert-file` option (and nixpkgs 23.05 is 2.13)
  nixPackage = pkgs.nixVersions.nix_2_15;

  # add netskope's public cert to work macbook
  cacertPackage = pkgs.cacert.override {
    extraCertificateStrings = [
''-----BEGIN CERTIFICATE-----
MIID/DCCAuSgAwIBAgICATgwDQYJKoZIhvcNAQELBQAwgZcxCzAJBgNVBAYTAlVT
MQswCQYDVQQIEwJDQTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExFjAUBgNVBAoTDU5l
dHNrb3BlIEluYy4xEjAQBgNVBAsTCWNlcnRhZG1pbjESMBAGA1UEAxMJY2VydGFk
bWluMSUwIwYJKoZIhvcNAQkBFhZjZXJ0YWRtaW5AbmV0c2tvcGUuY29tMB4XDTE5
MTAyNTE4MTg1MFoXDTI5MTAyMjE4MTg1MFowgZcxCzAJBgNVBAYTAlVTMQswCQYD
VQQIEwJDQTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExFjAUBgNVBAoTDU5ldHNrb3Bl
IEluYy4xEjAQBgNVBAsTCWNlcnRhZG1pbjESMBAGA1UEAxMJY2VydGFkbWluMSUw
IwYJKoZIhvcNAQkBFhZjZXJ0YWRtaW5AbmV0c2tvcGUuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuYamgJifcWI3j9zv6OHI0hCQnZHj8uuzZ6sw
nfbediwij9X7MTbQZmswXZt4EgJ58uPN8Opt3+eh+XGP1wbQemUIm9ZkL5WzMVxP
3xW/twL5hBBQOXvn6JX5HS8N53fiDDU8LCuc0xj0Kpdl3TiDDpebtJe6UPiwebyz
jtOwD3ddpiIlArvRzUU1Hi9RIey2clf//3NChyvteQ3TIhciwxbViOxPHxXTRI7w
znFlwuDxvx7X5wwDkI2vzV2jpn23uIROjpCYC7kLvGInEKrgVAzoKauaC+tJmiJY
91m2KGN6xGc94JMRawH6Q+wv/7cBsOGVOUVIpxcM1XS5UqngTwIDAQABo1AwTjAM
BgNVHRMEBTADAQH/MB0GA1UdDgQWBBSvIpNrMIV6Lcujo5SCGWw3AGl7VDAfBgNV
HSMEGDAWgBSvIpNrMIV6Lcujo5SCGWw3AGl7VDANBgkqhkiG9w0BAQsFAAOCAQEA
pKVWEFpG7/d0kAhre2eYLwYEf6tVVP2to9Cp8RgBFSG/ScmEqt2/TXXcpMjRI5eG
nOUbPJIQJi2TQEiI/BG/g6CJZWJiE3fR3NTCksbLbcbdl7exkKT/tItebf4qXlca
ASSd0hBTygE7QqOPSENnSrj7r9P0gv0Z2Bf5jKdirhr/clz/ev88O3KYuxqwwl31
vyLDT0hd/Dzka2/ZKMXL5uFAtsYqpU4hz5NeGgNntKAkwcfFgsTh/NZaYjyRhvUp
jRBt2Mt8OwtxJ+vPM4mvpwFMzvfzhdJfKX/p6IWOJjDFHHFRqdFaHvW3zzarzFt6
tLom62fi7946+fyBmEPu5w==
-----END CERTIFICATE-----''
    ];
  };
in
{
  home.packages = ifDarwin [ nixPackage ];

  home.sessionVariables = ifDarwin {
    NIX_SSL_CERT_FILE = "${cacertPackage}/etc/ssl/certs/ca-bundle.crt";
  };

  nix = ifDarwin {
    package = nixPackage;
    settings = {
      ssl-cert-file = "${cacertPackage}/etc/ssl/certs/ca-bundle.crt";
    };
  };
}
