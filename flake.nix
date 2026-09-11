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
          pkgs = nixpkgs.legacyPackages.${system};
          tooling = forSystem system;
          php = tooling.php.mkPhp { };
        in
        {
          inherit php;
          composer = php.packages.composer;

          general-lint = tooling.gitHooks.run {
            src = ./.;
            hooks = hooks.presets.general;
          };

          nix-lint = tooling.gitHooks.run {
            src = ./.;
            # Do not invoke nix flake check from inside its own checks.
            hooks = hooks.without [ "nix-flake-check" ] hooks.presets.nix;
          };
        }
        // tooling.scripts
        // lib.mapAttrs' (
          name: bundle:
          lib.nameValuePair "bundle-${name}" (
            pkgs.buildEnv {
              name = "bundle-${name}";
              paths = bundle.packages or [ ];
            }
          )
        ) tooling.bundles
        // lib.mapAttrs' (
          name: preset:
          let
            check = tooling.gitHooks.run {
              src = ./.;
              hooks = preset;
            };
          in
          lib.nameValuePair "hooks-${name}" (
            pkgs.runCommand "hooks-${name}" { nativeBuildInputs = [ pkgs.pre-commit ]; } ''
              export HOME="$TMPDIR"
              # Validate configuration without running consumer scripts or recursive flake checks.
              pre-commit validate-config ${check.config.configFile}
              touch "$out"
            ''
          )
        ) hooks.presets
      );

      devShells = forEachSystem (system: {
        # dogfood this
        default = (forSystem system).mkDevShell {
          src = ./.;

          bundles = [
            "common"
            "nix"
          ];

          hooks = hooks.merge [
            hooks.presets.general
            hooks.presets.nix
          ];
        };
      });
    };
}
