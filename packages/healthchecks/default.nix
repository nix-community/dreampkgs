{
  config,
  dream2nix,
  lib,
  ...
}: {
  imports = [
    dream2nix.modules.dream2nix.pip
  ];

  deps = {nixpkgs, ...}: {
    python = nixpkgs.python3;
    inherit (nixpkgs)
      fetchFromGitHub
      postgresql
      curl openssl
    ;
  };

  name = "healthchecks";
  version = "3.3";

  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "healthchecks";
      repo = config.name;
      rev = "v${config.version}";
      hash = "sha256-XQ8nr9z9Yjwr1irExIgYiGX2knMXX701i6BwvXsVP+E=";
    };
  };
  pip.requirementsFiles = [ "${config.mkDerivation.src}/requirements.txt" ];

  # As healthchecks isn't a real python package (setup.py or project.toml), but
  # just a repo with code and a requirements.txt inside we can't use the usual
  # machinery.
  buildPythonPackage.format = "other";
  pip.flattenDependencies = true;

  mkDerivation.installPhase = ''
    mkdir -p $out/share/healthchecks $out/bin
    cp -r . $out/share/healthchecks
    chmod +x $out/share/healthchecks/manage.py
  '';

  mkDerivation.postFixup = ''
    makeWrapper \
      $out/share/healthchecks/manage.py  \
      $out/bin/healthchecks \
      --prefix PATH : $program_PATH \
      --prefix PYTHONPATH : "$program_PYTHONPATH"
  '';


  # These buildInputs are only used during locking, well-behaved, i.e.
  # PEP 518 packages should not those, but some packages like psycopg2
  # require dependencies to be available during locking in order to execute
  # setup.py. This is fixed in psycopg3
  pip.nativeBuildInputs = [
    config.deps.postgresql  # psycopg2
    config.deps.curl.dev  # pycurl
  ];

  pip.overrides = {
    pycurl.mkDerivation.nativeBuildInputs = [
      config.deps.curl.dev
    ];
    pycurl.mkDerivation.buildInputs = [
      config.deps.curl.dev
      config.deps.openssl.dev
    ];
  };
}
