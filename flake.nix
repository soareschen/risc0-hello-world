{
  description = "Nix development dependencies for ibc-rs";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
    rust-overlay.url = github:oxalica/rust-overlay;

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

        rust-bin = nixpkgs.rust-bin.stable.latest.complete;

        risc0-rust-tarball = builtins.fetchurl {
          url = "https://github.com/risc0/rust/releases/download/test-release-2/rust-toolchain-x86_64-unknown-linux-gnu.tar.gz";
          sha256 = "sha256:1nqgpx6ww0rla5c4jzam6fr43v6lf0flsj572racjqwq9xk86l4a";
        };

        risc0-rust = nixpkgs.stdenv.mkDerivation {
            name = "risc0-rust";

            unpackPhase = "true";

            nativeBuildInputs = [
                rust-bin
                nixpkgs.zlib
                nixpkgs.autoPatchelfHook
            ];

            dontBuild = true;

            installPhase = ''
                mkdir -p $out
                cd $out
                tar xzf ${risc0-rust-tarball}
                chmod +x bin/*
                runHook postInstall
            '';
        };

        hello-guest = nixpkgs.rustPlatform.buildRustPackage {
            name = "hello-guest";

            src = ./.;

            buildAndTestSubdir = "guest";

            cargoSha256 = "sha256-VFABeUFCQ5nxAoHIv9zVqh1h+kXLdu/ymUTtmqh9niw=";

            nativeBuildInputs = [
                rust-bin
                nixpkgs.lld
            ];

            doCheck = false;

            buildPhase = ''
                RUSTC=${risc0-rust}/bin/rustc \
                    CARGO_ENCODED_RUSTFLAGS=$'-C\x1fpasses=loweratomic\x1f-C\x1flink-arg=-Ttext=0x00200800\x1f-C\x1flink-arg=--fatal-warnings\x1f-C\x1fpanic=abort\x1f-C\x1flinker=lld' \
                    cargo build --release --target riscv32im-risc0-zkvm-elf -p risc0-guest
            '';

            installPhase = ''
                mkdir -p $out
                cp target/riscv32im-risc0-zkvm-elf/release/risc0-guest $out/
            '';
        };
    in {
      packages = {
        inherit risc0-rust hello-guest;
      };
    });
}
