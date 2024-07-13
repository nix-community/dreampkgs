[dreampkgs](https://github.com/nix-community/dreampkgs)
is a collection of software packages managed with
[dream2nix](https://github.com/nix-community/dream2nix), a framework for automated packaging.

Both dream2nix and dreampkgs are unstable at this point.

The goal of this repo is to test and improve dream2nix.

For a list of CI jobs see here:
[buildbot.nix-community.org: dreampkgs]( https://buildbot.nix-community.org/#/projects/2)
To interact with the CLI, use nix 2.4+ with enabled experimental features nix-command + flakes.

# Packaging workflow

### clone repo
```shell
git clone https://github.com/nix-community/dreampkgs
cd dreampkgs
```

### list existing packages
```shell
nix flake show
```

### build a package
```shell
nix build .#{package-name}
```

# Developing/Debugging dream2nix
## Use dreampkgs with a local checkout of dream2nix
Temporarily override the dream2nix input of dreampkgs via:
```shell
nix flake lock --override-input dream2nix path:///$HOME/path/to/dream2nix
```
This command needs to be re-executed after each change on dream2nix.
