# Touchpad and Gesture Fixes for Lenovo S540 GTX 15IWL

## 🎯 Problem Description

The Lenovo S540 GTX 15IWL laptop commonly experiences touchpad issues including:
- **Scrolling not working** (two-finger scroll)
- **Gestures not responding** (pinch, swipe, rotate)
- **Touchpad sensitivity issues**
- **Permission problems** with input devices
- **Libinput conflicts** with older drivers

## ✅ Solutions Implemented

### 1. Enhanced Libinput Configuration
- **Modern touchpad support** with libinput
- **Lenovo-specific optimizations** for S540 hardware
- **Gesture recognition** enabled by default
- **Horizontal scrolling** support
- **Natural scrolling** enabled

### 2. Touchpad Packages Added
- `libinput` - Modern input device handling
- `touchegg` - Advanced gesture recognition
- `xorg.xinput` - Input device management
- `synaptics` - Legacy touchpad support (fallback)

### 3. Configuration Files Created
- **Libinput gestures configuration**
- **TouchEgg configuration** for advanced gestures
- **Touchpad permissions** fixed
- **User input group** membership

## 🚀 How to Use

### Quick Fix Script
```bash
# Run the dedicated touchpad fix script
./scripts/fix-touchpad.sh all

# Or run specific fixes
./scripts/fix-touchpad.sh detect      # Detect devices
./scripts/fix-touchpad.sh permissions # Fix permissions
./scripts/fix-touchpad.sh modules     # Reload modules
./scripts/fix-touchpad.sh config      # Create config
./scripts/fix-touchpad.sh test        # Test functionality
```

### Lenovo Performance Script
```bash
# Run the main Lenovo optimization script
./scripts/lenovo-performance.sh all

# Or specifically fix touchpad
./scripts/lenovo-performance.sh touchpad
```

## 🔧 What Each Fix Does

### 1. **Detect Touchpad**
- Lists all input devices
- Shows touchpad information
- Displays libinput device details

### 2. **Fix Permissions**
- Sets correct input device permissions (644)
- Adds user to input group
- Fixes ownership issues

### 3. **Reload Modules**
- Reloads libinput kernel module
- Reloads psmouse module if needed
- Ensures clean module state

### 4. **Create Configuration**
- Creates libinput gestures config
- Creates TouchEgg configuration
- Sets up proper touchpad settings

### 5. **Restart Services**
- Restarts TouchEgg service
- Restarts GNOME shell
- Reloads input services

### 6. **Test Functionality**
- Tests scrolling with two fingers
- Tests tapping and clicking
- Tests gesture recognition
- Shows current touchpad properties

## 📁 Configuration Files Created

### Libinput Gestures Config
**Location**: `~/.config/libinput/gestures.conf`
- Enables swipe gestures (3 fingers)
- Enables pinch gestures (2 fingers)
- Enables rotation gestures (2 fingers)
- Configures touchpad sensitivity

### TouchEgg Config
**Location**: `~/.config/touchegg/touchegg.conf`
- Two-finger drag to move windows
- Two-finger pinch to resize windows
- Three-finger swipe to switch desktops
- Four-finger swipe to show desktop

## 🎮 Gesture Support

### **Two-Finger Gestures**
- **Scroll**: Vertical and horizontal scrolling
- **Drag**: Move windows around
- **Pinch**: Resize windows
- **Rotate**: Rotate windows

### **Three-Finger Gestures**
- **Swipe Left/Right**: Switch between desktops
- **Tap**: Right-click (middle mouse button)
- **Swipe Up**: Show overview
- **Swipe Down**: Hide windows

### **Four-Finger Gestures**
- **Swipe Up**: Show desktop
- **Swipe Down**: Show all windows
- **Swipe Left/Right**: Switch workspaces

## 🛠️ Troubleshooting

### If Touchpad Still Doesn't Work

1. **Check device detection**:
   ```bash
   ./scripts/fix-touchpad.sh detect
   ```

2. **Verify permissions**:
   ```bash
   ls -la /dev/input/event*
   groups $USER
   ```

3. **Check kernel modules**:
   ```bash
   lsmod | grep -E "(libinput|psmouse|synaptics)"
   ```

4. **Restart GNOME shell**:
   ```bash
   killall -HUP gnome-shell
   ```

5. **Log out and back in** to ensure group changes take effect

### Common Issues and Solutions

#### **Permission Denied Errors**
```bash
sudo chmod 644 /dev/input/event*
sudo chown root:input /dev/input/event*
sudo usermod -a -G input $USER
```

#### **Module Not Found**
```bash
sudo modprobe libinput
sudo modprobe psmouse
```

#### **Service Not Starting**
```bash
sudo systemctl enable touchegg
sudo systemctl start touchegg
```

## 🔄 After Applying Fixes

### **Immediate Effects**
- Touchpad scrolling should work
- Basic gestures should respond
- Permissions should be correct

### **May Require Restart**
- GNOME shell restart
- User logout/login
- Full system reboot

### **Verification**
- Test two-finger scrolling
- Test three-finger gestures
- Check touchpad sensitivity
- Verify gesture recognition

## 📋 System Requirements

- **NixOS 25.05** or later
- **GNOME desktop** environment
- **Libinput** support enabled
- **TouchEgg** service running
- **User in input group**

## 🎯 Expected Results

After applying all fixes, you should have:
- ✅ **Smooth two-finger scrolling**
- ✅ **Responsive gesture recognition**
- ✅ **Proper touchpad sensitivity**
- ✅ **Working multi-touch gestures**
- ✅ **No permission errors**
- ✅ **Stable input handling**

## 🆘 Getting Help

If issues persist after applying all fixes:

1. **Check system logs**:
   ```bash
   journalctl -u touchegg
   journalctl -u display-manager
   ```

2. **Verify hardware detection**:
   ```bash
   sudo libinput list-devices
   xinput list
   ```

3. **Test with different configurations**:
   ```bash
   ./scripts/fix-touchpad.sh config
   ./scripts/fix-touchpad.sh test
   ```

4. **Consider hardware issues** if software fixes don't work

---

**Note**: These fixes are specifically optimized for the Lenovo S540 GTX 15IWL laptop. Results may vary on other hardware configurations.