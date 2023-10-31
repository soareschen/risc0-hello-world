{
  description = "Nix development dependencies for ibc-rs";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
    rust-overlay.url = github:oxalica/rust-overlay;

    risc0-rust = {
      url = "https://github.com/risc0/rust/releases/download/test-release-2/rust-toolchain-x86_64-unknown-linux-gnu.tar.gz";
      flake = false;
    };
  };

  outputs = inputs: let
    utils = inputs.flake-utils.lib;
  in
    utils.eachSystem
    [
      "x86_64-linux"
    ]
    (system: let
      nixpkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.rust-overlay.overlays.default
        ];
      };

      hello-guest = nixpkgs.rustPlatform.buildRustPackage
      ;
    in {
      packages = {
      };
    });
}
