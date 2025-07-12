# PHP Development Shell
# Usage: nix-shell /etc/nixos/shells/php-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "php-dev-shell";
  
  buildInputs = with pkgs; [
    # PHP and package manager
    php82
    php82Packages.composer
    
    # PHP extensions
    php82Extensions.curl
    php82Extensions.gd
    php82Extensions.intl
    php82Extensions.mbstring
    php82Extensions.mysqli
    php82Extensions.pdo
    php82Extensions.pdo_mysql
    php82Extensions.pdo_pgsql
    php82Extensions.redis
    php82Extensions.xml
    php82Extensions.zip
    php82Extensions.opcache
    php82Extensions.xdebug
    
    # Database servers (for local development)
    mysql80
    postgresql_15
    redis
    
    # Web servers
    nginx
    apache-httpd
    
    # Development tools
    git
    vim
    curl
    jq
    
    # PHP development tools
    php82Packages.phpstan
    php82Packages.psalm
    php82Packages.php-cs-fixer
    
    # Node.js for frontend assets
    nodejs_20
    nodePackages.npm
  ];
  
  shellHook = ''
    echo "🐘 PHP Development Environment"
    echo "PHP version: $(php --version | head -n 1)"
    echo "Composer version: $(composer --version)"
    echo "Available databases: MySQL 8.0, PostgreSQL 15, Redis"
    echo "Web servers: Nginx, Apache"
    echo "Development tools: PHPStan, Psalm, PHP-CS-Fixer"
    echo ""
    echo "Frameworks supported:"
    echo "  • Laravel (via composer)"
    echo "  • Symfony (via composer)"
    echo "  • CodeIgniter (via composer)"
    echo "  • CakePHP (via composer)"
    echo ""
    echo "Quick start:"
    echo "  composer init                       # Initialize composer.json"
    echo "  composer create-project laravel/laravel my-app  # Create Laravel app"
    echo "  composer create-project symfony/skeleton my-app # Create Symfony app"
    echo "  php -S localhost:8000               # Start built-in server"
    echo "  php artisan serve                   # Start Laravel server"
    echo "  symfony serve                       # Start Symfony server"
    echo ""
    echo "Development commands:"
    echo "  composer install                    # Install dependencies"
    echo "  composer update                     # Update dependencies"
    echo "  composer require package/name       # Add new package"
    echo "  phpstan analyse                     # Static analysis"
    echo "  psalm                              # Static analysis (Psalm)"
    echo "  php-cs-fixer fix                   # Fix code style"
    echo ""
    echo "Database commands:"
    echo "  mysql.server start                 # Start MySQL"
    echo "  pg_ctl start                       # Start PostgreSQL"
    echo "  redis-server                       # Start Redis"
    
    # Set up PHP environment
    export PHP_INI_SCAN_DIR="$PWD/.php"
    export COMPOSER_HOME="$PWD/.composer"
    export PATH="$PWD/vendor/bin:$PATH"
    export PATH="$COMPOSER_HOME/vendor/bin:$PATH"
    
    # Create PHP config directory if it doesn't exist
    mkdir -p .php
    
    # Create basic php.ini for development
    cat > .php/development.ini << 'EOF'
display_errors = On
error_reporting = E_ALL
log_errors = On
memory_limit = 512M
max_execution_time = 300
upload_max_filesize = 100M
post_max_size = 100M
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.client_host = localhost
xdebug.client_port = 9003
EOF
    
    echo "PHP development environment ready!"
    echo "Custom PHP config loaded from .php/development.ini"
  '';
}

