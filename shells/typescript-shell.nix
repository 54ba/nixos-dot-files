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
    nodePackages.ts-node
    nodePackages.tsx  # TypeScript execution engine
    nodePackages."@types/node"
    
    # Linting and formatting
    nodePackages.eslint
    nodePackages.prettier
    nodePackages."@typescript-eslint/eslint-plugin"
    nodePackages."@typescript-eslint/parser"
    
    # Build tools
    nodePackages.webpack
    nodePackages.webpack-cli
    nodePackages.vite
    nodePackages.rollup
    nodePackages.esbuild
    
    # Testing frameworks
    nodePackages.jest
    nodePackages.mocha
    nodePackages.vitest
    
    # Web frameworks and libraries
    nodePackages."@angular/cli"
    nodePackages."create-react-app"
    nodePackages."@vue/cli"
    nodePackages."create-next-app"
    
    # Utility tools
    nodePackages.nodemon
    nodePackages.concurrently
    nodePackages.dotenv-cli
    
    # Development tools
    git
    vim
    curl
    jq
  ];
  
  shellHook = ''
    echo "⚡ TypeScript/Node.js Development Environment"
    echo "Node.js version: $(node --version)"
    echo "NPM version: $(npm --version)"
    echo "TypeScript version: $(tsc --version)"
    echo "Available package managers: npm, yarn, pnpm"
    echo "Build tools: webpack, vite, rollup, esbuild"
    echo "Testing: jest, mocha, vitest"
    echo "Frameworks: Angular CLI, Create React App, Vue CLI, Next.js"
    echo ""
    echo "Quick start:"
    echo "  npm init -y                    # Initialize package.json"
    echo "  tsc --init                     # Initialize TypeScript config"
    echo "  npx create-react-app my-app    # Create React app"
    echo "  npx create-next-app my-app     # Create Next.js app"
    echo "  ng new my-app                  # Create Angular app"
    echo "  vue create my-app              # Create Vue app"
    
    # Set up Node environment
    export NODE_ENV="development"
    export NPM_CONFIG_PREFIX="$PWD/.npm-global"
    export PATH="$PWD/.npm-global/bin:$PATH"
    export PATH="$PWD/node_modules/.bin:$PATH"
  '';
}

