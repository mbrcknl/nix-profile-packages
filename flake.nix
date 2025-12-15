{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" ];

      mkPackages =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix = pkgs.nixVersions.latest;
          profile-packages = pkgs.buildEnv {
            name = "profile-packages";
            paths = [
              nix
              pkgs.atuin
              pkgs.git-repo
              pkgs.gnupg
              pkgs.gnused
              pkgs.jq
              pkgs.mise
              pkgs.nixd
              pkgs.nixfmt
              pkgs.patch
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
