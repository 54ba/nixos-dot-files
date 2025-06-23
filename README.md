# Comprehensive NixOS Configuration with nixGL and Optional Penetration Testing Tools

This repository contains a modular NixOS configuration with nixGL support for OpenGL applications and optional penetration testing tools.

## 📁 Directory Structure

```
.
├── flake.nix                    # Main flake configuration
├── configuration.nix             # Main system configuration
├── hardware-configuration.nix    # Hardware-specific config (generated)
├── overlays/
│   └── nixgl-wrapper.nix         # nixGL wrapper overlay
├── modules/
│   ├── core-packages.nix         # Core system packages and nixGL setup
│   ├── optional-packages.nix     # Optional package collections
│   └── pentest-packages.nix      # Penetration testing tools (optional)
└── packages/
    ├── core-packages.nix         # Essential system utilities
    ├── media-packages.nix        # Media and graphics packages
    ├── dev-packages.nix          # Development tools
    ├── productivity-packages.nix # Productivity applications
    ├── gaming-packages.nix       # Gaming platforms and tools
    ├── entertainment-packages.nix# Entertainment applications
    ├── pentest-packages.nix      # Penetration testing tools
    └── popular-packages.nix      # Popular and widely-used packages
```

## 🚀 Quick Start

### 1. Enable Package Collections

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

### 2. Enable Penetration Testing Tools (Optional)

⚠️ **WARNING**: These tools should only be used on systems you own or have explicit permission to test.

```nix
custom.security = {
  pentest.enable = true;
  pentest.warning = true;  # Set to false to disable warnings
};
```

### 3. Build and Apply Configuration

```bash
# Build the configuration
nixos-rebuild switch --flake .

# Or test without applying
nixos-rebuild test --flake .
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

## 🔄 Updates

```bash
# Update flake inputs
nix flake update

# Rebuild with updated packages
nixos-rebuild switch --flake .

# Garbage collect old generations
sudo nix-collect-garbage -d
```

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

This configuration is provided as-is for educational and personal use. Users are responsible for compliance with all software licenses and applicable laws, especially regarding security tools.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Test configuration thoroughly
4. Submit pull request with clear description

---

**Remember**: Always use security tools responsibly and only on systems you own or have explicit permission to test.

