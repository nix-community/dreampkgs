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
    python3 = nixpkgs.python311;
  };

  pdm.lockfile = ./pdm.lock;
  pdm.pyproject = ./pyproject.toml;
  pdm.pythonInterpreter = config.deps.python3;
  mkDerivation = {
    src = ./.;
    buildInputs = [
      config.deps.python3.pkgs.pdm-backend
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
      config.deps.python3.pkgs.poetry-core
    ];
    mkDerivation.propagatedBuildInputs = [
      config.deps.python3.pkgs.tkinter
    ];
  };
}
