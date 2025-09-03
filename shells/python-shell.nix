# Python Development Shell
# Usage: nix-shell /etc/nixos/shells/python-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "python-dev-shell";
  
  buildInputs = with pkgs; [
    # Python and package management
    python312
    python312Packages.pip
    python312Packages.poetry
    python312Packages.virtualenv
    python312Packages.setuptools
    python312Packages.wheel
    
    # Common Python packages
    python312Packages.requests
    python312Packages.numpy
    python312Packages.pandas
    python312Packages.matplotlib
    python312Packages.jupyter
    python312Packages.ipython
    python312Packages.pytest
    python312Packages.black
    python312Packages.isort
    python312Packages.flake8
    python312Packages.mypy
    
    # Database drivers
    python312Packages.psycopg2
    python312Packages.pymongo
    python312Packages.redis
    
    # Web frameworks
    python312Packages.flask
    python312Packages.django
    python312Packages.fastapi
    python312Packages.uvicorn
    
    # Development tools
    git
    vim
    curl
    jq
  ];
  
  shellHook = ''
    echo "🐍 Python Development Environment"
    echo "Python version: $(python --version)"
    echo "Available tools: pip, poetry, pytest, black, isort, flake8, mypy"
    echo "Web frameworks: Flask, Django, FastAPI"
    echo "Data science: NumPy, Pandas, Matplotlib, Jupyter"
    echo ""
    echo "Quick start:"
    echo "  poetry init         # Initialize new project"
    echo "  python -m venv venv  # Create virtual environment"
    echo "  source venv/bin/activate  # Activate virtual environment"
    echo "  jupyter lab         # Start Jupyter Lab"
    
    # Set up Python environment
    export PYTHONPATH="$PWD:$PYTHONPATH"
    export PIP_PREFIX="$PWD/.pip-packages"
    export PYTHON_PATH="$PIP_PREFIX/lib/python3.12/site-packages:$PYTHON_PATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
  '';
}

