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

  # TODO: this doesn't seem to work yet
  electron = {
    add-binary-v13 = {
      _condition = satisfiesSemver "^13.0.0";
      ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
      installPhase = ''
        ln -s ${pkgs.electron_13}/bin $out/bin
        ln -s ${pkgs.electron_13}/lib $out/lib
      '';
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
    preserve-symlinks-v4 = {
      _condition = satisfiesSemver "^4.0.0";
      patches = [
        ./enhanced-resolve/npm-preserve-symlinks-v4.patch
      ];
    };
    preserve-symlinks-v5 = {
      _condition = satisfiesSemver "^5.0.0";
      patches = [
        ./enhanced-resolve/npm-preserve-symlinks-v5.patch
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

  "@alicloud/fun" = {
    build = {
      buildScript = ''
        tsc -p ./
      '';
    };
  };

  # TODO: fix build
  "@mattermost/webapp" = {
    run-webpack = {
      # custom webpack config
      postPatch = ''
        cp "${./. + "/@mattermost/webapp/webpack.config.js"}" webpack.config.js
      '';
      # there seems to be a memory leak in some module
      # -> incleasing max memory
      buildScript = ''
        NODE_ENV=production node --max-old-space-size=8192 ./node_modules/webpack/bin/webpack.js
      '';
    };
  };
}