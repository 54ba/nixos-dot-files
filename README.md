# Comprehensive NixOS Configuration with AI Services, nixGL and Optional Penetration Testing Tools

This repository contains a modular NixOS configuration with nixGL support for OpenGL applications, AI services (Ollama with CUDA), home-manager integration, and optional penetration testing tools.

## 📁 Directory Structure

```
.
├── flake.nix                    # Main flake configuration with home-manager
├── configuration.nix             # Main system configuration
├── hardware-configuration.nix    # Hardware-specific config (generated)
├── ai-services.nix              # AI services (Ollama, NVIDIA CUDA setup)
├── home-manager.nix             # Home-manager configuration
├── backgrounds/                 # Boot and desktop background images
│   ├── bg.jpg                   # Main background image
│   ├── bg-original.jpg          # Original background backup
│   ├── custom-splash.png        # Custom splash screen
│   ├── nix-dark.png            # NixOS dark theme background
│   └── README.md               # Background setup instructions
├── qtile/                       # Qtile window manager configuration
│   ├── config.py               # Main Qtile configuration
│   ├── autostart.sh            # Autostart applications script
│   └── test_qtile.sh           # Qtile test script
├── desktop-entries/             # Custom .desktop files
│   ├── cursor.desktop
│   ├── figma-linux.desktop
│   ├── github-desktop.desktop
│   ├── gparted.desktop
│   ├── riseup-vpn.desktop
│   └── wezterm.desktop
├── overlays/                    # Nix overlays
│   ├── nixgl-wrapper.nix        # nixGL wrapper overlay
│   ├── custom.nix              # Custom package overlays
│   └── warp.nix                # Warp terminal overlay
├── modules/
│   ├── core-packages.nix        # Core system packages and nixGL setup
│   ├── optional-packages.nix    # Optional package collections
│   └── pentest-packages.nix     # Penetration testing tools (optional)
├── packages/
│   ├── core-packages.nix        # Essential system utilities
│   ├── media-packages.nix       # Media and graphics packages
│   ├── dev-packages.nix         # Development tools
│   ├── productivity-packages.nix # Productivity applications
│   ├── gaming-packages.nix      # Gaming platforms and tools
│   ├── entertainment-packages.nix# Entertainment applications
│   ├── pentest-packages.nix     # Penetration testing tools
│   └── popular-packages.nix     # Popular and widely-used packages
├── home-manager/                # Home-manager specific configurations
│   ├── home.nix                # Main home configuration
│   └── zsh.nix                 # ZSH shell configuration
└── scripts/                     # Utility scripts
    ├── deploy-enhanced.sh       # Enhanced deployment script
    ├── nix-config.sh           # Configuration management script
    └── ufw-setup.sh            # Firewall setup script
```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/54ba/nixos-dot-files.git /etc/nixos
cd /etc/nixos

# Generate hardware configuration (if not done already)
sudo nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
```

### 2. Enable Package Collections

In your `configuration.nix`, you can enable different package collections:

```nix
custom.packages = {
  media.enable = true;          # Media and graphics packages
  development.enable = true;    # Development tools
  productivity.enable = true;   # Productivity applications
  gaming.enable = true;         # Gaming platforms
  entertainment.enable = true;  # Entertainment apps
  popular.enable = true;        # Popular packages collection
};
```

### 3. Enable AI Services (Optional)

🤖 **AI Services**: Includes Ollama with CUDA acceleration for local AI models.

```nix
# AI services are automatically enabled in ai-services.nix
# Includes:
# - Ollama with CUDA acceleration
# - NVIDIA drivers optimized for AI workloads
# - GPU acceleration setup
```

### 4. Enable Penetration Testing Tools (Optional)

⚠️ **WARNING**: These tools should only be used on systems you own or have explicit permission to test.

```nix
custom.security = {
  pentest.enable = true;
  pentest.warning = true;  # Set to false to disable warnings
};
```

### 5. Build and Apply Configuration

```bash
# Build the configuration with flake
nixos-rebuild switch --flake .#mahmoud-laptop

# Or test without applying
nixos-rebuild test --flake .#mahmoud-laptop

# Build specific hostname (replace with your hostname)
nixos-rebuild switch --flake .
```

## 🏠 Home Manager Integration

This configuration includes full home-manager integration for user-specific configurations:

### Features
- **ZSH Configuration**: Oh-My-ZSH with autosuggestions and syntax highlighting
- **Starship Prompt**: Beautiful and informative shell prompt
- **Git Configuration**: Enhanced Git setup with credential management
- **XDG Configuration**: Proper XDG directory and MIME type setup
- **User Environment**: Comprehensive user environment management

### Configuration Files
- `flake.nix`: Contains home-manager integration
- `home-manager/`: Directory for home-manager specific configs
- User configs are automatically applied during system rebuild

## 🎨 Boot and Desktop Themes

### GRUB Boot Loader
- **Custom Theme**: Beautiful dark theme with custom colors
- **Background Image**: Custom background from `backgrounds/bg.jpg`
- **Multiple Resolutions**: Support for various screen resolutions
- **Boot Messages**: Custom boot messages and progress indicators

### Plymouth Boot Splash
- **Theme**: Breeze theme for smooth boot experience
- **Quiet Boot**: Minimal boot messages for clean appearance

### Desktop Environments
- **GNOME**: Primary desktop environment with GDM
- **Qtile**: Alternative tiling window manager (configured in `qtile/`)

## 🤖 AI Services

### Ollama Configuration
- **CUDA Acceleration**: Full NVIDIA GPU acceleration support
- **Stable Drivers**: NVIDIA stable drivers for AI workloads
- **Local AI Models**: Run large language models locally
- **API Access**: REST API for AI model interaction

### Getting Started with AI
```bash
# List available models
ollama list

# Pull a model (e.g., llama2)
ollama pull llama2

# Run a model interactively
ollama run llama2

# API usage
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?"
}'
```

## 🎯 Package Collections

### Core Packages (Always Enabled)
- Essential system utilities (git, vim, firefox, etc.)
- Terminal tools (zsh, starship, fzf, ripgrep)
- Network utilities (nmap, netcat, openssh)
- System monitoring (htop, btop, neofetch)
- Archive tools (zip, tar, p7zip)

### Media and Graphics Packages
- **Video**: ffmpeg, kdenlive, obs-studio, handbrake
- **Image**: gimp, inkscape, krita, imagemagick
- **3D**: blender
- **Audio**: audacity, ardour, lmms
- **Players**: vlc, mpv with nixGL wrappers

### Development Packages
- **Languages**: nodejs, python, rust, go, zig, php, ruby, lua
- **Containers**: docker, podman, kubernetes tools
- **Cloud**: aws-cli, azure-cli, terraform, ansible
- **Databases**: mongodb-compass, postgresql, sqlite, redis
- **IDEs**: vscode, code-server

### Productivity Packages
- **Communication**: slack, discord, telegram, signal, thunderbird
- **Office**: libreoffice, onlyoffice
- **Notes**: obsidian, logseq, joplin
- **Security**: bitwarden, keepassxc, gnupg

### Gaming Packages
- **Platforms**: steam, lutris, heroic (with nixGL wrappers)
- **Tools**: gamemode, mangohud, wine, bottles
- **Emulators**: retroarch, dolphin-emu, pcsx2

### Entertainment Packages
- **Music**: spotify, youtube-music
- **Video**: stremio, plex, jellyfin, kodi
- **Torrents**: qbittorrent, transmission
- **Media**: yt-dlp, calibre

### Penetration Testing Packages
- **Network**: nmap, masscan, wireshark, metasploit
- **Web**: burpsuite, sqlmap, nikto, gobuster
- **Passwords**: john, hashcat, hydra
- **Wireless**: aircrack-ng, kismet
- **Forensics**: sleuthkit, autopsy, volatility
- **Reverse Engineering**: ghidra, radare2, gdb

### Popular Packages Collection
- Most commonly used packages across all categories
- Popular terminal emulators, editors, tools
- Essential fonts and themes
- Window managers and desktop utilities

## 🎮 nixGL Support

This configuration includes comprehensive nixGL support for running OpenGL applications:

### Automatic Wrappers
The overlay provides pre-wrapped versions of common GUI applications:
- `blender-nixgl`, `gimp-nixgl`, `obs-studio-nixgl`
- `vlc-nixgl`, `mpv-nixgl`, `steam-nixgl`
- `lutris-nixgl`, `heroic-nixgl`

### Manual Usage
```bash
# Use nixGL directly
nixgl-intel application-name
nixgl-nvidia application-name

# Convenient aliases
blender-gl    # Runs blender with nixGL
gimp-gl      # Runs gimp with nixGL
obs-gl       # Runs OBS with nixGL
```

### Environment Variables
- `NIXGL_INTEL`: Path to nixGLIntel binary
- `NIXGL_NVIDIA`: Path to nixGLNvidia binary

## 🪟 Window Managers

### GNOME (Default)
- **Display Manager**: GDM with auto-login support
- **Desktop Environment**: GNOME with extensions
- **Theme**: Custom dark theme with background integration

### Qtile (Alternative)
- **Configuration**: Custom Qtile config in `qtile/config.py`
- **Key Bindings**: Vim-like navigation and window management
- **Bar**: Custom status bar with system information
- **Autostart**: Configurable autostart applications

#### Qtile Key Bindings
- `Mod + Return`: Launch terminal
- `Mod + d`: Launch application launcher (rofi)
- `Mod + q`: Close window
- `Mod + hjkl`: Navigate windows
- `Mod + Shift + hjkl`: Move windows
- `Mod + 1-9`: Switch workspaces

## 🔧 Development Shells

The flake provides several development environments:

```bash
# Default development environment
nix develop

# Penetration testing environment
nix develop .#pentest

# Media production environment
nix develop .#media

# Full environment (all packages)
nix develop .#full
```

## 🛠️ Package Installation

You can also install package collections without system-wide installation:

```bash
# Install specific package collection
nix profile install .#packages.media
nix profile install .#packages.dev
nix profile install .#packages.pentest

# Install all packages
nix profile install .#packages.all
```

## ⚠️ Security Considerations

### Penetration Testing Tools
- Tools are disabled by default
- Explicit configuration required to enable
- Warning system included
- Only use on authorized systems
- Comply with local and international laws

### Unfree Packages
Some packages require unfree licenses:
- Steam, Discord, Slack, etc.
- Automatically allowed in configuration
- Review licenses for compliance

## 📝 Customization

### Adding New Packages
1. Add packages to appropriate file in `packages/`
2. Update module in `modules/` if needed
3. Rebuild configuration

### Creating New Collections
1. Create new package file in `packages/`
2. Add option in `modules/optional-packages.nix`
3. Update `flake.nix` to include new collection

### nixGL Configuration
- Modify `overlays/nixgl-wrapper.nix` for custom wrappers
- Add new pre-wrapped applications as needed
- Update aliases in `modules/core-packages.nix`

## 🔄 Updates and Maintenance

```bash
# Update flake inputs
nix flake update

# Rebuild with updated packages
nixos-rebuild switch --flake .#mahmoud-laptop

# Garbage collect old generations
sudo nix-collect-garbage -d

# Update AI models
ollama pull llama2  # or other models

# Clean up Docker/Podman (if using containers)
podman system prune -a
```

## 🔐 Security Features

### Enhanced Security
- **AppArmor**: Mandatory access control framework
- **PAM Configuration**: Enhanced authentication and session management
- **Sudo Rules**: Granular sudo permissions for system maintenance
- **File Permissions**: Proper udev rules and file system permissions
- **Firewall**: UFW setup script included

### Credential Management
- **Git Credentials**: Secure credential storage via libsecret
- **GNOME Keyring**: System-wide credential management
- **SSH Configuration**: Secure SSH directory permissions

## 🖼️ Background Management

### Adding Custom Backgrounds
1. Place your image in `backgrounds/` directory
2. Update GRUB configuration to use new background:
   ```nix
   boot.loader.grub.splashImage = ./backgrounds/your-image.jpg;
   ```
3. Rebuild system configuration

### Supported Formats
- **GRUB**: JPEG, PNG (recommended: 1920x1080)
- **Desktop**: Any format supported by GNOME/Qtile
- **Plymouth**: PNG format for boot splash

## 🐛 Troubleshooting

### OpenGL Issues
- Ensure correct nixGL variant (Intel/NVIDIA)
- Check hardware drivers are properly configured
- Use wrapped versions of applications

### Package Conflicts
- Check for conflicting package definitions
- Review unfree package permissions
- Verify system architecture compatibility

### Build Failures
- Check for syntax errors in Nix files
- Verify all imports are correct
- Review hardware-configuration.nix compatibility

## 📄 License

This configuration is provided as-is for educational and personal use. Users are responsible for compliance with all software licenses and applicable laws, especially regarding:
- Security and penetration testing tools
- AI models and services
- Proprietary software packages
- NVIDIA drivers and CUDA toolkit

## 🤝 Contributing

1. Fork the repository
2. Create feature branch from `master`
3. Test configuration thoroughly
4. Submit pull request with clear description

### Repository Structure Guidelines
- Keep configurations modular and well-documented
- Test all changes before submitting
- Follow existing naming conventions
- Update README when adding new features

## 📋 System Requirements

### Minimum Requirements
- **Architecture**: x86_64-linux
- **RAM**: 4GB (8GB+ recommended for AI services)
- **Storage**: 50GB (100GB+ recommended)
- **GPU**: NVIDIA GPU (for AI acceleration)

### Recommended Setup
- **RAM**: 16GB+ (for running local AI models)
- **Storage**: SSD with 200GB+ free space
- **GPU**: NVIDIA RTX series (for optimal AI performance)
- **Network**: Stable internet for package downloads

---

**Remember**: 
- Always use security tools responsibly and only on systems you own or have explicit permission to test
- AI services require substantial system resources - monitor usage appropriately
- Keep your system updated regularly for security patches

