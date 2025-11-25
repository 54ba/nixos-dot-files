{ config, pkgs, lib, ... }:

{
  # Fix Nix store permissions on boot
  # This service ensures the Nix store has correct permissions after system crashes or corruption
  
  systemd.services.fix-nix-store-permissions = {
    description = "Fix Nix Store Permissions";
    wantedBy = [ "multi-user.target" ];
    before = [ "nix-daemon.service" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-nix-store-permissions" ''
        set -e
        
        echo "Fixing Nix store permissions..."
        
        # Ensure /nix/store is writable (remount if needed)
        if mount | grep -q '/nix/store.*ro,'; then
          echo "Remounting /nix/store as read-write..."
          mount -o remount,rw /nix/store || true
        fi
        
        # Fix any directories with incorrect 0644 permissions
        echo "Fixing directory permissions in /nix/store..."
        find /nix/store -type d -perm 0644 -exec chmod 0755 {} + 2>/dev/null || true
        
        # Ensure /nix/var/nix has correct permissions
        echo "Fixing /nix/var/nix permissions..."
        chown -R root:root /nix/var/nix 2>/dev/null || true
        chmod 755 /nix/var/nix 2>/dev/null || true
        
        # Fix daemon-socket directory
        if [ -d /nix/var/nix/daemon-socket ]; then
          chown root:nix /nix/var/nix/daemon-socket 2>/dev/null || true
          chmod 775 /nix/var/nix/daemon-socket 2>/dev/null || true
        fi
        
        # Fix db directory
        if [ -d /nix/var/nix/db ]; then
          chown -R root:root /nix/var/nix/db 2>/dev/null || true
          chmod -R 755 /nix/var/nix/db 2>/dev/null || true
        fi
        
        # Fix profiles directory
        if [ -d /nix/var/nix/profiles ]; then
          chown -R root:root /nix/var/nix/profiles 2>/dev/null || true
          chmod -R 755 /nix/var/nix/profiles 2>/dev/null || true
        fi
        
        # Fix gcroots directory
        if [ -d /nix/var/nix/gcroots ]; then
          chown -R root:root /nix/var/nix/gcroots 2>/dev/null || true
          chmod -R 755 /nix/var/nix/gcroots 2>/dev/null || true
        fi
        
        # Fix temproots directory (should be accessible by users)
        if [ -d /nix/var/nix/temproots ]; then
          chmod 1777 /nix/var/nix/temproots 2>/dev/null || true
        fi
        
        # Ensure the .links directory has correct permissions (but is read-only)
        if [ -d /nix/store/.links ]; then
          chmod 755 /nix/store/.links 2>/dev/null || true
        fi
        
        echo "Nix store permissions fixed successfully!"
      '';
    };
  };
  
  # Also ensure proper Nix daemon configuration
  nix.settings = {
    # Ensure the build users are in the right group
    trusted-users = [ "root" "@wheel" ];
    allowed-users = [ "@users" "@wheel" ];
    
    # Ensure proper sandbox settings
    sandbox = true;
    
    # Auto-optimize store (deduplicate files)
    auto-optimise-store = true;
  };
  
  # Ensure nix group exists
  users.groups.nix = {};
}
