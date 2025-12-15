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
          profile-packages = pkgs.buildEnv {
            name = "profile-packages";
            paths = [
              pkgs.atuin
              pkgs.dnsutils
              pkgs.git-repo
              pkgs.gnupg
              pkgs.gnused
              pkgs.jq
              pkgs.mise
              pkgs.nixd
              pkgs.nixfmt
              pkgs.nixVersions.latest
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
        in
        {
          inherit profile-packages;
        };
    in
    {
      checks = lib.genAttrs systems mkPackages;
      packages = lib.genAttrs systems mkPackages;
    };
}
