{
  description = "My flake with dream2nix packages";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
    crab-fit.url = "github:GRA0007/crab.fit";
    crab-fit.flake = false;
  };

  outputs = inputs @ {
    self,
    dream2nix,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
  in {
    # all packages defined inside ./packages/
    packages.${system} = dream2nix.lib.importPackages {
      projectRoot = ./.;
      # can be changed to ".git" or "flake.nix" to get rid of .project-root
      projectRootFile = "flake.nix";
      packagesDir = ./packages;
      packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
      packageSets.dreampkgs = self.packages.${system};
      specialArgs = {inherit inputs;};
    };
    checks.${system} =
      builtins.mapAttrs
      (_: p: p // {inherit system;})
      self.packages.${system};
  };
}
