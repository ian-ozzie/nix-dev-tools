{
  gitHooks,
  lib,
  packageLib,
  phpLib,
  pkgs,
}:
{
  src,

  bundles ? [ "common" ],
  env ? { },
  hooks ? { },
  packages ? [ ],
  php ? null,
  shellHook ? "",
}:
let
  checks = gitHooks.run { inherit hooks src; };
  hooksEnabled = lib.any (hook: hook.enable) (lib.attrValues checks.config.hooks);
  phpEnv = if php == null then null else phpLib.mkPhp php;
  selected = packageLib.mergeBundles bundles;
in
pkgs.mkShell {
  env = selected.env // env;

  packages =
    lib.optionals (php != null) [
      phpEnv
      phpEnv.packages.composer
    ]
    ++ selected.packages
    ++ packages
    ++ checks.enabledPackages;

  passthru = {
    inherit checks;
    php = phpEnv;
  };

  shellHook = lib.concatStringsSep "\n" (
    lib.filter (hook: hook != "") [
      selected.shellHook
      shellHook
      (lib.optionalString hooksEnabled checks.shellHook)
    ]
  );
}
