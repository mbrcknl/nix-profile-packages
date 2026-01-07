{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" ];
      nixpkgs-lock = (lib.importJSON ./flake.lock).nodes.nixpkgs;

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
              ln -s "${nixpkgs-flake-registry-json}" "$out/etc/nix/registry.json"
            '';
          };

          nixpkgs-flake-registry-json = pkgs.writers.writeJSON "nixpkgs-flake-registry.json" {
            version = 2;
            flakes = [
              {
                from = {
                  type = "indirect";
                  id = "nixpkgs";
                };
                to = {
                  inherit (nixpkgs-lock.original) ref;
                  inherit (nixpkgs-lock.locked)
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

          profile-packages = pkgs.buildEnv {
            name = "profile-packages";
            paths = [
              nix
              nixpkgs-source
              pkgs.atuin
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

          get-fallback-paths = pkgs.writeShellScriptBin "get-fallback-paths" ''
            ${pkgs.curl}/bin/curl 'https://releases.nixos.org/nix/nix-${nix.version}/fallback-paths.nix'
          '';
        in
        {
          inherit get-fallback-paths profile-packages;
        };
    in
    {
      checks = lib.genAttrs systems mkPackages;
      packages = lib.genAttrs systems mkPackages;
    };
}
