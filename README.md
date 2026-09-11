# Dev Tools

Common flake to centralise the pin on my devshells/tooling.

## Usage

This keeps the nixpkgs lock pinned to this projects lock:

```nix
inputs.dev-tools.url = "github:ian-ozzie/nix-dev-tools";
inputs.nixpkgs.follows = "dev-tools/nixpkgs";
```

## PHP settings containing INI syntax

With `mkDevShell`, `php.settings` values are written directly into `php.ini`, and would need manual
quotes around values that need them:

```nix
php.settings = {
  "session.save_path" = ''"2;/tmp/php-sessions"'';
};
```

This results in `session.save_path = "2;/tmp/php-sessions"`. Without the quotes, PHP treats the
semicolon as a comment and reads only `2`. Trying to handle this while still allowing `2048M` or
`E_ALL` unquoted is out of my reach.

## Tasks

### lock

Lock flake inputs

```bash
nix flake lock
```

### update

Update all/specific input

Inputs: INPUT

Environment: INPUT=

```bash
nix flake update $INPUT
```

### check

Check flake outputs

```bash
nix flake check
```

### inputs

Check flake inputs

```bash
nix flake metadata
```

### php-extensions

List available PHP extensions

Inputs: VERSION

Environment: VERSION=php85

```bash
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}.'"$VERSION"'.extensions' --apply 'e: builtins.concatStringsSep "\n" (builtins.attrNames e)'
```
