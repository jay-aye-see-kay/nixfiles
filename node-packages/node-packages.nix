# This file has been generated by node2nix 1.9.0. Do not edit!

{nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}:

let
  sources = {
    "fsevents-2.3.2" = {
      name = "fsevents";
      packageName = "fsevents";
      version = "2.3.2";
      src = fetchurl {
        url = "https://registry.npmjs.org/fsevents/-/fsevents-2.3.2.tgz";
        sha512 = "xiqMQR4xAeHTuB9uWm+fFRcIOgKBMiOBP+eXiyT7jsgVCq1bkVygt00oASowB7EdtpOHaaPgKt812P9ab+DDKA==";
      };
    };
  };
in
{
  "aws-cdk-1.x" = nodeEnv.buildNodePackage {
    name = "aws-cdk";
    packageName = "aws-cdk";
    version = "1.167.0";
    src = fetchurl {
      url = "https://registry.npmjs.org/aws-cdk/-/aws-cdk-1.167.0.tgz";
      sha512 = "QuaCSJhJFiK+DpKqE3UWaZDlwD1rsnLNgSN2kh3kp95IZWFja74k8fIMi+qqRIQIaIak6hkpIEYQ9y+wsH23Bw==";
    };
    dependencies = [
      sources."fsevents-2.3.2"
    ];
    buildInputs = globalBuildInputs;
    meta = {
      description = "CDK Toolkit, the command line tool for CDK apps";
      homepage = "https://github.com/aws/aws-cdk";
      license = "Apache-2.0";
    };
    production = true;
    bypassCache = true;
    reconstructLock = true;
  };
}
