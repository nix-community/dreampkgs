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
    
    # rust sources
    src_zellij.url = "github:zellij-org/zellij/v0.30.0";
    src_zellij.flake = false;
    src_ripgrep.url = "github:burntsushi/ripgrep/13.0.0";
    src_ripgrep.flake = false;
    src_amber.url = "github:dalance/amber/v0.5.9";
    src_amber.flake = false;
    src_eureka.url = "github:simeg/eureka/v2.0.0";
    src_eureka.flake = false;
    src_resvg.url = "github:RazrFalcon/resvg/v0.23.0";
    src_resvg.flake = false;
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
      (system: f system nixpkgs.legacyPackages.${system});

    config = {
      repoName = "dreampkgs";
      projectRoot = ./.;
      packagesDir = "dream2nix-packages";
      disableIfdWarning = true;
    };

    dream2nixFor = forAllSystems (system: pkgs:
      inp.dream2nix.lib.init {
        pkgs = inp.nixpkgs.legacyPackages.${system};
        inherit config;
      }
    );

    mkOutputsFor = forAllSystems (system: pkgs:
      attrs: dream2nixFor.${system}.makeOutputs (
        if l.isAttrs attrs && (! attrs ? outPath)
        then attrs
        else {source = attrs;}
      )
    );

    /*
      # FIXME:
      This wrapper for `makeOutputs` is supposed to jump the discover phase.
      Executing discovery on many projects would be very inefficient.
    */
    mkPackageFor = forAllSystems (system: pkgs:
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
        outputs = dream2nixFor.${system}.makeOutputs {
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
        outputs.packages.${name}
    );


    nodejsPackages = forAllSystems
      (system: pkgs: {
        mattermost-webapp = (mkOutputsFor.${system} inp.src_mattermost-webapp).packages."@mattermost/webapp";
        mattermost-desktop = (mkOutputsFor.${system} inp.src_mattermost-desktop).packages."mattermost-desktop";
      });

    pythonPackages = forAllSystems
      (system: pkgs: let

        # wrap mkPackage to automatically provide python project spec
        mkPythonPackage = name: args:
          mkPackageFor.${system} (args // {
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
      
    rustPackages =
      forAllSystems (system: pkgs:
        let
          mkPackageFor = src: name:
            (mkOutputsFor.${system} {
              source = src;
              settings = [{builder = "crane";}];
            }).packages.${name};
        in
          l.genAttrs
          ["zellij" "ripgrep" "amber" "resvg" "eureka"]
          (name: mkPackageFor inp."src_${name}" name)
      );
  in
    l.foldl' l.recursiveUpdate {}
    [
      {
        inherit
          nodejsPackages
          pythonPackages
          rustPackages
          ;
        packages = forAllSystems (system: pkgs:
          pythonPackages.${system}
          // rustPackages.${system}
        );
        checks = self.packages;
      }
    ];
}
