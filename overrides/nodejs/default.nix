{
  lib,
  pkgs,

  # dream2nix
  satisfiesSemver,
  ...
}:

let
  l = lib // builtins;

  # include this into an override to enable cntr debugging
  # (linux only)
  cntr = {
    nativeBuildInputs = [pkgs.breakpointHook];
    b = "${pkgs.busybox}/bin/busybox";
  };

in

## OVERRIDES
{

  css-loader = {

    disable-source-map-v4-v5 = {

      _condition = pkg:
        satisfiesSemver "^4.0.0" pkg
        || satisfiesSemver "^5.0.0" pkg;

      postPatch = ''
        substituteInPlace ./dist/utils.js --replace \
          "sourceMap: typeof rawOptions.sourceMap === "boolean" ? rawOptions.sourceMap : loaderContext.sourceMap," \
          "sourceMap: false,"
      '';
    };
  };

  electron =
    let

      mkElectron =
        pkgs.callPackage
          "${pkgs.path}/pkgs/development/tools/electron/generic.nix"
          {};

      nixpkgsElectrons =
        lib.mapAttrs
          (version: hashes:
            (mkElectron version hashes).overrideAttrs (old: {
              dontStrip = true;
              fixupPhase = old.postFixup;
            }))
          hashes;

      getElectronFor = version:
        nixpkgsElectrons."${version}"
        or (throw ''
          Electron binary hashes missing for required version ${version}
          Please add the hashes in the override below the origin of this error.
        '');

      # TODO: generate more of these via the script in nixpkgs,
      #       once we feel confident about this approach
      hashes = {
        "14.1.0" = {
          x86_64-linux = "27b60841c85369a0ea8b65a8b71cdd1fb08eba80d70e855e9311f46c595874f3";
          x86_64-darwin = "36d8e900bdcf5b410655e7fcb47800fa1f5a473c46acc1c4ce326822e5e95ee1";
          i686-linux = "808795405d6b27221b219c2a0f7a058e3acb2e56195c87dc08828dc882ffb8e9";
          armv7l-linux = "25a68645cdd1356d95a8bab9488f5aeeb9a206f9b5ee2df23c2e13f87d775847";
          aarch64-linux = "94047dcf53c54f6a5520a6eb62e400174addf04fc0e3ebe04b548ca962de349a";
          aarch64-darwin = "5c81f418f3f83dc6fc5893247dd386e1d23e609c83f798dd5aad451febed13c8";
          headers = "0p8lkhy97yq43sl6s4rskhdnzl520968cyh5l4fdhl2fhm5mayd4";
        };
        "14.2.0" = {
          armv7l-linux = "a1357716ebda8d7856f233c86a8cbaeccad1c83f1d725d260b0a6510c47042a2";
          aarch64-linux = "b1f4885c3ad816d89446f64a87b78d5139a27fecbf6317808479bede6fd94ae1";
          x86_64-linux = "b2faec4744edb20e889c3c85af685c2a6aef90bfff58f55b90038a991cd7691f";
          i686-linux = "9207af6e3a24dfcc76fded20f26512bcb20f6b652295a4ad3458dc10fd2d7d6e";
          x86_64-darwin = "d647d658c8c2ec4a69c071e791cf7e823320860f987121bd7390978aecacb073";
          aarch64-darwin = "f5a7e52b639b94cf9b2ec53969c8014c6d299437c65d98c33d8e5ca812fbfd48";
          headers = "1y289vr8bws3z6gmhaj3avz95rdhc8gd3rc7bi40jv9j1pnlsd3m";
        };
      };

    in

    {

      add-binary-v14 = {

        overrideAttrs = old: {
          postPatch = ''
            cp -r ${getElectronFor "${old.version}"}/lib/electron ./dist
            chmod -R +w ./dist
            echo -n $version > ./dist/version
            echo -n "electron" > ./path.txt
          '';
        };
      };
    };

  # TODO: fix electron-builder call or find alternative
  element-desktop = {
    build = {
      postPatch = ''
        ls tsconfig.json
        cp ${./element-desktop/tsconfig.json} ./tsconfig.json
      '';
      buildScript = ''
        npm run build:ts
        npm run build:res
        # electron-builder
      '';
      nativeBuildInputs = [pkgs.breakpointHook];
      b = "${pkgs.busybox}/bin/busybox";
    };
  };

  esbuild = {
    "add-binary-0.12.17" = {
      _condition = pkg: pkg.version == "0.12.17";
      ESBUILD_BINARY_PATH =
        let
          esbuild = pkgs.buildGoModule rec {
            pname = "esbuild";
            version = "0.12.17";

            src = pkgs.fetchFromGitHub {
              owner = "evanw";
              repo = "esbuild";
              rev = "v${version}";
              sha256 = "sha256-wZOBjNOgGmwIQNCrhzwGPmI/fW/yZiDqq8l4oSDTvZs=";
            };

            vendorSha256 = "sha256-2ABWPqhK2Cf4ipQH7XvRrd+ZscJhYPc3SV2cGT0apdg=";
          };
        in
          "${esbuild}/bin/esbuild";
    };
  };

  geckodriver = {
    add-binary = {
      GECKODRIVER_FILEPATH = "${pkgs.geckodriver}/bin/geckodriver";
    };
  };

  enhanced-resolve = {

    fix-resolution-v4 = {

      _condition = satisfiesSemver "^4.0.0";

      patches = [
        ./enhanced-resolve/npm-preserve-symlinks-v4.patch
      ];

      # respect node path
      postPatch = ''
        substituteInPlace lib/ResolverFactory.js --replace \
          'let modules = options.modules || ["node_modules"];' \
          'let modules = (options.modules || ["node_modules"]).concat(process.env.NODE_PATH.split( /[;:]/ ));'
      '';
    };

    fix-resolution-v5 = {

      _condition = satisfiesSemver "^5.0.0";

      patches = [
        ./enhanced-resolve/npm-preserve-symlinks-v5.patch
        ./enhanced-resolve/respect-node-path-v5.patch
      ];
    };
  };

  gifsicle = {
    add-binary = {
      buildScript = ''
        ln -s ${pkgs.gifsicle}/bin/gifsicle ./vendor/gifsicle
        npm run postinstall
      '';
    };
  };

  ledger-live-desktop = {
    build = {
      postPatch = ''
        substituteInPlace ./tools/main.js --replace \
          "git rev-parse --short HEAD" \
          "echo unknown"
      '';
    };
  };

  mattermost-desktop = {
    
    build = {

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      postPatch = ''
        substituteInPlace webpack.config.base.js --replace \
          "git rev-parse --short HEAD" \
          "echo foo"


        ${pkgs.jq}/bin/jq ".electronDist = \"$TMP/dist\"" electron-builder.json \
          | ${pkgs.moreutils}/bin/sponge electron-builder.json
        
        ${pkgs.jq}/bin/jq ".linux.target = [\"dir\"]" electron-builder.json \
          | ${pkgs.moreutils}/bin/sponge electron-builder.json
      '';

      # TODO:
      #   - figure out if building via electron-build is feasible
      #     (if not, remove commented out instructions)
      #   - app seems to logout immediately after login (token expired)
      buildPhase = ''
        # copy over the electron dist, as write access seems required
        cp -r ./node_modules/electron/dist $TMP/dist
        chmod -R +w $TMP/dist

        # required if electron-buidler is used
        # mv $TMP/dist/electron $TMP/dist/electron-wrapper
        # mv $TMP/dist/.electron-wrapped $TMP/dist/electron

        NODE_ENV=production npm-run-all check-build-config build-prod

        # skipping electron-builder, as produced executable crashes on startup
        # electron-builder --linux --x64 --publish=never

        # the electron wrapper wants to read the name and version from there
        cp package.json dist/package.json

        mkdir -p $out/bin
        makeWrapper \
          $(realpath ./node_modules/electron/dist/electron) \
          $out/bin/mattermost-desktop \
          --add-flags \
            $(realpath ./dist)
      '';
    };
  };

  mozjpeg = {
    add-binary = {
      buildScript = ''
        ln -s ${pkgs.mozjpeg}/bin/cjpeg ./vendor/cjpeg
        npm run postinstall
      '';
    };
  };

  optipng-bin = {
    add-binary = {
      buildScript = ''
        ln -s ${pkgs.optipng}/bin/optipng ./vendor/optipng
        npm run postinstall
      '';
    };
  };

  pngquant-bin = {
    add-binary = {
      buildScript = ''
        ln -s ${pkgs.pngquant}/bin/pngquant ./vendor/pngquant
        npm run postinstall
      '';
    };
  };

  rollup = {
    preserve-symlinks = {
      postPatch = ''
        find -name '*.js' -exec \
          sed -i "s/preserveSymlinks: .*/preserveSymlinks: true,/g" {} \;
      '';
    };
  };

  # TODO: confirm this is actually working
  typescript = {
    preserve-symlinks = {
      postPatch = ''
        find -name '*.js' -exec \
          sed -i "s/options.preserveSymlinks/true/g; s/compilerOptions.preserveSymlinks/true/g" {} \;
      '';
    };
  };

  # TODO: ensure preserving symlinks on dependency resolution always works
  #       The patch is currently done in `enhanced-resolve` which is used
  #       by webpack for module resolution
  webpack = {
    remove-webpack-cli-check = {
      _condition = pkg: pkg.version == "5.41.1";
      ignoreScripts = false;
      patches = [
        ./webpack/remove-webpack-cli-check.patch
      ];
    };
  };

  webpack-cli = {
    remove-webpack-check = {
      _condition = pkg: pkg.version == "4.7.2";
      ignoreScripts = false;
      patches = [
        ./webpack-cli/remove-webpack-check.patch
      ];
    };
  };

  # TODO: Maybe should replace binaries with the ones from nixpkgs
  "7zip-bin" = {

    patch-binaries = {

      nativeBuildInputs = [
        pkgs.autoPatchelfHook
      ];

      buildInputs = old: old ++ [
        pkgs.gcc-unwrapped.lib
      ];
    };
  };

  "@alicloud/fun" = {
    build = {
      buildScript = ''
        tsc -p ./
      '';
    };
  };

  "@mattermost/webapp" = {

    run-webpack = {

      # custom webpack config
      postPatch = ''
        # cp "${./. + "/@mattermost/webapp/webpack.config.js"}" webpack.config.js

        substituteInPlace webpack.config.js --replace \
          "crypto: require.resolve('crypto-browserify')," \
          "crypto: 'node_modules/crypto-browserify',"

        substituteInPlace webpack.config.js --replace \
          "stream: require.resolve('stream-browserify')," \
          "stream: 'node_modules/stream-browserify',"

        substituteInPlace webpack.config.js --replace \
          "DEV ? 'style-loader' : MiniCssExtractPlugin.loader," \
          ""
      '';

      # there seems to be a memory leak in some module
      # -> incleasing max memory
      buildScript = ''
        NODE_ENV=production node --max-old-space-size=8192 ./node_modules/webpack/bin/webpack.js
      '';
    };
  };

  # This should not be necessary, as this plugin claims to
  # respect the `preserveSymlinks` option of rollup.
  # Adding the NODE_PATH to the module directories fixes it for now.
  "@rollup/plugin-node-resolve" = {
    respect-node-path = {
      postPatch = ''
        for f in $(find -name '*.js'); do
          substituteInPlace $f --replace \
            "moduleDirectories: ['node_modules']," \
            "moduleDirectories: ['node_modules'].concat(process.env.NODE_PATH.split( /[;:]/ )),"
        done
      '';
    };
  };

}
