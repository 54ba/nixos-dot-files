{ config, pkgs, lib, ... }:

{
  # Systematic Nix store permissions fix
  # This module ensures proper permissions without heavy boot-time operations
  
  # Use systemd tmpfiles for lightweight permission fixes
  systemd.tmpfiles.rules = [
    # Nix database permissions
    "d /nix/var/nix/db 0755 root root -"
    "z /nix/var/nix/db/big-lock 0644 root root -"
    
    # Nix daemon socket
    "d /nix/var/nix/daemon-socket 0755 root nix -"
    
    # Nix profiles - allow users to create profiles
    "d /nix/var/nix/profiles 0755 root root -"
    "d /nix/var/nix/profiles/per-user 0755 root root -"
    
    # GC roots
    "d /nix/var/nix/gcroots 0755 root root -"
    "d /nix/var/nix/gcroots/per-user 0755 root root -"
    
    # Temproots - needs to be world-writable with sticky bit
    "d /nix/var/nix/temproots 1777 root root -"
    
    # Ensure fuse device has proper permissions for Flatpak
    "z /dev/fuse 0666 root root -"
  ];
  
  # Proper Nix daemon configuration for multi-user setup
  nix.settings = {
    # Users who can use Nix features that can break sandbox
    trusted-users = [ "root" "@wheel" ];
    
    # Users allowed to connect to Nix daemon
    allowed-users = [ "@users" "@wheel" ];
    
    # Keep store paths owned by root for security
    build-users-group = "nixbld";
  };
  
  # Ensure the Nix daemon uses proper permissions
  systemd.services.nix-daemon = {
    serviceConfig = {
      # Ensure daemon can access store
      ReadWritePaths = [ "/nix/store" "/nix/var" ];
    };
  };
  
  # One-time fix script (run manually if needed, not on boot)
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "fix-nix-permissions" ''
      #!/usr/bin/env bash
      # Manual Nix store permissions fix script
      # Run this only if you have permission issues
      
      set -e
      
      echo "🔧 Fixing Nix store permissions..."
      
      # Check if running as root
      if [ "$EUID" -ne 0 ]; then 
        echo "❌ Please run as root: sudo fix-nix-permissions"
        exit 1
      fi
      
      # Remount /nix/store as read-write if needed
      if mount | grep -q '/nix/store.*\bro\b'; then
        echo "📁 Remounting /nix/store as read-write..."
        mount -o remount,rw /nix/store || {
          echo "⚠️  Warning: Could not remount /nix/store"
        }
      fi
      
      # Fix any directories with wrong permissions (only if there are many)
      BAD_DIRS=$(find /nix/store -type d -perm 0644 2>/dev/null | wc -l)
      if [ "$BAD_DIRS" -gt 0 ]; then
        echo "📂 Found $BAD_DIRS directories with wrong permissions, fixing..."
        find /nix/store -type d -perm 0644 -exec chmod 0755 {} + 2>/dev/null || true
        echo "✅ Fixed directory permissions"
      else
        echo "✅ Store directory permissions are correct"
      fi
      
      # Fix /nix/var/nix permissions
      echo "🗂️  Fixing /nix/var/nix structure..."
      
      # Database
      if [ -d /nix/var/nix/db ]; then
        chmod 0755 /nix/var/nix/db
        chown -R root:root /nix/var/nix/db
        chmod 0644 /nix/var/nix/db/big-lock 2>/dev/null || true
      fi
      
      # Daemon socket
      if [ -d /nix/var/nix/daemon-socket ]; then
        chmod 0755 /nix/var/nix/daemon-socket
        chown root:nix /nix/var/nix/daemon-socket
      fi
      
      # Profiles
      if [ -d /nix/var/nix/profiles ]; then
        chmod 0755 /nix/var/nix/profiles
        chown root:root /nix/var/nix/profiles
        
        # Per-user profiles
        if [ -d /nix/var/nix/profiles/per-user ]; then
          chmod 0755 /nix/var/nix/profiles/per-user
          # Each user's profile directory should be owned by them
          for userdir in /nix/var/nix/profiles/per-user/*; do
            if [ -d "$userdir" ]; then
              username=$(basename "$userdir")
              if id "$username" &>/dev/null; then
                chown -R "$username:users" "$userdir"
                chmod 0755 "$userdir"
              fi
            fi
          done
        fi
      fi
      
      # GC roots
      if [ -d /nix/var/nix/gcroots ]; then
        chmod 0755 /nix/var/nix/gcroots
        chown root:root /nix/var/nix/gcroots
        
        # Per-user gcroots
        if [ -d /nix/var/nix/gcroots/per-user ]; then
          chmod 0755 /nix/var/nix/gcroots/per-user
        fi
      fi
      
      # Temproots (world-writable with sticky bit)
      if [ -d /nix/var/nix/temproots ]; then
        chmod 1777 /nix/var/nix/temproots
      fi
      
      # Fix fuse permissions
      if [ -e /dev/fuse ]; then
        chmod 0666 /dev/fuse
        echo "✅ Fixed /dev/fuse permissions"
      fi
      
      echo ""
      echo "✅ Nix permissions fixed successfully!"
      echo ""
      echo "💡 If you still have issues:"
      echo "   1. Restart Nix daemon: sudo systemctl restart nix-daemon"
      echo "   2. Re-login to pick up group changes"
      echo "   3. Make sure NIX_REMOTE=daemon is set: echo \$NIX_REMOTE"
      echo ""
    '')
  ];
  
  # Ensure nix group exists
  users.groups.nix = {};
  
  # Add a systemd service that runs ONCE on first boot after this module is added
  # This is safer than running on every boot
  systemd.services.nix-permissions-first-boot = {
    description = "One-time Nix Permissions Fix (First Boot)";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    before = [ "nix-daemon.service" ];
    
    # Run only once using a condition file
    unitConfig = {
      ConditionPathExists = "!/var/lib/nix-permissions-fixed";
    };
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-nix-permissions-once" ''
        # Quick permission fix on first boot only
        echo "Running one-time Nix permissions fix..."
        
        # Fix critical permissions only
        chmod 0755 /nix/var/nix/db 2>/dev/null || true
        chmod 1777 /nix/var/nix/temproots 2>/dev/null || true
        chmod 0666 /dev/fuse 2>/dev/null || true
        
        # Mark as completed
        touch /var/lib/nix-permissions-fixed
        
        echo "One-time fix completed. Future boots will skip this."
      '';
    };
  };
}

