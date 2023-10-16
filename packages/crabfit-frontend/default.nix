{ config
, dream2nix
, lib
, inputs
, ...
}: {
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-json
    dream2nix.modules.dream2nix.nodejs-package-lock
    dream2nix.modules.dream2nix.nodejs-granular
  ];

  deps = { nixpkgs, ... }: {
    inherit
      (nixpkgs)
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

  name = "crabfit-frontend";
  version = (lib.substring 0 8 inputs.crab-fit.rev);

  nodejs-package-lock.source = (inputs.crab-fit + "/frontend");

  nodejs-granular.buildScript = ''
    next build
  '';

  mkDerivation = {
    src = config.nodejs-package-lock.source;
    postPatch = ''
      substituteInPlace src/app/layout.tsx \
        --replace "import { Karla } from 'next/font/google'" "" \
        --replace "const karla = Karla({ subsets: ['latin'] })" "" \
        --replace "<body className={karla.className}>" "<body>"
    '';
    postInstall = ''
      makeWrapper $(realpath $out/lib/node_modules/.bin/next) $out/bin/crabfit-frontend \
        --chdir $out/lib/node_modules/crabfit-frontend \
        --add-flags start
    '';
  };
}
