{
  lib,
  config,
  dream2nix,
  inputs,
  ...
}: {
  imports = [
    dream2nix.modules.dream2nix.php-composer-lock
    dream2nix.modules.dream2nix.php-granular
  ];

  deps = {nixpkgs, ...}: {
    inherit
      (nixpkgs)
      fetchFromGitHub
      stdenv
      ;
  };

  name = "logchecker";
  version = "0.11.1";

  php-composer-lock = {
    source = inputs.logchecker;
  };

  mkDerivation = {
    src = config.php-composer-lock.source;
  };
}
