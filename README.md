# Dev Tools

Common flake to centralise the pin on my devshells/tooling.

## Usage

This keeps the nixpkgs lock pinned to this projects lock:

```nix
inputs.dev-tools.url = "github:ian-ozzie/nix-dev-tools";
inputs.nixpkgs.follows = "dev-tools/nixpkgs";
```

## PHP settings containing INI syntax

With `mkDevShell`, `php.settings` values are written directly into `php.ini`, and would need manual quotes around values that need them:

```nix
php.settings = {
  "session.save_path" = ''"2;/tmp/php-sessions"'';
};
```

This results in `session.save_path = "2;/tmp/php-sessions"`. Without the quotes, PHP treats the semicolon as a comment and reads only `2`. Trying to handle this while still allowing `2048M` or `E_ALL` unquoted is out of my reach.
