{ lib, pkgs }:
rec {
  scripts = {
    nix-dev-mailhog = pkgs.writeShellApplication {
      name = "nix-dev-mailhog";
      runtimeInputs = [ pkgs.mailhog ];

      text = ''
        exec MailHog \
          -api-bind-addr=127.0.0.1:8025 \
          -smtp-bind-addr=127.0.0.1:1025 \
          -ui-bind-addr=127.0.0.1:8025 \
          -storage=maildir \
          -maildir-path=database/dev.mailhog \
          > storage/logs/mailhog.log 2> storage/logs/mailhog.err
      '';
    };

    nix-dev-redis = pkgs.writeShellApplication {
      name = "nix-dev-redis";
      runtimeInputs = [ pkgs.redis ];

      text = ''
        exec redis-server \
          --dir ./database \
          --dbfilename dev.rdb \
          --daemonize no \
          --bind 127.0.0.1
      '';
    };
  };

  bundles = {
    common = {
      packages = [
        pkgs.jq
        pkgs.xc
      ];
    };

    nix = {
      packages = [ pkgs.nixd ];
    };

    node = {
      packages = [ pkgs.nodejs_24 ];
    };

    services = {
      packages = [
        pkgs.mailhog
        pkgs.redis
        scripts.nix-dev-mailhog
        scripts.nix-dev-redis
      ];
    };
  };

  mergeBundles =
    names:
    let
      unknown = lib.filter (name: !(bundles ? ${name})) names;

      selected =
        lib.throwIf (unknown != [ ])
          "mergeBundles: no bundle named ${lib.concatStringsSep ", " unknown} (have ${lib.concatStringsSep ", " (lib.attrNames bundles)})"
          (lib.attrVals names bundles);
    in
    {
      env = lib.foldl' (acc: bundle: acc // (bundle.env or { })) { } selected;

      packages = lib.concatMap (bundle: bundle.packages or [ ]) selected;

      shellHook = lib.concatStringsSep "\n" (
        lib.filter (hook: hook != "") (map (bundle: bundle.shellHook or "") selected)
      );
    };
}
