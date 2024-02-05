{
  config,
  dream2nix,
  lib,
  ...
}: let
  gpt-engineer =
    (lib.head (lib.attrValues config.groups.default.packages.gpt-engineer)).public;
in {
  imports = [
    dream2nix.modules.dream2nix.WIP-python-pdm
  ];

  deps = {nixpkgs, ...}: {
    python = nixpkgs.python311;
  };

  pdm.lockfile = ./pdm.lock;
  pdm.pyproject = ./pyproject.toml;

  mkDerivation = {
    src = ./.;
    buildInputs = [
      config.deps.python.pkgs.pdm-backend
    ];
    postFixup = ''
      mkdir -p $out/bin
      for bin in $(ls ${gpt-engineer}/bin/); do
        ln -s ${gpt-engineer}/bin/$bin $out/bin/$bin
      done

      # wrap program to set NODE_OPTIONS=--openssl-legacy-provider
      wrapProgram $out/bin/gpte \
        --prefix NODE_OPTIONS " " --openssl-legacy-provider
    '';
  };
  overrides.gpt-engineer = {
    mkDerivation.buildInputs = [
      config.deps.python.pkgs.poetry-core
    ];
    mkDerivation.propagatedBuildInputs = [
      config.deps.python.pkgs.tkinter
    ];
  };
}
