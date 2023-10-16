{ config
, dream2nix
, lib
, ...
}:
let
  source = config.deps.fetchFromGitHub {
    owner = "GRA0007";
    repo = "crab.fit";
    rev = "628f9eefc300bf1ed3d6cc3323332c2ed9b8a350";
    hash = "sha256-jy8BrJSHukRenPbZHw4nPx3cSi7E2GSg//WOXDh90mY=";
  };
in
{
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

  name = "crab-fit-frontend";
  version = (lib.substring 0 8 source.rev);

  nodejs-package-lock.source = (source + "/frontend");

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
      makeWrapper $(realpath $out/lib/node_modules/.bin/next) $out/bin/crab-fit-frontend \
        --chdir $out/lib/node_modules/crab-fit-frontend \
        --add-flags start
    '';
  };
}
