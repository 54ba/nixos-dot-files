# TypeScript/Node.js Development Shell
# Usage: nix-shell /etc/nixos/shells/typescript-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "typescript-dev-shell";
  
  buildInputs = with pkgs; [
    # Node.js and package managers
    nodejs_20  # LTS version
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    
    # TypeScript and development tools
    nodePackages.typescript
    
    # Linting and formatting

    nodePackages.prettier
    
    # Build tools
    nodePackages.webpack
    nodePackages.webpack-cli
        
    # Utility tools
    nodePackages.nodemon
    nodePackages.concurrently
    nodePackages.dotenv-cli
    
    # Development tools
    git
    curl
    jq
  ];
  
  shellHook = ''
    echo "⚡ TypeScript/Node.js Development Environment"
    echo "Node.js version: $(node --version)"
    echo "NPM version: $(npm --version)"
    echo "TypeScript version: $(tsc --version)"
    echo "Available package managers: npm, yarn, pnpm"
    echo "Build tools: webpack, rollup, esbuild"
    echo ""
    echo "Quick start:"
    echo "  npm init -y                    # Initialize package.json"
    echo "  tsc --init                     # Initialize TypeScript config"
    echo "  npx create-react-app my-app    # Create React app"
    echo "  npx create-next-app my-app     # Create Next.js app"
    
    # Set up Node environment
    export NODE_ENV="development"
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    export PATH="$PWD/.npm-global/bin:$PATH"
    export PATH="$PWD/node_modules/.bin:$PATH"
  '';
}

