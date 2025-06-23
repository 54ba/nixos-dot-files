#!/usr/bin/env bash

# Enhanced NixOS Deployment Script with nixai Integration
# This script deploys the enhanced NixOS configuration with AI assistance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Run as a regular user with sudo access."
        exit 1
    fi
}

# Backup existing configuration
backup_config() {
    local backup_dir="/etc/nixos/backup-$(date +%Y%m%d-%H%M%S)"
    print_status "Creating backup of existing configuration..."
    
    sudo mkdir -p "$backup_dir"
    
    # Backup main configuration files
    if [[ -f /etc/nixos/configuration.nix ]]; then
        sudo cp /etc/nixos/configuration.nix "$backup_dir/"
    fi
    
    if [[ -f /etc/nixos/flake.nix ]]; then
        sudo cp /etc/nixos/flake.nix "$backup_dir/"
    fi
    
    if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
        sudo cp /etc/nixos/hardware-configuration.nix "$backup_dir/"
    fi
    
    print_success "Backup created at $backup_dir"
}

# Check nixai availability
check_nixai() {
    print_status "Checking nixai availability..."
    
    if [[ -x "/etc/nixos/nix-ai-help/nixai-test" ]]; then
        print_success "nixai binary found at /etc/nixos/nix-ai-help/nixai-test"
        # Make it available system-wide by creating a symlink
        if [[ ! -L /usr/local/bin/nixai ]]; then
            sudo ln -sf /etc/nixos/nix-ai-help/nixai-test /usr/local/bin/nixai
            print_success "Created nixai symlink at /usr/local/bin/nixai"
        fi
        return 0
    else
        print_warning "nixai binary not found. Will proceed without AI assistance."
        return 1
    fi
}

# Validate configuration files
validate_config() {
    print_status "Validating configuration files..."
    
    # Check if enhanced configuration exists
    if [[ ! -f "/etc/nixos/enhanced-configuration.nix" ]]; then
        print_error "Enhanced configuration file not found!"
        exit 1
    fi
    
    # Check if nixai modules exist
    if [[ ! -d "/etc/nixos/nixai-modules" ]]; then
        print_error "nixai modules directory not found!"
        exit 1
    fi
    
    # Syntax check using nix-instantiate
    print_status "Checking NixOS configuration syntax..."
    if sudo nix-instantiate --parse /etc/nixos/enhanced-configuration.nix > /dev/null 2>&1; then
        print_success "Enhanced configuration syntax is valid"
    else
        print_error "Enhanced configuration has syntax errors!"
        exit 1
    fi
    
    # Check flake if it exists
    if [[ -f "/etc/nixos/enhanced-flake.nix" ]]; then
        print_status "Checking flake syntax..."
        if nix flake check --no-build /etc/nixos/ 2>/dev/null; then
            print_success "Flake configuration is valid"
        else
            print_warning "Flake check failed, but continuing..."
        fi
    fi
}

# Apply configuration
apply_config() {
    local config_type="$1"
    
    case $config_type in
        "standard")
            print_status "Applying enhanced NixOS configuration (standard)..."
            sudo cp /etc/nixos/enhanced-configuration.nix /etc/nixos/configuration.nix
            sudo nixos-rebuild switch
            ;;
        "flake")
            print_status "Applying enhanced NixOS configuration (flake)..."
            sudo cp /etc/nixos/enhanced-flake.nix /etc/nixos/flake.nix
            sudo nixos-rebuild switch --flake /etc/nixos#mahmoud-laptop
            ;;
        "test")
            print_status "Testing enhanced NixOS configuration..."
            sudo cp /etc/nixos/enhanced-configuration.nix /etc/nixos/configuration.nix
            sudo nixos-rebuild test
            ;;
        *)
            print_error "Unknown configuration type: $config_type"
            exit 1
            ;;
    esac
}

# Setup Home Manager
setup_home_manager() {
    print_status "Setting up Home Manager configuration..."
    
    # Create home manager directory if it doesn't exist
    mkdir -p ~/.config/home-manager
    
    # Copy home manager configuration
    if [[ -f "/etc/nixos/home-manager.nix" ]]; then
        cp /etc/nixos/home-manager.nix ~/.config/home-manager/home.nix
        print_success "Home Manager configuration copied"
        
        # Apply home manager configuration
        if command -v home-manager >/dev/null 2>&1; then
            print_status "Applying Home Manager configuration..."
            home-manager switch
            print_success "Home Manager configuration applied"
        else
            print_warning "Home Manager not available. Install it first or use the flake-based approach."
        fi
    fi
}

# Setup AI provider configuration
setup_ai_provider() {
    print_status "Setting up AI provider configuration..."
    
    echo
    print_header "AI Provider Configuration"
    echo "Available AI providers:"
    echo "1. GitHub Copilot (recommended for developers)"
    echo "2. OpenAI GPT"
    echo "3. Google Gemini"
    echo "4. Local Ollama"
    echo "5. Skip AI setup for now"
    
    read -p "Choose your AI provider (1-5): " choice
    
    case $choice in
        1)
            print_status "Setting up GitHub Copilot..."
            echo "Please ensure you have a GitHub token with Copilot access."
            echo "Set the GITHUB_TOKEN environment variable or add it to your shell profile."
            echo "export GITHUB_TOKEN=your_github_token_here"
            ;;
        2)
            print_status "Setting up OpenAI..."
            echo "Please ensure you have an OpenAI API key."
            echo "Set the OPENAI_API_KEY environment variable or add it to your shell profile."
            echo "export OPENAI_API_KEY=your_openai_key_here"
            ;;
        3)
            print_status "Setting up Google Gemini..."
            echo "Please ensure you have a Gemini API key."
            echo "Set the GEMINI_API_KEY environment variable or add it to your shell profile."
            echo "export GEMINI_API_KEY=your_gemini_key_here"
            ;;
        4)
            print_status "Setting up local Ollama..."
            echo "Ollama will be configured to run locally."
            echo "Make sure to install and start Ollama service after deployment."
            ;;
        5)
            print_warning "Skipping AI setup. You can configure it later."
            ;;
        *)
            print_warning "Invalid choice. Skipping AI setup."
            ;;
    esac
}

# Post-deployment tasks
post_deployment() {
    print_status "Running post-deployment tasks..."
    
    # Verify nixai service if available
    if systemctl is-active --quiet nixai-mcp 2>/dev/null; then
        print_success "nixai MCP service is running"
    else
        print_warning "nixai MCP service is not running (this may be expected)"
    fi
    
    # Check if nixai command is available
    if command -v nixai >/dev/null 2>&1; then
        print_success "nixai command is available"
        print_status "Testing nixai..."
        nixai --version || print_warning "nixai version check failed"
    else
        print_warning "nixai command not found in PATH"
    fi
    
    # Generate flake.lock if using flakes
    if [[ -f "/etc/nixos/flake.nix" ]]; then
        print_status "Updating flake.lock..."
        cd /etc/nixos && sudo nix flake update
    fi
}

# Show usage information
show_usage() {
    echo "Enhanced NixOS Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --test      Test the configuration without applying"
    echo "  -f, --flake     Use flake-based deployment"
    echo "  -s, --standard  Use standard configuration deployment (default)"
    echo "  -h, --help      Show this help message"
    echo "  --backup-only   Only create backup, don't deploy"
    echo "  --no-home       Skip Home Manager setup"
    echo "  --no-ai         Skip AI provider setup"
    echo ""
    echo "Examples:"
    echo "  $0                    # Standard deployment"
    echo "  $0 --test            # Test configuration"
    echo "  $0 --flake           # Flake-based deployment"
    echo "  $0 --backup-only     # Only create backup"
}

# Main deployment function
main() {
    local config_type="standard"
    local test_mode=false
    local backup_only=false
    local setup_home=true
    local setup_ai=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--test)
                test_mode=true
                config_type="test"
                shift
                ;;
            -f|--flake)
                config_type="flake"
                shift
                ;;
            -s|--standard)
                config_type="standard"
                shift
                ;;
            --backup-only)
                backup_only=true
                shift
                ;;
            --no-home)
                setup_home=false
                shift
                ;;
            --no-ai)
                setup_ai=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header "🚀 Enhanced NixOS Deployment with AI Integration"
    echo
    
    # Perform checks
    check_root
    
    # Create backup
    backup_config
    
    if [[ "$backup_only" == true ]]; then
        print_success "Backup completed. Exiting as requested."
        exit 0
    fi
    
    # Check nixai availability
    nixai_available=false
    if check_nixai; then
        nixai_available=true
    fi
    
    # Validate configuration
    validate_config
    
    # Setup AI provider if requested and available
    if [[ "$setup_ai" == true && "$nixai_available" == true ]]; then
        setup_ai_provider
    fi
    
    # Apply configuration
    apply_config "$config_type"
    
    if [[ "$test_mode" == false ]]; then
        print_success "NixOS configuration applied successfully!"
        
        # Setup Home Manager if requested
        if [[ "$setup_home" == true ]]; then
            setup_home_manager
        fi
        
        # Post-deployment tasks
        post_deployment
        
        echo
        print_header "🎉 Deployment Complete!"
        echo
        print_success "Enhanced NixOS with AI assistance is now active!"
        
        if [[ "$nixai_available" == true ]]; then
            echo
            print_status "Available nixai commands:"
            echo "  nixai ask 'How do I configure X?'    # Ask AI for help"
            echo "  nixai diagnose                      # Diagnose system issues"
            echo "  nixai build --help                  # Get build assistance"
            echo "  nixai templates list                # List configuration templates"
            echo "  nixai doctor                        # Run system health check"
        fi
        
        echo
        print_status "Next steps:"
        echo "1. Reboot your system to ensure all changes take effect"
        echo "2. Configure your AI provider API keys if you haven't already"
        echo "3. Try running 'nixai ask \"help me optimize my NixOS setup\"'"
        
    else
        print_success "Configuration test completed successfully!"
        print_status "Run without --test flag to apply the configuration permanently."
    fi
}

# Run main function with all arguments
main "$@"

