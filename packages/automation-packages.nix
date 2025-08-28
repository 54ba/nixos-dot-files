{ pkgs }:

with pkgs; [
  # ===== WORKFLOW ORCHESTRATION ENGINES =====
  
  # n8n - Self-hosted workflow automation (like Zapier/Pipedream)
  n8n
  
  # Node-RED - Visual programming for IoT and APIs
  nodePackages.node-red
  
  # Apache Airflow - Data pipeline orchestration
  # Note: Airflow requires Python environment setup
  python3Packages.apache-airflow
  
  # Prefect - Modern workflow orchestration
  python3Packages.prefect
  
  # Temporal - Durable execution platform
  # temporal (when available in nixpkgs)
  
  # ===== API AUTOMATION & TESTING =====
  
  # HTTP clients and API testing
  curl
  wget  
  httpie
  postman
  insomnia
  
  # JSON/YAML processors
  jq
  yq-go
  fx  # Interactive JSON viewer
  
  # API testing frameworks
  newman  # Postman collection runner
  nodePackages.dredd  # API testing framework
  
  # ===== CLI AUTOMATION TOOLS =====
  
  # Version control
  gh        # GitHub CLI
  glab      # GitLab CLI
  git-extras
  
  # Cloud providers
  awscli2
  azure-cli
  google-cloud-sdk
  
  # Communication platforms
  slack-cli  # (if available)
  # telegram-cli
  # discord-cli
  
  # File transfer and sync
  rclone
  rsync
  scp
  
  # ===== SCRIPTING & AUTOMATION LANGUAGES =====
  
  # Python automation ecosystem
  python3
  python3Packages.pip
  python3Packages.requests
  python3Packages.urllib3
  python3Packages.httpx
  python3Packages.aiohttp
  python3Packages.pyyaml
  python3Packages.toml
  python3Packages.click
  python3Packages.typer
  python3Packages.rich  # Rich terminal formatting
  python3Packages.schedule  # Job scheduling
  python3Packages.celery  # Distributed task queue
  python3Packages.redis  # Redis client
  python3Packages.psycopg2  # PostgreSQL adapter
  python3Packages.pymongo  # MongoDB client
  python3Packages.selenium  # Browser automation
  python3Packages.beautifulsoup4  # Web scraping
  python3Packages.scrapy  # Web crawling framework
  python3Packages.playwright  # Browser automation
  
  # Node.js automation ecosystem
  nodejs
  npm
  yarn
  pnpm
  nodePackages.pm2  # Process manager
  nodePackages.nodemon  # File watcher
  nodePackages.concurrently  # Run commands concurrently
  
  # Shell scripting tools
  bash
  zsh
  fish
  powershell  # Cross-platform PowerShell
  
  # ===== TASK SCHEDULERS =====
  
  # Traditional scheduling
  cron
  at
  
  # Modern alternatives
  # systemd timers (built into NixOS)
  
  # ===== MESSAGING & INTEGRATION =====
  
  # Message brokers
  # rabbitmq-server (configured via services)
  # redis (configured via services)
  
  # MQTT
  mosquitto  # MQTT broker
  mosquitto-clients  # MQTT client tools
  
  # ===== DATABASE TOOLS =====
  
  # Database clients
  postgresql  # PostgreSQL client
  sqlite  # SQLite
  # mongodb tools
  redis-cli  # Redis CLI (when Redis is available)
  
  # ===== WEB SCRAPING & BROWSER AUTOMATION =====
  
  # Browsers for automation
  chromium
  firefox
  
  # Browser automation drivers
  chromedriver
  geckodriver
  
  # Headless browsers
  # puppeteer (via npm)
  
  # ===== MONITORING & OBSERVABILITY =====
  
  # Log processing
  jq  # JSON log processing
  logrotate  # Log rotation
  
  # Metrics and monitoring
  # prometheus (when configured)
  # grafana (when configured)
  
  # Performance monitoring
  htop
  iotop
  nethogs
  
  # ===== SECURITY & SECRET MANAGEMENT =====
  
  # Secret management
  sops  # Secrets with Mozilla SOPS
  age   # Modern encryption tool
  pass  # Password manager
  
  # Certificate management
  openssl
  certbot  # Let's Encrypt certificates
  
  # ===== DEVELOPMENT & DEBUGGING =====
  
  # Network debugging
  netcat
  socat
  nmap
  wireshark-cli
  tcpdump
  
  # HTTP debugging
  mitmproxy  # HTTP proxy for debugging
  burpsuite  # Web security testing (community edition)
  
  # Tunneling
  ngrok
  # localtunnel
  
  # ===== CONTAINER & ORCHESTRATION =====
  
  # Container tools
  docker
  docker-compose
  podman
  buildah
  
  # Kubernetes tools
  kubectl
  kubernetes-helm
  k9s  # Kubernetes TUI
  kubectx  # Kubernetes context switcher
  stern  # Multi-pod log tailing
  
  # ===== TEXT PROCESSING & UTILITIES =====
  
  # Text processing
  sed
  awk
  grep
  ripgrep
  
  # File manipulation
  fd  # Modern find
  fzf  # Fuzzy finder
  tree
  
  # Data conversion
  pandoc  # Document conversion
  
  # ===== VERSION CONTROL & CI/CD =====
  
  # Git tools
  git
  git-lfs
  git-crypt
  
  # CI/CD tools
  gitlab-runner
  act  # Run GitHub Actions locally
  
  # ===== INFRASTRUCTURE AS CODE =====
  
  # Infrastructure tools
  terraform
  terragrunt
  ansible
  
  # ===== NOTIFICATION & COMMUNICATION =====
  
  # Email
  msmtp  # SMTP client
  mailutils  # Mail utilities
  
  # Desktop notifications
  libnotify  # notify-send command
  
  # ===== SPECIALIZED AUTOMATION TOOLS =====
  
  # Time and date utilities
  dateutils
  
  # File system watching
  entr  # Run commands when files change
  inotify-tools  # File system events
  
  # Network utilities
  curl
  wget
  aria2  # Advanced download utility
  
  # Archive handling
  unzip
  zip
  tar
  gzip
  xz
  
  # ===== TESTING FRAMEWORKS =====
  
  # API testing
  newman  # Postman CLI
  
  # Load testing
  # wrk  # HTTP load testing tool
  # hey  # HTTP load generator
  
  # ===== WORKFLOW HELPERS =====
  
  # Markdown processing
  pandoc
  
  # CSV/TSV processing
  csvkit  # CSV utilities (when available)
  # miller  # Like awk/sed/cut/join/sort for CSV/TSV/JSON
  
  # ===== DEVELOPMENT SERVERS =====
  
  # Simple HTTP servers
  python3  # python -m http.server
  nodejs   # npx http-server
  
  # ===== BACKUP & SYNC =====
  
  # Backup tools
  restic  # Modern backup program
  borgbackup  # Deduplicating backup program
  
  # Sync tools
  unison  # File synchronizer
  syncthing  # Continuous file synchronization
]
