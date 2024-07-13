{
  config,
  dream2nix,
  lib,
  ...
}: let
  version = "2024.6.3";

  src = config.deps.python3.pkgs.fetchPypi {
    pname = "homeassistant";
    inherit version;
    hash = "sha256-lhTVAYwtYf7UzplAIHTWqgd0P7V93gjNbBUlMd3i3oQ="; 
  };
in {
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  deps = {nixpkgs, ...}: {
    python = nixpkgs.python312;
    python3 = nixpkgs.python312;
    cc = nixpkgs.stdenv.cc;
    gammu = nixpkgs.gammu;
    openblas = nixpkgs.openblas;
    autoconf = nixpkgs.autoconf;
    runCommand = nixpkgs.runCommand;
    rsync = nixpkgs.rsync;
    buildEnv = nixpkgs.buildEnv;
  };

  name = "homeassistant";
  inherit version;
  buildPythonPackage.catchConflicts = false;
  buildPythonPackage.format = "pyproject";

  mkDerivation = {
    inherit src;
    propagatedBuildInputs = [
      # these are soo many dependencies that our stack overflows because of environment variables
      (config.deps.buildEnv {
        name = "env";
        paths = builtins.map (drv: drv.public) (builtins.attrValues (lib.filterAttrs (n: v: n != "homeassistant") config.pip.drvs));
        ignoreCollisions = true;
      })
    ];
    postPatch = ''
      sed -i 's/wheel[~=]/wheel>/' pyproject.toml
      sed -i 's/setuptools[~=]/setuptools>/' pyproject.toml
    '';
  };

  pip = {
    pipFlags = [
      "-c"
      "${./package_constraints.txt}"
    ];
    requirementsList = [
      "setuptools-scm[toml]"
      "homeassistant==${version}"
    ];
    requirementsFiles = ["${./requirements.txt}"];
    # XXX those nativeBuildInputs are not yet correctly forwarded
    nativeBuildInputs = [
      config.deps.cc
      config.deps.openblas
    ] ++ lib.optionals config.deps.stdenv.isLinux [
      config.deps.gammu
    ];

    drvs = {
      cached-ipaddress.mkDerivation = {
        nativeBuildInputs = [
          config.deps.python.pkgs.poetry-core
          config.deps.python.pkgs.cython
        ];

        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace " --cov=cached_ipaddress --cov-report=term-missing:skip-covered" "" \
            --replace "Cython>=3.0.5" "Cython"
        '';
      };
      dtlssocket.mkDerivation = {
        nativeBuildInputs = [
          config.deps.python.pkgs.cython
          config.deps.autoconf
        ];
      };
      ms-cv.mkDerivation = {
        buildInputs = [
          config.deps.python.pkgs.pytest-runner
        ];
      };
      webrtc-noise-gain.mkDerivation = {
        buildInputs = [
          config.deps.python.pkgs.pybind11
        ];
      };
      pygatt.mkDerivation = {
        buildInputs = [
          config.deps.python.pkgs.pynose
          config.deps.python.pkgs.coverage
        ];
        nativeBuildInputs = [
          config.deps.python.pkgs.wheel
        ];
        postPatch = ''
          substituteInPlace requirements.txt \
            --replace "nose" "pynose" 
          substituteInPlace setup.py \
            --replace "nose" "pynose" \
        '';
      };
      titlecase = {
        mkDerivation = {
          nativeBuildInputs = [
            config.pip.drvs.setuptools-scm.public
          ];
        };
      };
    };
  };
}
