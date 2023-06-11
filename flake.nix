{
  inputs = {
    # Need Dart 2.x -> 22.11
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    nix-dart.url = "github:tadfisher/nix-dart";
    nix-dart.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, nix-dart }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Seems `pub` was previously a separate binary but is now a subcommand of `dart`
        # dart2nix still requires `pub` as a separate command
        pub = pkgs.writeShellScriptBin "pub" ''
          ${pkgs.dart}/bin/dart pub "$@"
        '';
        tools = nix-dart.builders.${system}.buildDartPackage {
          pname = "craftinginterpreters-tools";
          version = "1.0";
          src = ./tool;
          specFile = ./tool/pubspec.yaml;
          lockFile = ./tool/pub2nix.lock;
          buildInputs = [ pub ];
        };
        # `test.dart` expects to be run in the root directory of the book repository
        lox-test = pkgs.writeShellScriptBin "lox-test" ''
          cd ${./.}
          exec ${tools}/bin/lox-test "$@"
        '';
        tools-fixed = pkgs.symlinkJoin {
          name = "craftinginterpreters-tools";
          paths = [ lox-test ];
        };
      in {
        packages.craftinginterpreters-tools = tools-fixed;
        devShell = with pkgs;
          mkShell {
            buildInputs = [
              #
              nix-dart.packages.${system}.pub2nix-lock
              tools-fixed
            ];
          };
      });
}
