# Modular NixOS Configuration

This is a modular NixOS configuration system that allows you to easily enable or disable different sets of packages and services based on your needs. The system is designed to be minimal by default while providing optional components that can be enabled as needed.

## 📁 Directory Structure

```
.
├── flake.nix                    # Main flake configuration with home-manager
├── configuration.nix             # Main system configuration
├── hardware-configuration.nix    # Hardware-specific config (generated)
├── home-manager.nix             # Home-manager configuration
├── modules/                     # Modular system components
│   ├── ai-services.nix          # AI services (Ollama, NVIDIA CUDA setup)
│   ├── boot.nix                 # Boot configuration
│   ├── boot-enhancements.nix    # Boot enhancements and themes
│   ├── containers.nix           # Container services (Podman, Docker)
│   ├── core-packages.nix        # Core system packages and nixGL setup
│   ├── custom-binding.nix       # Custom SSD2 bind mounts
│   ├── device-permissions.nix   # Device access permissions
│   ├── display-manager.nix      # Display manager (GDM) configuration
│   ├── electron-apps.nix        # Electron apps with Wayland support
│   ├── flake-config.nix         # Flake configuration management
│   ├── hardware.nix             # Hardware support (audio, bluetooth, graphics)
│   ├── home-manager-integration.nix # Home-manager integration
│   ├── networking.nix           # Network configuration
│   ├── nixgl.nix               # nixGL graphics compatibility
│   ├── optional-packages.nix    # Optional package collections
│   ├── pentest.nix             # Penetration testing configuration
│   ├── pentest-packages.nix     # Penetration testing tools (optional)
│   ├── security.nix            # Security configuration
│   ├── security-services.nix    # Security services
│   ├── system-base.nix         # Base system configuration
│   ├── system-optimization.nix  # System performance optimizations
│   ├── system-services.nix     # System services
│   ├── user-security.nix       # User security configuration
│   ├── users.nix               # User account management
│   ├── virtualization.nix      # Virtualization services
│   └── wayland.nix             # Wayland environment setup
├── packages/                    # Package collections
│   ├── boot-packages.nix        # Boot-related packages
│   ├── containers-packages.nix  # Container-related packages
│   ├── core-packages.nix        # Essential system utilities
│   ├── dev-packages.nix         # Development tools
│   ├── entertainment-packages.nix# Entertainment applications
│   ├── essential-packages.nix   # Essential packages
│   ├── gaming-packages.nix      # Gaming platforms and tools
│   ├── media-packages.nix       # Media and graphics packages
│   ├── minimal-packages.nix     # Minimal package set
│   ├── networking-packages.nix  # Networking tools
│   ├── nixai-config.yaml        # nixai configuration
│   ├── pentest-packages.nix     # Penetration testing tools
│   ├── popular-packages.nix     # Popular and widely-used packages
│   ├── productivity-packages.nix # Productivity applications
│   ├── system-base-packages.nix # System base packages
│   └── virtualization-packages.nix # Virtualization packages
├── shells/                      # Development shell environments
│   ├── flutter-shell.nix        # Flutter development environment
│   ├── full-dev-shell.nix       # Full development environment
│   ├── php-shell.nix            # PHP development environment
│   ├── python-shell.nix         # Python development environment
│   └── typescript-shell.nix     # TypeScript development environment
├── legacy/                      # Legacy and deprecated modules
│   ├── modules/                 # Moved legacy modules
│   │   ├── core.nix             # Legacy core module
│   │   ├── electron-desktop-portals.nix # Legacy electron portals
│   │   ├── gnome-desktop.nix    # Legacy GNOME configuration
│   │   └── optional.nix         # Legacy optional module
│   └── packages/                # Moved legacy packages
│       └── nixai-packages.nix   # Legacy nixai packages
└── .gitignore                   # Git ignore rules
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

## 🖥️ Electron Apps & Wayland Support

### Electron Apps Module
The `modules/electron-apps.nix` provides proper Wayland support for Electron-based applications:

```nix
custom.electron-apps = {
  discord.enable = true;     # Discord with Wayland support
  chromium.enable = true;    # Chromium browser with Wayland support
  vscode.enable = true;      # VS Code with Wayland support
};
```

### Features
- **Wayland Native**: Apps run natively on Wayland with proper flags
- **Desktop Integration**: Custom desktop files for GUI launchers
- **Shell aliases**: Terminal aliases with proper flags
- **Environment Variables**: Proper XDG and Wayland environment setup

### Manual Installation
If the module doesn't work immediately, you can create manual desktop files:
```bash
# Create manual Discord desktop file
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/discord-wayland.desktop << 'EOF'
[Desktop Entry]
Name=Discord (Wayland)
Exec=discord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox %U
Icon=discord
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=discord
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications
```

### Troubleshooting Electron Apps
- **GUI Launcher Issues**: Use manual desktop files or system rebuild
- **Wayland Flags**: Apps include `--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland`
- **Sandbox Issues**: Apps include `--no-sandbox --disable-gpu-sandbox` for compatibility
- **Environment**: Ensure `XDG_SESSION_TYPE=wayland` and `WAYLAND_DISPLAY=wayland-0` are set

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

## 🔄 System Restoration

### Recent Restoration (2025-07-12)
The following components have been restored from git history:
- **README.md**: Complete documentation restored
- **modules/pentest-packages.nix**: Penetration testing module restored
- **configuration.nix**: Import for pentest-packages.nix restored

### Restoration Process
If you need to restore deleted files in the future:
```bash
# Check what files were deleted
git status

# Restore specific files
git restore README.md
git restore modules/pentest-packages.nix

# Or restore all deleted files
git restore .

# Verify the restoration
git status
```

### Configuration Updates
After restoration, the configuration now includes:
- ✅ Complete pentest-packages.nix module
- ✅ Proper import in configuration.nix
- ✅ Security warnings and desktop notifications
- ✅ Tor service integration
- ✅ All penetration testing tools available

---

**Remember**: 
- Always use security tools responsibly and only on systems you own or have explicit permission to test
- AI services require substantial system resources - monitor usage appropriately
- Keep your system updated regularly for security patches
- Use git restore to recover accidentally deleted files

