{
  description = "Bracket Lab bracket pool Rails app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Ruby runtime
            ruby_3_4

            # JavaScript runtime
            bun

            # Native extension dependencies
            libyaml
            sqlite

            # Build tools for native gems
            pkg-config
            gcc
            gnumake

            # Playwright browsers for system tests (version must match gem)
            playwright-driver.browsers
          ];

          shellHook = ''
            # Help bundler find native libraries for gem compilation
            export PKG_CONFIG_PATH="${pkgs.libyaml.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"

            # Runtime library path for gems with native extensions (e.g., psych needs libyaml)
            export LD_LIBRARY_PATH="${pkgs.libyaml}/lib:$LD_LIBRARY_PATH"

            # Use user-installed gems
            export GEM_HOME="$HOME/.local/share/gem/ruby/3.4.0"
            export PATH="$GEM_HOME/bin:$PATH"

            # Use bundler 4.x to avoid constant redefinition warnings.
            # Keep in sync with bundler version in Gemfile.
            export BUNDLER_VERSION="4.0.5"

            # Install bundler if not present or wrong version
            if ! gem list bundler -i -v 4.0.5 > /dev/null 2>&1; then
              echo "Installing bundler 4.0.5..."
              gem install bundler -v 4.0.5 --no-document
            fi

            # Point Playwright to nix-managed browsers
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
          '';
        };
      });
}
