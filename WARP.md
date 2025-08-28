# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Development Commands

### System Configuration Management
```bash
# Build and apply system configuration
sudo nixos-rebuild switch --flake .#mahmoud-laptop

# Test configuration without switching
sudo nixos-rebuild test --flake .#mahmoud-laptop  

# Build for next boot (safer)
sudo nixos-rebuild boot --flake .#mahmoud-laptop

# Dry run to see what would change
nixos-rebuild dry-run --flake .#mahmoud-laptop
```

### System Maintenance
```bash
# Run comprehensive system maintenance
sudo ./scripts/system-maintenance.sh

# Manual maintenance tasks
sudo nix-collect-garbage -d              # Clean old generations
nix-store --optimise                     # Optimize store
nix flake update                         # Update flake inputs
journalctl --vacuum-time=7d              # Clean logs
```

### Home Manager (Standalone Mode)
```bash
# Switch home-manager configuration  
./hm-switch.sh

# Or manually as user mahmoud
home-manager switch --flake .#mahmoud
```

### Development Shells
```bash
# Enter specialized development environments
nix develop .#python        # Python development environment
nix develop .#typescript    # TypeScript development environment  
nix develop .#php           # PHP development environment
nix develop .#flutter       # Flutter development environment
nix develop .#full-dev      # Full development environment
```

### Package Testing
```bash
# Temporarily install packages for testing
nix-shell -p package-name

# Search for packages
nix search nixpkgs package-name
```

## Repository Architecture

### Core Design Principles

**Modular Configuration System**: This NixOS configuration uses a highly modular architecture where functionality is split into specialized modules under `modules/` that can be independently enabled/disabled via options in the main `configuration.nix`.

**Package Collections**: Rather than monolithic package lists, packages are organized into logical collections in the `packages/` directory (development, gaming, media, productivity, etc.) that can be selectively enabled.

**Flake-Based**: The system uses Nix flakes for reproducible builds with pinned dependencies managed through `flake.lock`.

### Directory Structure

```
/etc/nixos/
├── flake.nix                 # Main flake configuration with inputs/outputs
├── configuration.nix         # Primary system configuration with module imports
├── hardware-configuration.nix # Hardware-specific settings (auto-generated)
├── home-manager.nix          # User environment configuration
├── modules/                  # Modular system components
│   ├── boot.nix             # Boot loader and GRUB configuration
│   ├── system-base.nix      # Core system settings (hostname, locale, timezone)
│   ├── hardware.nix         # Hardware support (audio, bluetooth, graphics)
│   ├── networking.nix       # Network configuration
│   ├── security.nix         # Security framework (AppArmor, PAM, sudo)
│   ├── ai-services.nix      # Ollama + NVIDIA CUDA for AI workloads
│   ├── electron-apps.nix    # Electron apps with Wayland optimization
│   └── [25+ other modules]  # Each handles specific functionality
├── packages/                # Package collections organized by purpose
│   ├── dev-packages.nix     # Development tools
│   ├── gaming-packages.nix  # Gaming platforms and tools  
│   ├── media-packages.nix   # Media editing and playback
│   └── [10+ other collections]
├── shells/                  # Development shell environments
└── scripts/                 # System maintenance and utility scripts
```

### Module System Pattern

Each module follows a consistent pattern:
1. **Options Definition**: Uses `mkEnableOption` and `mkOption` to define configurable options under `custom.*` namespace
2. **Conditional Configuration**: Uses `mkIf` to only apply configuration when the module is enabled
3. **Composable**: Modules can depend on each other but remain independently toggleable

Example module structure:
```nix
{ config, pkgs, lib, ... }:
with lib;
{
  options.custom.module-name = {
    enable = mkEnableOption "description";
    # Additional options...
  };
  
  config = mkIf config.custom.module-name.enable {
    # Module configuration only applied when enabled
  };
}
```

### Package Organization Strategy

Packages are grouped into collections by purpose rather than implementation. Each collection can be enabled independently via `custom.packages.*` options. This allows for:
- Minimal base system installations
- Selective feature additions (e.g., gaming, development, media)
- Easy maintenance of package lists
- Avoiding package conflicts through organized separation

## Configuration Management

### Adding New Modules
1. Create module file in `modules/` following the established pattern
2. Add module import to `configuration.nix` imports list  
3. Configure module options in `configuration.nix` under `custom.*`
4. Test with `nixos-rebuild test`

### Enabling/Disabling Features
The system uses feature flags throughout `configuration.nix`:
```nix
custom.ai-services.enable = true;       # AI development tools
custom.electron-apps.enable = true;     # Wayland-optimized Electron apps
custom.packages.gaming.enable = false;  # Gaming packages
```

### Hardware-Specific Optimizations
- Lenovo S540 GTX 15IWL specific optimizations in `modules/lenovo-s540-gtx-15iwl.nix`
- NVIDIA GPU optimizations for both gaming and AI workloads
- SSD bind mounts for performance (`/tmp` and `/var` → SSD2)

### Security Architecture
Multi-layered security with:
- AppArmor mandatory access control
- Enhanced PAM configuration
- Granular sudo permissions
- UFW firewall configuration  
- Optional penetration testing tools (disabled by default)

### AI/ML Development Focus
Specialized configuration for AI development:
- Ollama with CUDA acceleration for local LLM inference
- NVIDIA drivers optimized for AI workloads
- Python ML ecosystem packages
- Proper CUDA environment variables

### Home Manager Integration
Uses standalone Home Manager configuration (not as NixOS module) to avoid permission conflicts. User environment managed separately from system configuration.

## System Characteristics

**Target User**: Power user/developer with specific focus on AI/ML development, gaming, and productivity workflows.

**Hardware Profile**: Lenovo laptop with NVIDIA GPU, optimized for both development work and AI model inference.

**Desktop Environment**: GNOME on Wayland with extensive customizations and Electron app optimizations.

**Development Focus**: Multi-language development environment with specialized shells for Python, TypeScript, PHP, and Flutter development.

**Special Features**:
- Local AI model inference with Ollama
- Windows application compatibility via Wine
- Comprehensive system health monitoring
- Automated maintenance scripts
- Rescue system with generation management
