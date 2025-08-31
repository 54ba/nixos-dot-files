# NixOS Boot Failure Debug Analysis Guide

This guide helps you analyze the debug logs collected by the debug-boot-failure.sh script to identify boot issues.

## 🎯 Quick Start

After a boot failure, run:
```bash
sudo /etc/nixos/scripts/debug-boot-failure.sh
```

Then examine the logs in the created debug directory.

## 📂 Log Files Overview

### Critical Files to Check First:
1. **`boot-logs.log`** - Complete boot process logs
2. **`kernel-logs.log`** - Kernel messages (dmesg output)  
3. **`failed-services.log`** - Services that failed to start
4. **`kernel-params-comparison.log`** - Parameter differences between generations

### Supporting Files:
- **`graphics-info.log`** - Graphics hardware and driver status
- **`acpi-info.log`** - ACPI errors and power management issues
- **`hardware-info.log`** - Hardware detection and module loading
- **`generation-info.log`** - Generation and boot entry information

## 🔍 Analysis Checklist

### 1. Boot Process Analysis (`boot-logs.log`)
Look for these patterns:

**❌ Boot Failures:**
```
● Failed to start [service-name]
systemd[1]: [service] failed with result 'exit-code'
Kernel panic
BUG: unable to handle page fault
```

**❌ Graphics Issues:**
```
(EE) NVIDIA: Failed to initialize
drm: failed to load driver
nouveau: probe failed
gdm: can't connect to display
```

**❌ ACPI Problems:**
```
ACPI Error: AE_ALREADY_EXISTS
ACPI BIOS Error
acpi PNP0A08: _OSC failed
```

### 2. Kernel Messages Analysis (`kernel-logs.log`)
Search for:

**❌ Critical Errors:**
```bash
grep -i "panic\|oops\|bug\|error\|failed\|timeout" kernel-logs.log
```

**🔧 Driver Issues:**
```bash
grep -i "nvidia\|nouveau\|i915\|drm" kernel-logs.log
```

### 3. Service Failures Analysis (`failed-services.log`)
Common problematic services:
- **gdm.service** - Display manager issues
- **NetworkManager.service** - Network problems
- **systemd-modules-load.service** - Module loading failures
- **nvidia-***.service** - NVIDIA driver services

### 4. Kernel Parameter Comparison (`kernel-params-comparison.log`)
Compare parameters between:
- Generation 16 (known working)
- Current failing generation

Look for:
- **Duplicated parameters** (same parameter multiple times)
- **Conflicting parameters** (nvidia.drm.modeset=0 AND nvidia-drm.modeset=1)
- **Missing parameters** that were present in Gen 16

## 🚨 Common Boot Failure Patterns

### Pattern 1: NVIDIA Driver Conflicts
**Symptoms:**
- Black screen after GRUB
- Display manager fails to start
- Graphics driver errors in logs

**Look for:**
```
nouveau 0000:02:00.0: unknown chipset
nvidia: probe of 0000:02:00.0 failed
gdm[pid]: Unable to run X server
```

**Solution:** Check driver blacklisting and parameter conflicts

### Pattern 2: ACPI Compatibility Issues  
**Symptoms:**
- Hangs during early boot
- Hardware detection failures
- Power management errors

**Look for:**
```
ACPI Error: AE_ALREADY_EXISTS
ACPI BIOS Error (bug): Failure creating named object
```

**Solution:** Adjust acpi_osi parameters

### Pattern 3: systemd Service Cascade Failures
**Symptoms:**
- Services fail to start in sequence
- Long timeouts during boot
- Eventually drops to emergency shell

**Look for:**
```
Dependency failed for [service]
[service] start request repeated too quickly
Job [service] timeout
```

**Solution:** Identify the root failing service

### Pattern 4: Kernel Module Loading Issues
**Symptoms:**
- Hardware not detected
- Driver functionality missing
- Kernel warnings/errors

**Look for:**
```
modprobe: FATAL: Module not found
Unknown symbol in module
module verification failed
```

**Solution:** Check module configuration and dependencies

## 🔧 Specific Debug Commands

### Check NVIDIA Status:
```bash
lsmod | grep nvidia
lsmod | grep nouveau
nvidia-smi  # (if drivers loaded)
```

### Check Display Manager:
```bash
systemctl status gdm
journalctl -u gdm --no-pager
```

### Check Graphics Stack:
```bash
lspci | grep VGA
ls /sys/class/drm/card*/device/power_state
echo $WAYLAND_DISPLAY $DISPLAY
```

### Check Boot Timeline:
```bash
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
```

## 📋 Analysis Workflow

1. **Start with `SUMMARY.log`** - Overview of collected data
2. **Check `failed-services.log`** - Identify failed services  
3. **Review `boot-logs.log`** - Find error patterns
4. **Compare `kernel-params-comparison.log`** - Spot parameter issues
5. **Examine service-specific logs** based on failures found
6. **Cross-reference with `graphics-info.log`** for driver issues

## 💡 Tips for Effective Analysis

- **Use grep extensively**: `grep -i "error\|failed\|timeout" file.log`
- **Look for timestamps**: Identify when failures occur in boot sequence
- **Check dependencies**: Failed service might depend on another failed service
- **Compare working vs failing**: Use Gen 16 as baseline
- **Focus on first failure**: Often subsequent failures are cascading effects

## 🆘 Emergency Recovery

If analysis shows system corruption or severe issues:

1. **Boot Generation 16** (known working)
2. **Backup current config**: `cp -r /etc/nixos /etc/nixos-backup-$(date +%Y%m%d)`
3. **Reset to minimal config** if needed
4. **Test step-by-step** re-enabling features one by one

## 📞 Getting Help

When seeking help, include:
- Output of `debug-boot-failure.sh`
- Specific error messages from logs
- Hardware information (`lspci`, `lsusb`)
- Generation comparison results
- Steps that led to the failure

---

**Remember:** The most important logs are usually `boot-logs.log` and `failed-services.log`. Start there!
