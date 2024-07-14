{
  config,
  dream2nix,
  ...
}: {
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  deps = {nixpkgs, ...}: {
    python = nixpkgs.python3;
    inherit (nixpkgs)
      gcc
      ninja;
  };

  name = "beancount";
  version = "3.0.0";

  buildPythonPackage.pyproject = true;
  pip = {
    requirementsList = ["${config.name}==${config.version}"];
    nativeBuildInputs = [ config.deps.gcc config.deps.ninja ];
    buildDependencies.meson-python = true;
    pipFlags = [ "--no-binary" "beancount" ];
  };

  env.dontUseMesonConfigure = true;
  mkDerivation = with config.deps; {
    nativeBuildInputs = [
      python.pkgs.meson-python
      python.pkgs.ninja
    ];
  };
}
