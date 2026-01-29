{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" ];

      packages = lib.genAttrs systems mkPackages;

      nixPaths = lib.mapAttrs (_: p: "${p.nix}") packages;
      nixPathsPretty = lib.generators.toPretty { } nixPaths + "\n";

      nixpkgs-lock = (lib.importJSON ./flake.lock).nodes.nixpkgs.locked;

      flake-registry = {
        version = 2;
        flakes = [
          {
            from = {
              id = "nixpkgs";
              type = "indirect";
            };
            to = {
              inherit (nixpkgs-lock)
                type
                narHash
                owner
                repo
                rev
                ;
            };
          }
        ];
      };

      mkPackages =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix = pkgs.nixVersions.latest;

          # mkdir -p ~/.nix-defexpr/channels ~/.config/nix
          # ln -s ~/.nix-profile/share/nixpkgs ~/.nix-defexpr/channels
          # ln -s ~/.nix-profile/etc/nix/registry.json ~/config/nix
          nixpkgs-source = pkgs.stdenvNoCC.mkDerivation {
            name = "nixpkgs-source";
            buildCommand = ''
              mkdir -p "$out/share" "$out/etc/nix"
              ln -s "${nixpkgs}" "$out/share/nixpkgs"
              ln -s "${flake-registry-json}" "$out/etc/nix/registry.json"
            '';
          };

          flake-registry-json = pkgs.writers.writeJSON "nixpkgs-flake-registry.json" flake-registry;
          fallback-paths = pkgs.writeText "nix-fallback-paths.nix" nixPathsPretty;

          profile-packages = pkgs.buildEnv {
            name = "profile-packages";
            paths = [
              nix
              nixpkgs-source
              pkgs.atuin
              pkgs.gh
              pkgs.git-repo
              pkgs.gnupg
              pkgs.gnused
              pkgs.jq
              pkgs.mise
              pkgs.nerd-fonts.fira-code
              pkgs.nixd
              pkgs.nixfmt
              pkgs.patch
              pkgs.podman
              pkgs.starship
              pkgs.texlive.combined.scheme-full
              pkgs.uv
              pkgs.wget
              pkgs.whois
              pkgs.xz
              pkgs.zstd
            ];
            extraOutputsToInstall = [
              "doc"
              "man"
            ];
          };
        in
        {
          inherit fallback-paths nix profile-packages;
        };
    in
    {
      inherit packages;
      checks = packages;
    };
}
