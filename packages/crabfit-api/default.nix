{
  lib,
  config,
  dream2nix,
  inputs,
  ...
}: let
  source = inputs.crab-fit + "/api";
in {
  imports = [
    dream2nix.modules.dream2nix.rust-cargo-lock
    dream2nix.modules.dream2nix.rust-crane
  ];

  deps = {nixpkgs, dreanpkgs, ...}: {
    inherit (nixpkgs)
      fetchFromGitHub
      openssl
      pkg-config
      protobuf
      ;
  };

  name = "crabfit-api";
  version = "3.0.0";

  env.PROTOC = "${config.deps.protobuf}/bin/protoc";

  mkDerivation = {
    src = source;
    buildInputs = [
      config.deps.openssl
    ];
    nativeBuildInputs = [
      config.deps.pkg-config
    ];
  };

  rust-crane = {
    buildProfile = "dev";
    buildFlags = ["--verbose"];
    runTests = false;
    depsDrv = {
      env.PROTOC = "${config.deps.protobuf}/bin/protoc";
      # options defined here will be applied to the dependencies derivation
      mkDerivation.preBuild = ''
        rm $TMPDIR/nix-vendor/google-cloud-0.2.1/build.rs
      '';
      mkDerivation.buildInputs = [
        config.deps.openssl
      ];
      mkDerivation.nativeBuildInputs = [
        config.deps.pkg-config
        config.deps.protobuf
      ];
    };
  };
}
