# NixOS Enhanced Environment Variables Documentation

## Overview

This document describes the comprehensive environment variable enhancements made to your NixOS system to include all installed libraries and packages.

## What Was Enhanced

### 1. Development Libraries Module (`modules/development-libraries.nix`)

Enhanced environment variables to include all system libraries and headers:

#### **PKG_CONFIG_PATH**
- Now includes pkg-config files from all enabled package categories
- Automatically includes: glibc, gcc, zlib, bzip2, openssl, curl
- Graphics: mesa, vulkan, wayland, X11
- Multimedia: ffmpeg, gstreamer, alsa, pipewire
- GUI: gtk3, gtk4, cairo, pango, Qt5, Qt6

#### **CPATH (C/C++ Include Path)**
- Comprehensive header search paths for all development libraries
- Includes system headers, compression libraries, graphics, multimedia, and GUI toolkits
- Automatically appends to existing CPATH

#### **CMAKE_PREFIX_PATH & CMAKE_LIBRARY_PATH**
- Enhanced CMake discovery paths for all installed packages
- Includes all core, graphics, multimedia, and GUI libraries
- Supports Qt5 and Qt6 development

#### **LIBRARY_PATH**
- Comprehensive linker library search paths
- Includes all shared libraries (.so) and static libraries (.a)
- Covers: compression (zlib, bzip2, xz, lz4, zstd)
- Graphics: Mesa, Vulkan, Wayland, X11
- Multimedia: FFmpeg, GStreamer, audio libraries
- Networking: OpenSSL, curl, protobuf, gRPC
- GUI: GTK, Qt, Cairo, Pango

#### **PATH**
- Binary paths for all essential development tools
- Includes: coreutils, findutils, grep, sed, awk, git, wget, curl

### 2. System-Wide Configuration (`configuration.nix`)

Added global environment variables accessible to all users:

#### **NIX_PROFILES**
- Points to all Nix profile locations
- Default system profile, current system, and user profiles

#### **Documentation Paths**
- **MANPATH**: Man pages from all installed packages
- **INFOPATH**: Info documentation
- **ACLOCAL_PATH**: Autotools macro files

#### **System Resources**
- **TERMINFO_DIRS**: Terminal information database
- **LOCALE_ARCHIVE**: System locale files

## New Tools

### Environment Inspector (`env-inspector`)

A comprehensive command-line tool to inspect and manage your system environment:

```bash
# Show all installed packages
env-inspector packages

# Display all environment variables
env-inspector env

# Show library search paths
env-inspector libs

# Show header/include paths
env-inspector headers

# Test if a package/library is available
env-inspector test gtk3

# Search for packages by name
env-inspector search python

# Export comprehensive development environment
env-inspector export

# Show system statistics
env-inspector stats
```

### Features:

1. **Package Discovery**: Find all binaries, libraries, and headers
2. **Environment Inspection**: View all environment variables with colored output
3. **Package Testing**: Check if packages are properly installed and accessible
4. **Search Functionality**: Search across binaries, libraries, and headers
5. **Environment Export**: Generate a sourceable script with all paths
6. **Statistics**: See counts of installed packages and disk usage

## Using the Enhanced Environment

### For Development

The enhanced environment variables are automatically available in all shells. To verify:

```bash
# Check if libraries are accessible
echo $LIBRARY_PATH

# Check include paths
echo $CPATH

# Check pkg-config can find packages
pkg-config --list-all

# Test CMake configuration
echo $CMAKE_PREFIX_PATH
```

### For Building Projects

All build systems should now automatically find installed libraries:

```bash
# CMake projects
cmake -B build -S .
cmake --build build

# Make projects
./configure
make

# Meson projects
meson setup build
ninja -C build

# Cargo/Rust projects
cargo build

# Python projects with native extensions
pip install -e .
```

### Manual Environment Setup

If you need to manually set up the environment (e.g., in a specific shell):

```bash
# Generate environment script
env-inspector export

# Source the generated environment
source /tmp/nixos-dev-env.sh
```

## Environment Variable Reference

### Core System Variables

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `NIX_PROFILES` | All Nix profile locations | `/nix/var/nix/profiles/default /run/current-system/sw` |
| `PATH` | Binary search paths | `/run/current-system/sw/bin:...` |
| `MANPATH` | Man page directories | `/run/current-system/sw/share/man` |

### Build System Variables

| Variable | Purpose | Enabled By |
|----------|---------|------------|
| `PKG_CONFIG_PATH` | pkg-config search path | Development Libraries Module |
| `CPATH` | C/C++ include search path | Development Libraries Module |
| `CMAKE_PREFIX_PATH` | CMake package search path | Development Libraries Module |
| `CMAKE_LIBRARY_PATH` | CMake library search path | Development Libraries Module |
| `LIBRARY_PATH` | Linker library search path | Development Libraries Module |

### Language-Specific Variables

| Variable | Purpose | When Enabled |
|----------|---------|--------------|
| `PYTHONPATH` | Python module search path | When Python development enabled |
| `NODE_PATH` | Node.js module search path | When Node.js development enabled |
| `GOPATH` | Go workspace path | When Go development enabled |

## Package Categories

The development libraries module organizes packages into categories:

### Core Libraries (Enabled by Default)
- glibc, gcc, binutils
- pkg-config, cmake, autotools
- libffi, libiconv

### Graphics Libraries (Enabled by Default)
- Mesa, Vulkan, OpenGL
- Wayland, X11 libraries
- libxkbcommon

### Multimedia Libraries (Enabled by Default)
- FFmpeg, GStreamer
- ALSA, PipeWire
- Image libraries (JPEG, PNG, WebP)

### Networking Libraries (Enabled by Default)
- OpenSSL, curl
- libssh, protobuf, gRPC

### Compression Libraries (Enabled by Default)
- zlib, bzip2, xz, lz4, zstd
- libarchive

### GUI Libraries (Enabled by Default)
- GTK 3, GTK 4
- Qt 5, Qt 6
- Cairo, Pango, GDK-Pixbuf

### Optional Categories (Disabled by Default)
- Database libraries (SQLite, PostgreSQL)
- Python development libraries
- Node.js development libraries
- Java development libraries

## Enabling/Disabling Categories

Edit `/etc/nixos/configuration.nix` to enable/disable categories:

```nix
custom.development-libraries = {
  enable = true;
  core = true;
  graphics = true;
  multimedia = true;
  networking = true;
  compression = true;
  gui = true;
  
  # Enable additional categories
  database = true;    # Enable database libraries
  python = true;      # Enable Python development
  nodejs = true;      # Enable Node.js development
  java = true;        # Enable Java development
};
```

After editing, rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Troubleshooting

### Package Not Found

If a package isn't found:

```bash
# Search for the package
env-inspector search <package-name>

# Test if it's installed
env-inspector test <package-name>

# Check if binary exists
command -v <package-name>

# Check if library exists
find /run/current-system/sw/lib -name "lib<package>*"
```

### Build Failures

If builds fail to find libraries:

```bash
# Check environment variables
env-inspector env

# Verify library paths
env-inspector libs

# Check specific library
pkg-config --cflags --libs <library-name>
```

### Environment Not Loading

If environment variables aren't set:

```bash
# Manually source the environment
source /tmp/nixos-dev-env.sh

# Or add to your shell RC file
echo "source /tmp/nixos-dev-env.sh" >> ~/.bashrc  # For Bash
echo "source /tmp/nixos-dev-env.sh" >> ~/.zshrc   # For Zsh
```

## Statistics

Your current system (as an example):

```bash
env-inspector stats
```

Should show:
- System binaries: ~3600+
- System libraries: Hundreds of .so files
- Header files: Thousands of .h files
- pkg-config files: Hundreds of .pc files
- Store dependencies: ~9600+ packages

## Benefits

1. **Seamless Compilation**: All installed libraries are automatically discoverable
2. **Build System Compatibility**: Works with CMake, Make, Meson, Cargo, etc.
3. **IDE Integration**: IDEs can find headers and libraries automatically
4. **Cross-Language Support**: Python, Node.js, Rust, Go, C/C++ all supported
5. **No Manual Configuration**: Environment variables are set system-wide

## Advanced Usage

### Custom Development Shells

Create a `shell.nix` for project-specific environments:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Add project-specific dependencies
  ];
  
  shellHook = ''
    # Inherit system environment variables
    export CPATH="$CPATH"
    export LIBRARY_PATH="$LIBRARY_PATH"
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    
    # Add project-specific paths
    export PROJECT_ROOT="$(pwd)"
  '';
}
```

### CI/CD Integration

For CI/CD pipelines, export the environment:

```bash
# In your CI script
env-inspector export
source /tmp/nixos-dev-env.sh

# Now build your project
cmake -B build
cmake --build build
```

## References

- [NixOS Manual - Environment Variables](https://nixos.org/manual/nixos/stable/#sec-environment-variables)
- [Nix Pills - Environment Variables](https://nixos.org/guides/nix-pills/)
- [NixOS Wiki - Development](https://nixos.wiki/wiki/Development)

## Support

For issues or questions about the environment configuration:

1. Check system logs: `journalctl -b`
2. Verify configuration: `nixos-option custom.development-libraries`
3. Test specific packages: `env-inspector test <package>`
4. Search for packages: `env-inspector search <query>`

---

Last Updated: $(date)
Generated for NixOS Configuration at /etc/nixos
