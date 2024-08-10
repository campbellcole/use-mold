{
  description = "A utility for using the mold linker for Nix flake devshells that use Rust.";

  outputs = { ... }:
    let
      defaultConfigTemplate = { linker }: ''
        [target.x86_64-unknown-linux-gnu]
        linker = "clang"
        rustflags = ["-C", "link-arg=-fuse-ld=${linker}"]
      '';
    in
    {
      useMoldHook =
        { cargoConfigPath ? "$PWD/.cargo/config.toml"
        , configTemplate ? defaultConfigTemplate
        , extraShellHook ? ""
        # force being set to true is highly recommended, otherwise when the mold path changes, the cargo config becomes invalid.
        # since users can set the template, there should be no reason to set this to false
        , force ? true
        }:
        mold:
        let
          cargoConfig = configTemplate { linker = "${mold}/bin/mold"; };
        in
        ''
          # if the cargo config doesn't exist or force is `true`, then write the config
          if [[ ! -f "${cargoConfigPath}" ]] || ${force}; then
            cat > ${cargoConfigPath} <<EOF
            ${cargoConfig}
            EOF
          fi

          ${extraShellHook}
        '';
    };
}
