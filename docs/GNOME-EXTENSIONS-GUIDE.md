# 🎨 Beautiful GNOME Extensions Guide

## Overview
This configuration includes a curated collection of the most beautiful and useful GNOME extensions from [extensions.gnome.org](https://extensions.gnome.org/).

## 📦 Available Presets

### 1. **Minimal** - Performance First
Perfect for low-end hardware or users who want maximum performance.
- AppIndicator (tray icons)
- Dash to Dock (essential dock)
- User Themes (theme support)
- Caffeine (prevent sleep)

### 2. **Beautiful** - Aesthetics First ⭐
The most visually stunning setup with animations and effects.
- Blur My Shell - Beautiful blur effects
- Burn My Windows - Window open/close animations
- Compiz-alike Magic Lamp Effect - Smooth minimize
- Coverflow Alt-Tab - 3D window switcher
- Dash to Dock - Elegant dock
- Rounded Window Corners - Modern rounded corners
- Panel Corners - Rounded panel edges
- Just Perfection - Shell customization
- Vitals - Beautiful system monitor
- Media Controls - Media player integration
- User Themes - Theme support
- AppIndicator - Tray icons

### 3. **Productivity** - Work Focused
Optimized for maximum productivity and workflow.
- Dash to Panel - Windows-like taskbar
- Pop Shell - Automatic tiling
- Clipboard Indicator - Clipboard history
- Vitals - System monitoring
- GSConnect - Android integration
- Just Perfection - Customization
- Tiling Assistant - Smart tiling
- AppIndicator - Tray support
- Bluetooth Quick Connect
- Window List

### 4. **macOS-like** - Apple Experience
Familiar interface for macOS users.
- Dash to Dock - macOS-style dock
- Blur My Shell - Translucent effects
- Rounded Window Corners
- Unite - Merged title bars
- Coverflow Alt-Tab
- Just Perfection
- User Themes
- AppIndicator
- Media Controls

### 5. **Windows-like** - Microsoft Experience
Familiar interface for Windows users.
- Dash to Panel - Windows taskbar
- Arc Menu - Start menu
- Window List - Task buttons
- Desktop Icons - Desktop icons
- AppIndicator - System tray
- Clipboard Indicator
- Quick Settings Tweaker

### 6. **Gaming** - Game Performance
Optimized for gaming with performance tools.
- GameMode indicator
- Caffeine (prevent sleep)
- GPU Profile Selector
- CPU Power Manager
- Vitals (monitor resources)
- AppIndicator
- Just Perfection

## 🎯 Extension Categories

### 🌟 Beauty & Visual Enhancements
- **Blur My Shell** - Beautiful blur effects (use with caution on older hardware)
- **Burn My Windows** - Fire, TV effect, and more for window animations
- **Compiz-alike Magic Lamp Effect** - Smooth genie-like minimize animation
- **Compiz Windows Effect** - Wobbly windows when moving
- **Desktop Cube** - 3D desktop cube workspace switcher
- **Coverflow Alt-Tab** - 3D carousel window switcher
- **Rounded Window Corners** - Modern rounded corners for all windows
- **Panel Corners** - Rounded corners for the top panel

### 💼 Productivity
- **Dash to Dock** - The essential dock (like macOS or Ubuntu)
- **Dash to Panel** - Integrate dock into panel (like Windows)
- **AppIndicator** - System tray icon support (essential!)
- **Caffeine** - Prevent automatic suspend/sleep
- **Clipboard Indicator** - Clipboard history manager
- **Desktop Icons NG** - Desktop icons support
- **Just Perfection** - Customize every aspect of GNOME Shell
- **Pop Shell** - Automatic tiling from System76
- **Unite** - Remove window decorations and merge with top bar

### 🪟 Window Management
- **Space Bar** - Beautiful workspace indicator
- **Workspace Matrix** - 2D workspace grid
- **Window List** - Show window buttons in panel
- **gTile** - Advanced window tiling with grid
- **Tiling Assistant** - Smart window tiling helper
- **Auto Move Windows** - Automatically move apps to specific workspaces

### 📊 System Monitoring
- **Vitals** - Beautiful all-in-one system monitor ⭐
- **System Monitor Next** - Advanced resource monitoring
- **TopHat** - Gorgeous resource monitor
- **CPU Power Manager** - Control CPU power profiles
- **GPU Profile Selector** - Switch GPU profiles (NVIDIA/AMD)
- **Freon** - Temperature monitoring

### 🎨 Interface Enhancements
- **Arc Menu** - Beautiful application menu with search
- **User Themes** - Enable custom shell themes
- **Bluetooth Quick Connect** - Quick Bluetooth device management
- **Quick Settings Tweaker** - Customize quick settings panel
- **Logo Menu** - Replace "Activities" with a custom logo

### 🎵 Media & Audio
- **Media Controls** - Control media players from panel
- **Sound Output Device Chooser** - Quick audio output switcher
- **Volume Mixer** - Per-application volume control

### 🔔 Notifications
- **Notification Banner Reloaded** - Better notification positioning
- **Do Not Disturb Button** - Quick DND toggle
- **Night Theme Switcher** - Auto dark/light theme based on time

### 🛠️ Utilities
- **GSConnect** - Android integration (KDE Connect protocol)
- **Emoji Copy** - Quick emoji picker
- **Espresso** - Alternative caffeine extension
- **Removable Drive Menu** - USB drive quick access
- **Screenshot Tool** - Enhanced screenshots
- **Weather O'Clock** - Weather in clock area

### 🔋 Power Management
- **Battery Health Charging** - Protect battery health
- **Power Profile Switcher** - Quick power profile switching

## 🚀 Usage

### Enable Extensions

1. **Using a Preset** (Recommended for beginners):
```nix
custom.gnome.extensions = {
  enable = true;
  preset = "beautiful";  # Choose: minimal, beautiful, productivity, macos, windows, gaming
};
```

2. **Custom Configuration** (For advanced users):
```nix
custom.gnome.extensions = {
  enable = true;
  preset = "custom";
  
  categories = {
    beauty = true;         # Visual enhancements
    productivity = true;   # Productivity tools
    windows = true;        # Window management
    system = true;         # System monitoring
    interface = true;      # UI enhancements
    utilities = true;      # Utility extensions
  };
};
```

3. **With Settings**:
```nix
custom.gnome.extensions = {
  enable = true;
  preset = "beautiful";
  
  settings = {
    enable = true;
    dashToDock = {
      enable = true;
      position = "BOTTOM";     # LEFT, RIGHT, BOTTOM, TOP
      iconSize = 48;           # 16-64
      transparency = "DYNAMIC"; # FIXED, DYNAMIC, ADAPTIVE
    };
    vitals = {
      enable = true;
      showCpu = true;
      showMemory = true;
      showTemperature = true;
    };
  };
};
```

### Switch Between Niri and GNOME

**To use GNOME with beautiful extensions:**
```nix
# Disable Niri
custom.niri.enable = false;

# Enable GNOME with extensions
custom.desktop.gnome.enable = true;
custom.gnome.extensions.enable = true;
```

**To use Niri:**
```nix
# Enable Niri
custom.niri.enable = true;

# Disable GNOME extensions (optional, but recommended)
custom.gnome.extensions.enable = false;
```

## 📝 Notes

### Performance Considerations
- **Blur My Shell** can impact performance on older hardware - disable if you experience lag
- The **Beautiful** preset uses more resources than **Minimal**
- For gaming, use the **Gaming** preset which disables visual effects

### Compatibility
- All extensions are tested with GNOME 45/46
- Some extensions may not be available in older NixOS versions
- The configuration handles missing extensions gracefully with warnings

### Customization
You can add custom extensions not in the presets:
```nix
custom.gnome.extensions = {
  enable = true;
  preset = "beautiful";
  customList = [
    "another-extension"
    "custom-extension"
  ];
};
```

## 🎬 After Installation

1. **Rebuild your system:**
   ```bash
   sudo nixos-rebuild switch
   ```

2. **Log out and select GNOME session** (if using GNOME)

3. **Enable extensions in GNOME Tweaks:**
   - Open "Tweaks" or "Extensions" app
   - Toggle extensions on/off as desired
   - Configure extension settings

4. **Configure extensions:**
   - Most extensions have settings accessible via right-click on their icon
   - Or use the Extensions app (pre-installed)

## 🌐 Resources

- [GNOME Extensions Website](https://extensions.gnome.org/)
- [Extension Manager App](https://github.com/mjakeman/extension-manager)
- [GNOME Shell Extensions Guide](https://wiki.gnome.org/Projects/GnomeShell/Extensions)

## ⚡ Tips

1. **Start with a preset** and customize later
2. **Don't enable too many extensions** at once - it can impact performance
3. **Use Just Perfection** to fine-tune your desktop
4. **Vitals** is great for monitoring system resources
5. **Pop Shell** or **Tiling Assistant** for productive window management
6. **GSConnect** is amazing if you have an Android phone

## 🎨 Recommended Combinations

### For Beauty:
```
Beautiful preset + Custom GTK theme + Blur My Shell + Rounded Corners
```

### For Productivity:
```
Productivity preset + Pop Shell + Clipboard Indicator + Vitals
```

### For Gaming:
```
Gaming preset + GameMode + GPU Profile Selector
```

Enjoy your beautiful GNOME desktop! ✨
