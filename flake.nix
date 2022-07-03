{
  description = "A collection of software packages managed with dream2nix";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    dream2nix.inputs.nixpkgs.follows = "nixpkgs";

    # nodejs sources
    src_mattermost-webapp.url = "github:mattermost/mattermost-webapp/v6.0.2";
    src_mattermost-webapp.flake = false;
    src_mattermost-desktop.url = "github:mattermost/desktop/v5.0.1";
    src_mattermost-desktop.flake = false;

    # python sources
    src_orange3.url = "github:biolab/orange3/3.32.0";
    src_orange3.flake = false;
    src_labelimg.url = "https://files.pythonhosted.org/packages/c5/fb/9947097363fbbfde3921f7cf7ce9800c89f909d26a506145aec37c75cda7/labelImg-1.8.6.tar.gz";
    src_labelimg.flake = false;
    src_labelme = {flake = false; url = "github:wkentaro/labelme";};
    src_urh = {flake = false; url = "github:jopohl/urh";};
    src_httpie = {flake = false; url = "github:httpie/httpie";};
  };

  outputs = {
    self,
    nixpkgs,
    dream2nix,
    ...
  }@inp:
  let

    l = nixpkgs.lib // builtins;

    supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

    forAllSystems = f: l.genAttrs supportedSystems
      (system: f system (import nixpkgs { inherit system; }));

    config = {
      repoName = "dreampkgs";
      projectRoot = ./.;
      packagesDir = "dream2nix-packages";
    };

    dream2nix = inp.dream2nix.lib.init {
      pkgs = inp.nixpkgs.legacyPackages.x86_64-linux;
      inherit config;
    };

    mkOutputs = src: dream2nix.makeOutputs { source = src;};

    /*
      # FIXME:
      This wrapper for `makeOutputs` is supposed to jump the discover phase.
      Executing discovery on many projects would be very inefficient.
    */
    mkPackage =
      {
        source,
        name,
        subsystem,
        translator,
        packageOverrides ? {},
        relPath ? "",
        subsystemInfo ? {},
      }:
      let
        outputs = dream2nix.makeOutputs {
          inherit packageOverrides source;
          discoveredProjects = [{
            inherit
              name
              relPath
              subsystem
              subsystemInfo
              translator
              ;
            dreamLockPath = let c = config; in
              "${c.packagesDir}/${subsystem}/${name}/dream-lock.json";
          }];
        };
      in
        outputs.packages.${name};


    nodejsPackages = forAllSystems
      (system: pkgs: {
        mattermost-webapp = (mkOutputs inp.src_mattermost-webapp).packages."@mattermost/webapp";
        mattermost-desktop = (mkOutputs inp.src_mattermost-desktop).packages."mattermost-desktop";
      });

    pythonPackages = forAllSystems
      (system: pkgs: let

        # wrap mkPackage to automatically provide python project spec
        mkPythonPackage = name: args:
          mkPackage (args // {
            inherit name;
            source = inp."src_${name}";
            subsystem = "python";
            translator = "pip";
            subsystemInfo =
              args.subsystemInfo or {}
              // { pythonAttr = args.subsystemInfo.pythonAttr or "python3";};
          });

      in {
        httpie = mkPythonPackage "httpie" {};
        orange3 = mkPythonPackage "orange3" {};
        labelimg = mkPythonPackage "labelimg" {};
        labelme = mkPythonPackage "labelme" {
          subsystemInfo.pythonAttr = "python38";
        };
        urh = mkPythonPackage "urh" {
          subsystemInfo = {
            extraSetupDeps = ["numpy" "cython"];
          };
        };
      });
  in
    l.foldl' l.recursiveUpdate {}
    [
      {
        inherit
          nodejsPackages
          pythonPackages
          ;
        packages.x86_64-linux = pythonPackages.x86_64-linux;
        checks = self.packages;
      }
    ];
}
