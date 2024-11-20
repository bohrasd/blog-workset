{
  description = "Example JavaScript development environment for Zero to Nix";

  # Flake inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

  };

  # Flake outputs
  outputs = { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      # Development environment output
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          # The Nix packages provided in the environment
          packages = with pkgs; [
            nodejs_18 # Node.js 18, plus npm, npx, and corepack
            nodePackages.node2nix
            yarn
            hexo-cli
          ];
          shellHook = ''
            cd blog
            yarn
            hexo generate
            font-spider --ignore "font-awesome\.css$,bootstrap\.min\.css$" public/**/*.html
            mv themes/cactus-light/layout/_partial/head.ejs themes/cactus-light/layout/_partial/head.ejs.2
            cp themes/cactus-light/layout/_partial/head.ejs.1 themes/cactus-light/layout/_partial/head.ejs
            hexo generate
            hexo server
          '';
        };
      });
    };
}
