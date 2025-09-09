{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "automation-development-shell";
  
  buildInputs = with pkgs; [
    # ===== CORE AUTOMATION PLATFORMS =====
    
    # Workflow orchestration engines
    n8n                              # Self-hosted workflow automation
    nodePackages.node-red            # Visual programming for IoT and APIs
    
    # ===== SCRIPTING LANGUAGES & RUNTIMES =====
    
    # Python ecosystem for automation
    python3
    python3Packages.pip
    python3Packages.virtualenv
    # python3Packages.pipenv  # Not available in current nixpkgs
    poetry
    
    # Essential Python packages for automation
    python3Packages.requests          # HTTP library
    python3Packages.httpx             # Async HTTP library
    python3Packages.aiohttp           # Async HTTP client/server
    python3Packages.urllib3           # HTTP client library
    python3Packages.pyyaml            # YAML parser
    python3Packages.toml              # TOML parser
    python3Packages.click             # Command line interfaces
    python3Packages.typer             # Modern CLI framework
    python3Packages.rich              # Rich terminal formatting
    python3Packages.schedule          # Job scheduling
    python3Packages.celery            # Distributed task queue
    python3Packages.redis             # Redis client
    python3Packages.psycopg2          # PostgreSQL adapter
    python3Packages.pymongo           # MongoDB client
    python3Packages.sqlalchemy       # SQL toolkit
    python3Packages.alembic           # Database migrations
    python3Packages.fastapi           # Modern API framework
    python3Packages.uvicorn           # ASGI server
    python3Packages.pydantic          # Data validation
    python3Packages.jinja2            # Template engine
    
    # Web scraping and browser automation
    python3Packages.selenium          # Browser automation
    python3Packages.beautifulsoup4    # HTML/XML parser
    python3Packages.scrapy            # Web crawling framework
    python3Packages.playwright        # Modern browser automation
    
    # Data processing
    python3Packages.pandas            # Data manipulation
    python3Packages.numpy             # Numerical computing
    python3Packages.matplotlib        # Plotting library
    
    # Node.js ecosystem for automation
    nodejs
    # npm  # npm comes with nodejs package
    yarn
    pnpm
    nodePackages.pm2                  # Process manager
    nodePackages.nodemon              # File watcher
    nodePackages.concurrently         # Run commands concurrently
    nodePackages.ts-node              # TypeScript execution
    nodePackages.typescript           # TypeScript compiler
    nodePackages.eslint               # JavaScript linter
    nodePackages.prettier             # Code formatter
    
    # Shell scripting
    bash
    zsh
    fish
    powershell                        # Cross-platform PowerShell
    
    # ===== API DEVELOPMENT & TESTING =====
    
    # HTTP clients
    curl
    wget
    httpie                            # User-friendly HTTP client
    
    # API testing tools
    postman                           # API development environment
    insomnia                          # REST client
    newman                            # Postman CLI runner
    
    # JSON/YAML processing
    jq                                # Command-line JSON processor
    yq-go                             # YAML processor
    fx                                # Interactive JSON viewer
    
    # ===== DATABASE TOOLS =====
    
    # Database clients
    postgresql                        # PostgreSQL client
    sqlite                            # SQLite database
    redis                             # Redis CLI
    
    # Database management
    pgcli                             # Better PostgreSQL CLI
    litecli                           # Better SQLite CLI
    
    # ===== CONTAINER & ORCHESTRATION =====
    
    # Container tools
    docker
    docker-compose
    podman
    buildah
    
    # Kubernetes tools
    kubectl
    kubernetes-helm
    k9s                               # Kubernetes TUI
    kubectx                           # Context switcher
    stern                             # Multi-pod log tailing
    
    # ===== CLOUD & INFRASTRUCTURE =====
    
    # Cloud provider CLIs
    awscli2                           # AWS CLI
    azure-cli                         # Azure CLI
    google-cloud-sdk                  # Google Cloud CLI
    
    # Infrastructure as Code
    terraform                         # Infrastructure provisioning
    terragrunt                        # Terraform wrapper
    ansible                           # Configuration management
    
    # ===== VERSION CONTROL & CI/CD =====
    
    # Git and related tools
    git
    gh                                # GitHub CLI
    glab                              # GitLab CLI
    git-lfs                           # Large file storage
    git-crypt                         # Repository encryption
    
    # CI/CD tools
    gitlab-runner                     # GitLab CI/CD runner
    act                               # Run GitHub Actions locally
    
    # ===== MONITORING & OBSERVABILITY =====
    
    # System monitoring
    htop                              # Interactive process viewer
    iotop                             # I/O monitoring
    nethogs                           # Network usage per process
    
    # Network tools
    nmap                              # Network discovery
    netcat                            # Networking utility
    socat                             # Socket relay
    tcpdump                           # Packet analyzer
    wireshark-cli                     # Network protocol analyzer
    
    # ===== SECURITY & DEBUGGING =====
    
    # HTTP debugging and proxying
    mitmproxy                         # Interactive HTTP proxy
    burpsuite                         # Web security testing
    
    # Tunneling and exposure
    ngrok                             # Secure tunneling
    
    # Secret management
    sops                              # Encrypted secrets
    age                               # Modern encryption
    pass                              # Password manager
    
    # Certificate management
    openssl                           # Cryptography toolkit
    certbot                           # Let's Encrypt client
    
    # ===== TEXT PROCESSING & UTILITIES =====
    
    # Text processing
    ripgrep                           # Fast text search
    fd                                # Modern find alternative
    fzf                               # Fuzzy finder
    bat                               # Better cat with syntax highlighting
    eza                               # Modern ls replacement
    
    # File manipulation
    tree                              # Directory tree display
    entr                              # Run commands on file change
    inotify-tools                     # File system event monitoring
    
    # Archive handling
    unzip
    zip
    gnutar  # tar command
    gzip
    xz
    
    # ===== DEVELOPMENT TOOLS =====
    
    # Code editors (CLI)
    vim
    neovim
    emacs
    nano
    
    # Development utilities
    gnumake                           # Build automation (make command)
    cmake                             # Cross-platform build system
    ninja                             # Small build system
    
    # Documentation tools
    pandoc                            # Universal document converter
    graphviz                          # Graph visualization
    
    # ===== MESSAGING & COMMUNICATION =====
    
    # Message brokers (clients)
    mosquitto                         # MQTT clients
    
    # Email tools
    msmtp                             # SMTP client
    mailutils                         # Mail utilities
    
    # Notification tools
    libnotify                         # Desktop notifications
    
    # ===== BACKUP & SYNC =====
    
    # Backup tools
    restic                            # Modern backup program
    borgbackup                        # Deduplicating backup
    
    # File synchronization
    rclone                            # Cloud storage sync
    rsync                             # File synchronization
    unison                            # File synchronizer
    syncthing                         # Continuous file sync
    
    # ===== WORKFLOW-SPECIFIC TOOLS =====
    
    # Time and scheduling
    cron                              # Task scheduler
    at                                # One-time task scheduling
    dateutils                         # Date/time utilities
    
    # Load testing
    wrk                               # HTTP load testing
    
    # Data serialization
    protobuf                          # Protocol buffers
    
    # ===== DEVELOPMENT ENVIRONMENT =====
    
    # Language servers and development support
    nodePackages.bash-language-server
    nodePackages.yaml-language-server
    nodePackages.dockerfile-language-server-nodejs
    
    # Linting and formatting
    shellcheck                        # Shell script linter
    shfmt                            # Shell script formatter
    yamllint                         # YAML linter
    
    # ===== SPECIALIZED AUTOMATION TOOLS =====
    
    # Web automation
    chromium                          # Browser for automation
    firefox                           # Alternative browser
    chromedriver                      # Chrome WebDriver
    geckodriver                       # Firefox WebDriver
    
    # API mocking and testing
    mockserver                        # API mocking (if available)
    
    # Performance monitoring
    strace                            # System call tracer
    ltrace                            # Library call tracer
  ];

  shellHook = ''
    echo "🚀 Automation Development Shell"
    echo "================================"
    echo ""
    echo "Available workflow engines:"
    echo "  • n8n          - Self-hosted workflow automation"
    echo "  • Node-RED     - Visual programming environment"
    echo ""
    echo "Key automation tools:"
    echo "  • curl/httpie  - HTTP testing"
    echo "  • jq/yq        - JSON/YAML processing"
    echo "  • postman      - API development"
    echo "  • docker       - Containerization"
    echo "  • kubectl      - Kubernetes management"
    echo ""
    echo "Development languages:"
    echo "  • Python 3     - Full automation ecosystem"
    echo "  • Node.js      - JavaScript/TypeScript runtime"
    echo "  • Bash/Zsh     - Shell scripting"
    echo "  • PowerShell   - Cross-platform automation"
    echo ""
    echo "Quick start commands:"
    echo "  n8n start                    # Start n8n server"
    echo "  node-red                     # Start Node-RED"
    echo "  python -m http.server        # Simple HTTP server"
    echo "  curl -s api.github.com/user  # Test API endpoint"
    echo "  jq '.' file.json             # Pretty-print JSON"
    echo ""
    
    # Set up automation environment variables
    export AUTOMATION_HOME="/var/lib/automation"
    export N8N_USER_FOLDER="$AUTOMATION_HOME/n8n"
    export NODE_RED_HOME="$AUTOMATION_HOME/node-red"
    export PYTHONPATH="$AUTOMATION_HOME/python:$PYTHONPATH"
    
    # Create automation directories if they don't exist
    mkdir -p "$AUTOMATION_HOME"/{n8n,node-red,python,logs,workflows,temp}
    
    # Add automation scripts to PATH
    export PATH="/etc/nixos/scripts/automation:$PATH"
    
    # Set up Python virtual environment for automation
    if [ ! -d "$AUTOMATION_HOME/python/venv" ]; then
      echo "Setting up Python virtual environment for automation..."
      python -m venv "$AUTOMATION_HOME/python/venv"
      source "$AUTOMATION_HOME/python/venv/bin/activate"
      pip install --upgrade pip
      pip install requests pyyaml click rich schedule celery redis pymongo sqlalchemy
      echo "Python automation environment ready!"
    else
      echo "Activating existing Python automation environment..."
      source "$AUTOMATION_HOME/python/venv/bin/activate"
    fi
    
    # Set helpful aliases
    alias ll='eza -la --group-directories-first --icons'
    alias cat='bat'
    alias grep='ripgrep'
    alias find='fd'
    alias http='httpie'
    alias json='jq .'
    alias yaml='yq .'
    
    # Automation-specific aliases
    alias n8n-start='n8n start'
    alias node-red-start='node-red'
    alias automation-health='/etc/nixos/scripts/automation/system-automation.sh health-check'
    alias workflow-status='/etc/nixos/scripts/automation/workflow-manager.py status'
    alias api-test='/etc/nixos/scripts/automation/system-automation.sh api-test'
    
    # Docker aliases for workflow development
    alias docker-ps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
    alias docker-logs='docker logs -f'
    
    # Kubernetes aliases
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    
    echo "Environment configured. Type 'exit' to leave the automation shell."
    echo ""
  '';

  # Environment variables for automation development
  shellVariables = {
    # n8n configuration
    N8N_HOST = "0.0.0.0";
    N8N_PORT = "5678";
    N8N_PROTOCOL = "http";
    
    # Node-RED configuration
    NODE_RED_HOST = "127.0.0.1";
    NODE_RED_PORT = "1880";
    
    # Python configuration
    PYTHONPATH = "/var/lib/automation/python";
    PIP_USER = "1";
    
    # Development tools
    EDITOR = "vim";
    PAGER = "bat";
    BROWSER = "chromium";
    
    # Automation-specific
    AUTOMATION_LOG_LEVEL = "INFO";
    AUTOMATION_CONFIG_DIR = "/var/lib/automation/config";
    AUTOMATION_WORKFLOWS_DIR = "/var/lib/automation/workflows";
  };
}
