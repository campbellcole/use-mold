# use-mold

`use-mold` is a Nix utility for writing a `.cargo/config.toml` that points to a [`mold`](https://github.com/rui314/mold) binary in the Nix store.

## Usage

In your `flake.nix` that defines a devshell:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    use-mold.url = "github:campbellcole/use-mold";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, use-mold }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        # useMoldHook returns a function that accepts the mold package
        moldHook = use-mold.useMoldHook {
          # all attributes are optional and their default values are shown here
          cargoConfigDir = "$PWD/.cargo";
          
          # the `linker` attribute is the full path to the mold binary
          configTemplate = ({ linker }: ''
            [target.x86_64-unknown-linux-gnu]
            linker = "clang"
            rustflags = ["-C", "link-arg=-fuse-ld=${linker}"]
          '');

          # extra shell hook code to include after the mold hook
          extraShellHook = "";
          
          # setting this to false will cause the config to become invalid when mold updates!
          # it is recommended to leave this as true
          force = true;

          # usually, calling useMoldHook with an empty attrset suffices:
          # moldHook = use-mold.useMoldHook {};
        };
        # you can also apply both arguments here if preferred:
        moldShellHook = use-mold.useMoldHook {} pkgs.mold;
      in
      with pkgs;
      {
        devShells.default = mkShell rec {
          nativeBuildInputs = [
            pkg-config
            clang
          ];

          buildInputs = [
            (rust-bin.nightly.latest.override {
              components = [ "rust-src" "rust-analyzer" "rustc" "cargo" "clippy" ];
            })
          ];

          LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;

          RUST_BACKTRACE = 1;

          # `moldHook mold` would work here because we `with pkgs;` but just to exemplify
          # what the argument its expecting is:
          shellHook = moldHook pkgs.mold;

          # if you prefer the second style, you would use:
          # shellHook = moldShellHook;
        };
      }
    );
}
```
