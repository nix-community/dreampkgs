{
  description = "A collection of software packages managed with dream2nix";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
    crab-fit.url = "github:GRA0007/crab.fit";
    crab-fit.flake = false;
    logchecker.url = "github:OPSnet/Logchecker/0.11.1";
    logchecker.flake = false;
  };

  outputs = inputs @ {
    self,
    dream2nix,
    nixpkgs,
    ...
  }: let
    eachSystem = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  in {
    # all packages defined inside ./packages/
    packages = eachSystem (system: dream2nix.lib.importPackages {
      projectRoot = ./.;
      # can be changed to ".git" or "flake.nix" to get rid of .project-root
      projectRootFile = "flake.nix";
      packagesDir = ./packages;
      packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
      packageSets.dreampkgs = self.packages.${system};
      specialArgs = {inherit inputs;};
    });
    checks = eachSystem (system:
      builtins.mapAttrs
        (_: p: p // {inherit system;})
        self.packages.${system});
  };
}
