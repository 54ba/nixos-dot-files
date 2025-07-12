# Python Development Shell
# Usage: nix-shell /etc/nixos/shells/python-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "python-dev-shell";
  
  buildInputs = with pkgs; [
    # Python and package management
    python311
    python311Packages.pip
    python311Packages.poetry
    python311Packages.virtualenv
    python311Packages.setuptools
    python311Packages.wheel
    
    # Common Python packages
    python311Packages.requests
    python311Packages.numpy
    python311Packages.pandas
    python311Packages.matplotlib
    python311Packages.jupyter
    python311Packages.ipython
    python311Packages.pytest
    python311Packages.black
    python311Packages.isort
    python311Packages.flake8
    python311Packages.mypy
    
    # Database drivers
    python311Packages.psycopg2
    python311Packages.pymongo
    python311Packages.redis
    
    # Web frameworks
    python311Packages.flask
    python311Packages.django
    python311Packages.fastapi
    python311Packages.uvicorn
    
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
    export PYTHON_PATH="$PIP_PREFIX/lib/python3.11/site-packages:$PYTHON_PATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
  '';
}

