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
            nodejs_18
            yarn
            hexo-cli
          ];
          shellHook = ''
            cd blog
            yarn
            # First generate with relative path
            hexo generate
            # Replace CSS path to absolute for font-spider
            ABSOLUTE_PATH=$(pwd)
            sed -i.bak "s|<%- css('css/style') %>|<%- css('$ABSOLUTE_PATH/public/css/style.css') %>|g" themes/cactus-light/layout/_partial/head.ejs
            hexo generate
            # Run font-spider
            npx font-spider --ignore "font-awesome\.css$,bootstrap\.min\.css$" public/**/*.html
            # Restore original CSS path
            mv themes/cactus-light/layout/_partial/head.ejs.bak themes/cactus-light/layout/_partial/head.ejs
            # Generate final version
            hexo generate
            hexo server
          '';
        };
      });
    };
}
