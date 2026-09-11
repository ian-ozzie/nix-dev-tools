{ lib }:
let
  prettierTypes = [
    "css"
    "graphql"
    "html"
    "javascript"
    "json"
    "jsx"
    "less"
    "markdown"
    "scss"
    "ts"
    "tsx"
    "vue"
    "yaml"
  ];

  checkNames =
    fn: names: preset:
    let
      unknown = lib.filter (name: !(preset ? ${name})) names;
    in
    lib.throwIf (unknown != [ ])
      "hooks.${fn}: no hook named ${lib.concatStringsSep ", " unknown} (have ${lib.concatStringsSep ", " (lib.attrNames preset)})"
      names;
in
{
  merge = lib.foldl' lib.recursiveUpdate { };
  select = names: preset: lib.getAttrs (checkNames "select" names preset) preset;
  without = names: preset: removeAttrs preset (checkNames "without" names preset);

  presets = {
    general = {
      check-case-conflicts.enable = true;
      check-symlinks.enable = true;
      detect-private-keys.enable = true;

      check-merge-conflicts = {
        enable = true;
        args = [ "--assume-in-merge" ];
      };

      prettier = {
        enable = true;
        name = "Prettier format";
        types_or = prettierTypes;
      };
    };

    nix = {
      deadnix.enable = true;
      nixfmt.enable = true;
      statix.enable = true;

      nix-flake-check = {
        enable = true;
        entry = "nix flake check";
        files = "\\.nix$|^flake\\.lock$";
        pass_filenames = false;
        stages = [ "pre-push" ];
      };
    };

    php = {
      npm-build = {
        enable = true;
        entry = "npm run build";
        name = "Tailwind CSS compile";
        pass_filenames = false;
        types_or = [ "css" ];
      };

      npm-lint = {
        enable = true;
        entry = "npm run lint:fix";
        name = "Prettier format";
        pass_filenames = false;

        types_or = prettierTypes;
      };

      npm-static = {
        enable = true;
        entry = "npm run static:fix";
        excludes = [ "(^|/)vendor/" ];
        name = "ESLint";
        pass_filenames = false;

        types_or = [
          "javascript"
          "jsx"
          "ts"
          "tsx"
        ];
      };

      npm-style = {
        enable = true;
        entry = "npm run style:fix";
        name = "Stylelint format";
        pass_filenames = false;
        types_or = [ "css" ];
      };

      php-lint = {
        enable = true;
        entry = "composer run lint:fix";
        name = "Pint format";
        types_or = [ "php" ];
      };

      php-static = {
        enable = true;
        entry = "composer run static:check:fresh";
        excludes = [ "^tests/|^config/|\\.blade\\.php$|^modules/[^/]*/tests/" ];
        name = "PHPStan";
        pass_filenames = false;
        types_or = [ "php" ];
      };

      php-test = {
        enable = true;
        entry = "composer run test:coverage";
        name = "Pest test";
        pass_filenames = false;
        types_or = [ "php" ];
      };
    };
  };
}
