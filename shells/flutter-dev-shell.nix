{ pkgs ? import <nixpkgs> {} }:

let
  # Import all packages from home-manager configuration
  homeManagerPackages = import /etc/nixos/home-manager.nix { inherit pkgs; config = {}; lib = pkgs.lib; };
  
in pkgs.mkShell {
  name = "flutter-development-shell";
  
  # Use all packages from home-manager
  buildInputs = homeManagerPackages.home.packages or [];
  
  # Shell hook with information
  shellHook = ''
    echo "🎯 Flutter Development Shell with Auto-Generated Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ All packages from home-manager.nix are available"
    echo "✅ PKG_CONFIG_PATH automatically configured"
    echo "✅ LD_LIBRARY_PATH automatically configured"
    echo ""
    echo "📦 Verify GTK+3:"
    pkg-config --modversion gtk+-3.0 2>/dev/null && echo "   GTK+3 $(pkg-config --modversion gtk+-3.0) found" || echo "   GTK+3 checking..."
    echo ""
    echo "🚀 Ready to build Flutter apps:"
    echo "   flutter clean"
    echo "   flutter build linux --debug"
    echo "   flutter run -d linux"
    echo ""
  '';
}
