# NVIDIA Monitoring Guide

## Overview

The NVIDIA performance module has been enhanced with system-wide monitoring capabilities that are safe and stable. The monitoring is **disabled by default** to ensure reliable booting, but can be easily enabled when needed.

## Current Status

- **NVIDIA Performance**: ✅ Enabled (gaming, DLSS, ray tracing)
- **NVIDIA Monitoring**: ❌ Disabled (for boot safety)
- **Available Tools**: nvitop, gpustat, nvidia-smi
- **System Generation**: 110 (stable)

## Available Monitoring Tools

When monitoring is enabled, the following tools are available:

### 1. nvitop - Interactive GPU Process Monitor
```bash
nvitop                    # Interactive GPU monitoring
nvitop --once            # One-time snapshot
```

### 2. gpustat - Simple GPU Statistics
```bash
gpustat                  # Basic GPU status
gpustat --watch         # Continuous monitoring
```

### 3. nvidia-smi - NVIDIA System Management
```bash
nvidia-smi              # Basic GPU information
nvidia-smi -l 1         # Continuous monitoring (1 second intervals)
```

## How to Enable Monitoring

To safely enable NVIDIA monitoring:

1. **Edit the configuration** in `/etc/nixos/configuration.nix`:
   ```nix
   custom.nvidiaPerformance = {
     enable = true;
     monitoring = {
       enable = true;        # Enable monitoring packages
       autoStart = false;    # Keep auto-start disabled for safety
       tools = {
         nvitop = true;      # Enable nvitop
         nvtop = true;       # Enable nvtop (if available)  
         gpustat = true;     # Enable gpustat
       };
     };
   };
   ```

2. **Rebuild the system**:
   ```bash
   sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}
   ```

3. **Test the tools**:
   ```bash
   nvitop --once           # Test nvitop
   gpustat                 # Test gpustat
   nvidia-smi              # Test nvidia-smi
   ```

## How to Disable Monitoring

To disable monitoring and return to the safe configuration:

1. **Edit the configuration**:
   ```nix
   custom.nvidiaPerformance = {
     enable = true;
     monitoring = {
       enable = false;       # Disable monitoring packages
       autoStart = false;    # Keep auto-start disabled
     };
   };
   ```

2. **Rebuild the system**:
   ```bash
   sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}
   ```

## Advanced Monitoring Options

The nvidia-performance module supports additional monitoring features:

### System-wide Monitoring Services

For automatic GPU statistics logging:

```nix
custom.nvidiaPerformance = {
  monitoring = {
    enable = true;
    autoStart = true;     # Enable automatic monitoring services
  };
};
```

This will start system services that log GPU statistics to the journal:
```bash
journalctl -u nvidia-smi-logger -f
```

### Individual Tool Control

You can enable/disable specific monitoring tools:

```nix
custom.nvidiaPerformance = {
  monitoring = {
    enable = true;
    tools = {
      nvitop = true;        # Enable nvitop
      nvtop = false;        # Disable nvtop
      gpustat = true;       # Enable gpustat
    };
  };
};
```

## Troubleshooting

### Boot Issues
If you experience boot issues after enabling monitoring:

1. **Boot to a previous generation** from the GRUB menu
2. **Disable monitoring** in the configuration
3. **Rebuild** the system

### Package Issues
If monitoring packages fail to install:

1. **Check package availability**:
   ```bash
   nix search nixpkgs nvitop
   nix search nixpkgs gpustat
   ```

2. **Update the flake**:
   ```bash
   nix flake update
   ```

## Performance Impact

- **nvitop**: Minimal impact, efficient monitoring
- **gpustat**: Very low impact, simple tool
- **nvidia-smi-logger**: Low impact, logs to journal
- **Auto-start services**: Minimal impact when enabled

## Security Considerations

- Monitoring services run as system services
- No network exposure by default
- Log data stored in systemd journal (automatically rotated)
- Tools require GPU access permissions

## Generation History

- **Generation 107**: Failed (nvidia monitoring caused boot issues)
- **Generation 108-109**: Fixed and tested nvidia-performance module
- **Generation 110**: Current stable configuration with optional monitoring

This configuration resolves the boot failures from generation 107 while providing safe, optional monitoring capabilities.
