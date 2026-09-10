{
  description = "Shared devshell/tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
  };

  outputs =
    { git-hooks, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      forEachSystem = lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      hooks = import ./lib/hooks.nix { inherit lib; };

      forSystem =
        system:
        let
          gitHooks = git-hooks.lib.${system};
          packageLib = import ./lib/packages.nix { inherit lib pkgs; };
          phpLib = import ./lib/php.nix { inherit lib pkgs; };
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          inherit gitHooks;
          inherit (packageLib) bundles mergeBundles scripts;

          php = phpLib;

          mkDevShell = import ./lib/shell.nix {
            inherit
              gitHooks
              lib
              packageLib
              phpLib
              pkgs
              ;
          };
        };
    in
    {
      lib = { inherit forSystem hooks; };

      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);

      checks = forEachSystem (
        system:
        let
          tooling = forSystem system;
        in
        {
          nix-lint = tooling.gitHooks.run {
            src = ./.;
            # Do not invoke nix flake check from inside its own checks.
            hooks = hooks.without [ "nix-flake-check" ] hooks.presets.nix;
          };

          inherit (tooling.scripts) nix-dev-mailhog nix-dev-redis;
        }
      );

      devShells = forEachSystem (system: {
        # dogfood this
        default = (forSystem system).mkDevShell {
          src = ./.;

          bundles = [
            "common"
            "nix"
          ];

          hooks = hooks.presets.nix;
        };
      });
    };
}
