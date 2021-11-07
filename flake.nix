{
  description = "A collection of software packages managed with dream2nix";

  inputs = {
    dream2nix.url = "path:///home/grmpf/projects/github/dream2nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    dream2nix,
  }@inp:
  let

    l = nixpkgs.lib // builtins;

    supportedSystems = [ "x86_64-linux" ];

    forAllSystems = f: l.genAttrs supportedSystems
      (system: f system (import nixpkgs { inherit system; }));

    dream2nix = inp.dream2nix.lib.init {
      systems = supportedSystems;
      config = {
        overridesDirs = [ ./overrides ];
        packagesDir = "./packages";
        repoName = "dreampkgs";
      };
    };

    dreampkgs = forAllSystems
      (system: pkgs:
        l.genAttrs
          (l.attrNames (l.readDir ./packages))
          (pname:
            let
              outputs = dream2nix.riseAndShine {
                dreamLock = "${./.}/packages/${pname}/dream-lock.json";
              };
            in
              outputs.defaultPackage."${system}"
              // {
                packages = outputs.packages."${system}";
              }));
  in
    l.foldl' l.recursiveUpdate {}
    [
      {
        apps = dream2nix.apps;
        defaultApp = dream2nix.defaultApp;
        packages = dreampkgs;
      }
    ];
}