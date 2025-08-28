# NixOS Configuration - Enabled Modules Documentation

## 📋 **Currently Enabled Modules**

This document lists all enabled modules in the NixOS configuration with their purposes and current settings.

### 🏗️ **Core System Modules**

#### **Essential Infrastructure**
- ✅ `hardware-configuration.nix` - Auto-generated hardware configuration
- ✅ `modules/boot.nix` - Boot loader and GRUB configuration
  - GRUB with 40 generations, dark theme, memtest86
- ✅ `modules/boot-enhancements.nix` - Additional boot optimizations  
- ✅ `modules/system-base.nix` - Basic system settings (hostname, timezone, locale)

#### **Hardware & Drivers**
- ✅ `modules/hardware.nix` - Hardware support and drivers
  - Bluetooth: ✅ Enabled
  - Audio: ⚠️ Currently disabled  
  - Input devices: ✅ Enabled
  - Graphics: ✅ Enabled
- ✅ `modules/wayland.nix` - Wayland optimizations
- ✅ `modules/lenovo-s540-gtx-15iwl.nix` - Laptop-specific optimizations

#### **Display & Desktop**
- ✅ `modules/display-manager.nix` - Display manager configuration
- ✅ `modules/gnome-extensions.nix` - GNOME Shell extensions
- ✅ `modules/gtk-enhanced.nix` - GTK theming and enhancements

### 🔐 **Security & Authentication**

#### **Security Framework**
- ✅ `modules/security.nix` - Core security configuration
  - AppArmor: ✅ Enabled
  - Sudo: ✅ Enabled (no password for wheel)
  - PAM: ✅ Enabled
- ✅ `modules/security-services.nix` - Security services
- ✅ `modules/user-security.nix` - User-specific security
- ✅ `modules/pam-consolidated.nix` - **⚠️ CONFLICT DETECTED**

#### **User Management**
- ✅ `modules/users.nix` - User account management
- ✅ `modules/device-permissions.nix` - Device access permissions

### 🌐 **Network & Services**

#### **Network Configuration**
- ✅ `modules/networking.nix` - Network configuration
  - NetworkManager: ✅ Enabled
  - Firewall: ✅ Enabled (ports 22, 53)
  - DNS: systemd-resolved

#### **System Services**
- ✅ `modules/system-services.nix` - Core system services
- ✅ `modules/system-optimization.nix` - System optimizations

### 📦 **Package Management**

#### **Package Collections**
- ✅ `modules/core-packages.nix` - Essential packages
- ✅ `modules/optional-packages.nix` - Optional packages  
- ✅ `modules/package-recommendations.nix` - AI-driven package recommendations
- ✅ `modules/pentest.nix` - Penetration testing tools

#### **Package Categories (from custom.packages)**
- ✅ `minimal.enable = true` - Essential system packages
- ✅ `core.enable = true` - Core system packages  
- ✅ `productivity.enable = true` - Productivity packages
- ✅ `development.enable = true` - Development packages
- ✅ `media.enable = true` - Media packages
- ✅ `entertainment.enable = true` - Entertainment packages
- ✅ `popular.enable = true` - Popular packages
- ✅ `gaming.enable = true` - Gaming packages

### 🖥️ **Desktop Environment**

#### **Desktop Framework** 
- ✅ `custom.desktop.enable = true` - Desktop environment
  - Wayland: ✅ Enabled
  - GNOME: ✅ Enabled
  - Extensions: ✅ Enabled
  - Exclude Apps: ✅ Enabled
  - Theme: ✅ Enabled

#### **Shell & Terminal**
- ✅ `modules/shell-environment.nix` - Enhanced shell environment
  - Starship prompt: ✅ Enabled
  - Modern CLI tools: ✅ Enabled (bat, eza, fd, ripgrep, fzf)
  - Aliases: ✅ Enabled

### 🔧 **Development & Applications**

#### **Development Tools**
- ✅ `modules/ai-services.nix` - AI/ML development services
  - Ollama: ✅ Enabled (CUDA acceleration)
  - NVIDIA: ✅ Enabled (stable package)
- ✅ `modules/nixai-integration.nix` - NixAI integration
- ✅ `modules/void-editor.nix` - Void Editor for development
- ✅ `modules/electron-apps.nix` - Electron applications with Wayland
  - Discord, Chromium, VS Code: ✅ Enabled

#### **Virtualization & Containers**
- ✅ `modules/virtualization.nix` - Virtualization support
  - VirtualBox: ✅ Enabled
  - KVM: ✅ Enabled  
  - libvirt: ✅ Enabled
- ✅ `modules/containers.nix` - Container support
  - Docker: ✅ Enabled
  - Podman: ❌ Disabled (avoid conflicts)

#### **Windows Compatibility**
- ✅ `modules/wine-support.nix` - Wine configuration
- ✅ `modules/windows-compatibility.nix` - Windows app layer
  - .NET Framework: ✅ Enabled (4.8, 3.5)
  - Wine prefixes: ✅ Configured for different app types

### 🔧 **System Utilities**

#### **Graphics & Compatibility**
- ✅ `modules/nixgl.nix` - Graphics compatibility layer
  - Vulkan: ✅ Enabled
  - Application wrappers: ✅ Enabled

#### **Storage & Binding**
- ✅ `modules/custom-binding.nix` - SSD2 bind mounts
  - /tmp → /mnt/ssd2/tmp: ✅ Enabled
  - /var → /mnt/ssd2/var: ✅ Enabled

#### **Helper Tools**
- ✅ `modules/migration-assistant.nix` - System migration tools
- ❌ `modules/home-manager-integration.nix` - **DISABLED** (permission issues)
- ❌ `modules/nvidia-performance.nix` - **DISABLED** (commented out)

## ⚠️ **Known Issues & Conflicts**

### **PAM Configuration Conflicts**
- **Issue**: Both `modules/pam-consolidated.nix` and main `configuration.nix` set GNOME Keyring
- **Location**: Lines 668-673 in configuration.nix vs. pam-consolidated.nix
- **Fix Needed**: Remove duplicate PAM configuration

### **Health Monitoring Duplication**
- **Issue**: Both manual health-monitor services and new module exist
- **Location**: Lines 322-338 in configuration.nix  
- **Fix Needed**: Remove manual setup, use new module

### **Potential dbus Issues**
- **Source**: Multiple service configurations may conflict
- **Related**: Wine services, GNOME services, system services

## 🎯 **Recommended Module Structure**

### **Keep Enabled (Essential)**
```bash
# Core System (7 modules)
boot.nix, system-base.nix, hardware.nix, networking.nix
security.nix, users.nix, device-permissions.nix

# Desktop Environment (4 modules)  
display-manager.nix, wayland.nix, gnome-extensions.nix, gtk-enhanced.nix

# Package Management (3 modules)
core-packages.nix, optional-packages.nix, shell-environment.nix

# Development (3 modules)
ai-services.nix, electron-apps.nix, void-editor.nix

# Virtualization (2 modules)
virtualization.nix, containers.nix

# System Health (1 new module)
health-monitoring.nix
```

### **Consider Disabling (Complexity Reduction)**
```bash
# Heavy/Complex modules that could be simplified
wine-support.nix, windows-compatibility.nix
package-recommendations.nix, migration-assistant.nix  
nixai-integration.nix, lenovo-s540-gtx-15iwl.nix

# Problematic modules
home-manager-integration.nix (permission issues)
pam-consolidated.nix (conflicts with main config)
```

## 📊 **Module Statistics**

- **Total Imported Modules**: 25
- **Currently Enabled**: 20+  
- **Known Conflicts**: 2-3
- **Recommended for Cleanup**: 6-8

---

**Created**: $(date)  
**Status**: Analysis Complete - Ready for Simplification
