{ lib
, config
, dream2nix
, lighthouse-src
, ...
}:
let
  fake-git = config.deps.writeShellScriptBin "git" ''echo "${config.version}"'';
in
rec {
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-json
    dream2nix.modules.dream2nix.nodejs-granular
  ];

  name = "lighthouse";
  version = "11.2.0";

  mkDerivation = {
    src = config.deps.fetchFromGitHub {
      owner = "GoogleChrome";
      repo = "lighthouse";
      rev = "v${version}";
      sha256 = "sha256-VUH2c2YKEtcBiQIlWvhDTu+Ar74oFunYDzrCSpEwR5M=";
    };
    nativeBuildInputs = [ fake-git ];
    preInstall = ''
      unlink ./node_modules/lighthouse-logger
      unlink ./node_modules/lighthouse
    '';
    postInstall = ''
      cp -r $out/lib/node_modules/lighthouse/lighthouse-logger $out/lib/node_modules/lighthouse/node_modules
    '';
  };

  deps = { nixpkgs, ... }: {
    inherit
      (nixpkgs)
      stdenv
      writeShellScriptBin
      fetchFromGitHub
      ;
    npm = nixpkgs.nodejs.pkgs.npm.override (old: rec {
      version = "8.19.4";
      src = builtins.fetchTarball {
        url = "https://registry.npmjs.org/npm/-/npm-${version}.tgz";
        sha256 = "0xmvjkxgfavlbm8cj3jx66mlmc20f9kqzigjqripgj71j6b2m9by";
      };
    });
  };

  nodejs-package-json.npmArgs = [ "--force" ];
  nodejs-package-lock.source = config.mkDerivation.src;
  nodejs-granular = {
    deps.puppeteer."21.3.6".env.PUPPETEER_SKIP_DOWNLOAD = true;
    buildScript = ''
      chmod +w -R ./node_modules/lighthouse
      rm -rf ./node_modules/lighthouse
      ln -s "$(realpath .)" ./node_modules/lighthouse
      ln -s "$(realpath ./lighthouse-logger)" ./node_modules/lighthouse-logger
      node build/build-report-components.js && node build/build-report.js
      node ./build/build-bundle.js clients/devtools/devtools-entry.js dist/lighthouse-dt-bundle.js && node ./build/build-dt-report-resources.js
    '';
  };
}
