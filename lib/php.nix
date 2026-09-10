{ lib, pkgs }:
rec {
  defaultExtensions = [
    "redis"
    "xdebug"
  ];

  defaultVersion = "php85";

  defaultSettings = {
    "display_errors" = "stderr";
    "display_startup_errors" = "On";
    "error_reporting" = "E_ALL";
    "log_errors" = "On";
    "log_errors_max_len" = "0";
    "memory_limit" = "2048M";
    "xdebug.client_host" = "127.0.0.1";
    "xdebug.client_port" = "9003";
    "xdebug.log_level" = "0";
    "xdebug.mode" = "develop,debug,coverage";
    "xdebug.start_with_request" = "trigger";
    "xdebug.trigger_value" = "dev-tools";
  };

  mkPhp =
    {
      extensions ? defaultExtensions,
      settings ? { },
      version ? defaultVersion,
    }:
    let
      php = pkgs.${version} or (throw "mkPhp: nixpkgs has no PHP package named '${version}'");

      renderValue =
        name: value:
        if builtins.isBool value then
          (if value then "On" else "Off")
        else if builtins.isString value || builtins.isInt value then
          toString value
        else
          throw "mkPhp: setting '${name}' must be a string, int, bool, or null";
    in
    php.buildEnv {
      extensions =
        { all, enabled, ... }:
        let
          unknown = lib.filter (name: !(all ? ${name})) extensions;
        in
        lib.throwIf (unknown != [ ])
          "mkPhp: ${version} has no extension ${lib.concatStringsSep ", " unknown}"
          (enabled ++ lib.attrVals extensions all);

      # the settings attrset as php.ini, a null value dropping a key
      extraConfig = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "${name} = ${renderValue name value}") (
          lib.filterAttrs (_: value: value != null) (defaultSettings // settings)
        )
      );
    };
}
