{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.rescueSystem;
  
  # Enhanced rescue tools categorized by function
  networkTools = with pkgs; [
    # Network diagnostics and troubleshooting
    nettools         # ifconfig, route, netstat
    iproute2         # ip, ss, tc
    dnsutils         # dig, nslookup
    tcpdump          # packet capture
    wireshark-cli    # tshark for network analysis  
    nmap             # network discovery and security
    traceroute       # network path analysis
    mtr              # network diagnostic tool
    iperf3           # network performance testing
    wget curl        # download tools
    openssh          # ssh client
    wireguard-tools  # VPN tools
  ];
  
  diskTools = with pkgs; [
    # Disk and filesystem tools
    parted           # partition management
    gparted          # GUI partition manager
    gptfdisk         # GPT partition tools
    dosfstools       # FAT filesystem tools
    ntfs3g           # NTFS filesystem support
    exfat            # exFAT filesystem support
    e2fsprogs        # ext2/3/4 filesystem tools
    xfsprogs         # XFS filesystem tools
    btrfs-progs      # Btrfs filesystem tools
    zfsUnstable      # ZFS filesystem tools
    smartmontools    # disk health monitoring
    hdparm           # hard drive parameters
    ddrescue         # data recovery
    testdisk         # partition and data recovery (includes photorec)
    safecopy         # fault-tolerant disk copying
    rsync            # file synchronization
    lsof             # list open files
  ];
  
  systemTools = with pkgs; [
    # System diagnostics and repair
    htop btop        # process monitoring
    iotop            # I/O monitoring
    strace           # system call tracing
    ltrace           # library call tracing
    gdb              # debugger
    valgrind         # memory debugging
    perf-tools       # performance analysis
    sysstat          # system statistics
    procps           # process utilities
    psmisc           # process utilities
    lshw             # hardware information
    pciutils         # PCI utilities
    usbutils         # USB utilities
    dmidecode        # hardware information
    memtest86plus    # memory testing
    stress           # system stress testing
    bindfs           # filesystem in userspace
    squashfsTools    # compressed filesystem tools
  ];
  
  recoveryCLITools = with pkgs; [
    # Command-line recovery tools
    vim nano         # text editors
    tmux screen      # terminal multiplexers  
    bash zsh fish    # shells
    coreutils        # basic utilities
    findutils        # find utilities
    gnugrep ripgrep  # search tools
    gnused           # stream editor
    gawk             # text processing
    less             # pager
    tree             # directory tree
    file             # file type detection
    util-linux       # includes hexdump and other utilities
    binutils         # includes strings
    mc               # midnight commander
    ranger           # file manager
  ];
  
in {
  options.custom.rescueSystem = {
    enable = mkEnableOption "comprehensive rescue system with enhanced recovery capabilities";
    
    grub = {
      enableAdvancedMenu = mkOption {
        type = types.bool;
        default = true;
        description = "Enable advanced GRUB menu with generation sorting";
      };
      
      timeout = mkOption {
        type = types.int;
        default = 30;
        description = "GRUB menu timeout in seconds for rescue operations";
      };
      
      enableGenerationSorting = mkOption {
        type = types.bool;
        default = true;
        description = "Sort boot generations by date and group them";
      };
      
      rescueEntries = mkOption {
        type = types.bool;
        default = true;
        description = "Add dedicated rescue mode entries to GRUB menu";
      };
    };
    
    generations = {
      maxCount = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum number of generations to keep for recovery";
      };
      
      sortBy = mkOption {
        type = types.enum [ "date" "number" "size" ];
        default = "date";
        description = "Sort generations by date, number, or size";
      };
      
      groupBy = mkOption {
        type = types.enum [ "week" "month" "none" ];
        default = "week";
        description = "Group generations by week, month, or none";
      };
      
      autoCleanup = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically cleanup old generations beyond maxCount";
      };
    };
    
    rescueTools = {
      enable = mkEnableOption "comprehensive rescue tool suite";
      
      networkTools = mkOption {
        type = types.bool;
        default = true;
        description = "Include network diagnostic and recovery tools";
      };
      
      diskTools = mkOption {
        type = types.bool;
        default = true;
        description = "Include disk recovery and filesystem tools";
      };
      
      systemTools = mkOption {
        type = types.bool;
        default = true;
        description = "Include system diagnostic and repair tools";
      };
      
      developmentTools = mkOption {
        type = types.bool;
        default = false;
        description = "Include development and debugging tools";
      };
    };
    
    emergencyAccess = {
      enableRootShell = mkOption {
        type = types.bool;
        default = true;
        description = "Enable emergency root shell access in rescue mode";
      };
      
      enableNetworkAccess = mkOption {
        type = types.bool;
        default = true;
        description = "Enable network access in rescue mode";
      };
      
      enableSSH = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SSH access in rescue mode (security risk)";
      };
      
      allowPasswordAuth = mkOption {
        type = types.bool;
        default = true;
        description = "Allow password authentication in rescue mode";
      };
    };
    
    autoRescue = {
      enable = mkEnableOption "automatic rescue system activation on boot failures";
      
      bootFailureThreshold = mkOption {
        type = types.int;
        default = 3;
        description = "Number of boot failures before auto-rescue activation";
      };
      
      autoRepair = mkOption {
        type = types.bool;
        default = false;
        description = "Attempt automatic system repairs in rescue mode";
      };
    };
  };

  config = mkIf config.custom.rescueSystem.enable {
    # Enhanced GRUB configuration with rescue options
    boot.loader.timeout = mkDefault config.custom.rescueSystem.grub.timeout;
    boot.loader.grub = {
      
      # Custom GRUB theme for rescue system
      theme = mkIf config.custom.rescueSystem.grub.enableAdvancedMenu (pkgs.stdenv.mkDerivation {
        name = "nixos-rescue-grub-theme";
        src = pkgs.writeTextDir "theme.txt" ''
          desktop-image: ""
          title-color: "#FFFFFF"
          title-font: "DejaVu Sans Bold 16"
          terminal-font: "DejaVu Sans Mono 12"
          
          + boot_menu {
            left = 20%
            top = 30%
            width = 60%
            height = 40%
            item_color = "#CCCCCC"
            selected_item_color = "#FFFFFF"
            item_height = 25
            item_padding = 5
            item_spacing = 2
          }
          
          + label {
            id = "__timeout__"
            text = "Rescue System - Auto boot in %d seconds"
            color = "#FFFF00"
            font = "DejaVu Sans 12"
            top = 80%
            left = 50%
            align = "center"
          }
        '';
        installPhase = "cp -r . $out";
      });
      
      # Custom menu entries for rescue system
      extraEntries = ''
        menuentry "NixOS Rescue Mode (Emergency Shell)" {
          linux $kernel init=/bin/sh boot.shell_on_fail systemd.unit=emergency.target
          initrd $initrd
        }
        
        menuentry "NixOS Recovery Mode (Single User)" {
          linux $kernel systemd.unit=rescue.target
          initrd $initrd
        }
        
        menuentry "NixOS Memory Test" {
          linux16 ${pkgs.memtest86plus}/memtest.bin
        }
        
        menuentry "NixOS System Info" {
          linux $kernel systemd.unit=multi-user.target rescue-info=true
          initrd $initrd
        }
        
        submenu "Generation Recovery Options" {
          menuentry "List All Generations" {
            linux $kernel systemd.unit=multi-user.target rescue-list-generations=true
            initrd $initrd
          }
          
          menuentry "Rollback to Previous Generation" {
            linux $kernel systemd.unit=multi-user.target rescue-rollback=true
            initrd $initrd
          }
          
          menuentry "Generation Cleanup" {
            linux $kernel systemd.unit=multi-user.target rescue-cleanup=true
            initrd $initrd
          }
        }
        
        submenu "Hardware Diagnostics" {
          menuentry "Disk Health Check" {
            linux $kernel systemd.unit=multi-user.target rescue-disk-check=true
            initrd $initrd
          }
          
          menuentry "Memory Diagnostic" {
            linux $kernel systemd.unit=multi-user.target rescue-memory-check=true
            initrd $initrd
          }
          
          menuentry "Network Diagnostic" {
            linux $kernel systemd.unit=multi-user.target rescue-network-check=true
            initrd $initrd
          }
        }
      '';
    };

    # Generation management script
    environment.etc."nixos/scripts/generation-manager.sh" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        
        # NixOS Generation Manager and Rescue Tool
        # Provides advanced generation management with sorting and filtering
        
        set -euo pipefail
        
        SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
        LOG_FILE="/var/log/nixos-rescue.log"
        
        # Logging function
        log() {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
        }
        
        # Get generation information with enhanced metadata
        get_generation_info() {
            local gen_path="$1"
            local gen_num=$(basename "$gen_path" | cut -d- -f2)
            local gen_date=""
            local gen_kernel=""
            local gen_nixos_version=""
            local gen_status="unknown"
            
            if [[ -f "$gen_path/nixos-version" ]]; then
                gen_nixos_version=$(cat "$gen_path/nixos-version")
            fi
            
            if [[ -f "$gen_path/kernel" ]]; then
                gen_kernel=$(readlink "$gen_path/kernel" | sed 's/.*linux-//' | sed 's/-.*//')
            fi
            
            # Get creation date from filesystem
            if [[ -e "$gen_path" ]]; then
                gen_date=$(stat -c %Y "$gen_path")
            fi
            
            # Check if generation is bootable
            if [[ -f "$gen_path/init" && -f "$gen_path/kernel" ]]; then
                gen_status="working"
            else
                gen_status="broken"
            fi
            
            # Check if it's the current generation
            if [[ "$gen_path" -ef "/nix/var/nix/profiles/system" ]]; then
                gen_status="current"
            fi
            
            echo "$gen_num|$gen_date|$gen_kernel|$gen_nixos_version|$gen_status|$gen_path"
        }
        
        # List all generations with detailed information
        list_generations() {
            local sort_by="''${1:-date}"
            local group_by="''${2:-week}"
            local filter_status="''${3:-all}"
            
            log "Listing generations (sort: $sort_by, group: $group_by, filter: $filter_status)"
            
            echo "=== NixOS Generation Analysis ==="
            echo "Current time: $(date)"
            echo "System: $(uname -a)"
            echo ""
            
            local generations=()
            local current_gen=""
            
            # Find current generation
            if [[ -L "/nix/var/nix/profiles/system" ]]; then
                current_gen=$(readlink "/nix/var/nix/profiles/system")
            fi
            
            # Collect all generation information
            for gen_path in /nix/var/nix/profiles/system-*-link; do
                if [[ -e "$gen_path" ]]; then
                    local gen_info=$(get_generation_info "$gen_path")
                    generations+=("$gen_info")
                fi
            done
            
            # Sort generations
            case "$sort_by" in
                "date")
                    IFS=$'\n' generations=($(printf '%s\n' "''${generations[@]}" | sort -t'|' -k2 -n -r))
                    ;;
                "status")
                    IFS=$'\n' generations=($(printf '%s\n' "''${generations[@]}" | sort -t'|' -k5))
                    ;;
                "name")
                    IFS=$'\n' generations=($(printf '%s\n' "''${generations[@]}" | sort -t'|' -k1 -n -r))
                    ;;
            esac
            
            # Group and display generations
            local current_group=""
            local group_count=0
            
            for gen_info in "''${generations[@]}"; do
                IFS='|' read -r gen_num gen_date gen_kernel gen_nixos_version gen_status gen_path <<< "$gen_info"
                
                # Filter by status if requested
                if [[ "$filter_status" != "all" && "$gen_status" != "$filter_status" ]]; then
                    continue
                fi
                
                # Determine group
                local group_name=""
                local date_readable=$(date -d "@$gen_date" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
                local date_group=""
                
                case "$group_by" in
                    "day")
                        date_group=$(date -d "@$gen_date" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
                        group_name="Day: $date_group"
                        ;;
                    "week")
                        date_group=$(date -d "@$gen_date" '+%Y-W%U' 2>/dev/null || echo "unknown")
                        group_name="Week: $date_group"
                        ;;
                    "month")
                        date_group=$(date -d "@$gen_date" '+%Y-%m' 2>/dev/null || echo "unknown")
                        group_name="Month: $date_group"
                        ;;
                    "status")
                        group_name="Status: $gen_status"
                        date_group="$gen_status"
                        ;;
                esac
                
                # Print group header if changed
                if [[ "$date_group" != "$current_group" ]]; then
                    if [[ $group_count -gt 0 ]]; then
                        echo ""
                    fi
                    echo "=== $group_name ==="
                    current_group="$date_group"
                    ((group_count++))
                fi
                
                # Format status with colors
                local status_display=""
                case "$gen_status" in
                    "current")
                        status_display="[CURRENT]"
                        ;;
                    "working")
                        status_display="[WORKING]"
                        ;;
                    "broken")
                        status_display="[BROKEN] "
                        ;;
                    *)
                        status_display="[UNKNOWN]"
                        ;;
                esac
                
                # Display generation info
                printf "  Gen %-3s %s %s\n" "$gen_num" "$status_display" "$date_readable"
                printf "          Kernel: %-20s NixOS: %s\n" "$gen_kernel" "$gen_nixos_version"
                printf "          Path: %s\n" "$gen_path"
                
                # Add current generation marker
                if [[ "$gen_path" -ef "$current_gen" ]]; then
                    printf "          >>> CURRENTLY ACTIVE <<<\n"
                fi
                
                echo ""
            done
            
            # Summary
            local total_gens=''${#generations[@]}
            local working_gens=$(printf '%s\n' "''${generations[@]}" | grep -c "|working|" || true)
            local broken_gens=$(printf '%s\n' "''${generations[@]}" | grep -c "|broken|" || true)
            
            echo "=== Summary ==="
            echo "Total generations: $total_gens"
            echo "Working: $working_gens, Broken: $broken_gens"
            echo "Groups found: $group_count"
        }
        
        # Rollback to a specific generation
        rollback_generation() {
            local target_gen="''${1:-previous}"
            
            log "Attempting rollback to: $target_gen"
            
            if [[ "$target_gen" == "previous" ]]; then
                echo "Rolling back to previous generation..."
                nixos-rebuild switch --rollback
            elif [[ "$target_gen" =~ ^[0-9]+$ ]]; then
                echo "Rolling back to generation $target_gen..."
                local gen_path="/nix/var/nix/profiles/system-$target_gen-link"
                if [[ -e "$gen_path" ]]; then
                    nix-env -p /nix/var/nix/profiles/system --switch-generation "$target_gen"
                    "$gen_path/bin/switch-to-configuration" switch
                else
                    echo "ERROR: Generation $target_gen not found!"
                    return 1
                fi
            else
                echo "ERROR: Invalid generation specifier: $target_gen"
                return 1
            fi
            
            log "Rollback completed successfully"
        }
        
        # Cleanup old generations
        cleanup_generations() {
            local keep_count="''${1:-10}"
            local dry_run="''${2:-false}"
            
            log "Generation cleanup: keeping $keep_count generations (dry_run: $dry_run)"
            
            echo "=== Generation Cleanup ==="
            echo "Keeping $keep_count most recent generations..."
            
            if [[ "$dry_run" == "true" ]]; then
                echo "DRY RUN - No changes will be made"
                nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n +$((keep_count + 1))
            else
                nix-collect-garbage -d
                nix-env -p /nix/var/nix/profiles/system --delete-generations +$keep_count
                echo "Cleanup completed"
            fi
        }
        
        # System diagnostics
        system_diagnostics() {
            log "Running system diagnostics"
            
            echo "=== System Diagnostics ==="
            echo "Timestamp: $(date)"
            echo ""
            
            echo "--- System Information ---"
            uname -a
            echo "NixOS Version: $(nixos-version 2>/dev/null || echo 'Unknown')"
            echo "Uptime: $(uptime)"
            echo ""
            
            echo "--- Memory Usage ---"
            free -h
            echo ""
            
            echo "--- Disk Usage ---"
            df -h
            echo ""
            
            echo "--- Nix Store ---"
            du -sh /nix/store 2>/dev/null || echo "Cannot access /nix/store"
            echo ""
            
            echo "--- Failed Services ---"
            systemctl --failed --no-legend || echo "No failed services"
            echo ""
            
            echo "--- Last Boot Messages ---"
            journalctl --boot --no-pager --lines=20 --priority=err 2>/dev/null || echo "Cannot access journal"
            echo ""
            
            echo "--- Generation Status ---"
            list_generations date week working | head -20
        }
        
        # Main function
        main() {
            local action="''${1:-help}"
            shift 2>/dev/null || true
            
            case "$action" in
                "list"|"list-generations")
                    list_generations "$@"
                    ;;
                "rollback")
                    rollback_generation "$@"
                    ;;
                "cleanup")
                    cleanup_generations "$@"
                    ;;
                "diagnostics"|"diag")
                    system_diagnostics
                    ;;
                "help"|*)
                    echo "NixOS Generation Manager and Rescue Tool"
                    echo ""
                    echo "Usage: $0 <command> [options]"
                    echo ""
                    echo "Commands:"
                    echo "  list [sort] [group] [filter]  - List generations"
                    echo "    sort: date, status, name (default: date)"
                    echo "    group: day, week, month, status (default: week)"
                    echo "    filter: all, working, broken, current (default: all)"
                    echo ""
                    echo "  rollback [target]             - Rollback to generation"
                    echo "    target: previous, or generation number (default: previous)"
                    echo ""
                    echo "  cleanup [keep] [dry-run]      - Clean old generations"
                    echo "    keep: number to keep (default: 10)"
                    echo "    dry-run: true/false (default: false)"
                    echo ""
                    echo "  diagnostics                   - Run system diagnostics"
                    echo "  help                          - Show this help"
                    echo ""
                    echo "Examples:"
                    echo "  $0 list date week working     # Working generations by week"
                    echo "  $0 rollback 42                # Rollback to generation 42"
                    echo "  $0 cleanup 5 true             # Dry run cleanup keeping 5"
                    ;;
            esac
        }
        
        # Run main function with all arguments
        main "$@"
      '';
      mode = "0755";
    };

    # Comprehensive rescue tools installation
    environment.systemPackages = mkMerge [
      # Always include rescue menu script
      [ (pkgs.writeScriptBin "nixos-rescue-menu" ''
          #!${pkgs.bash}/bin/bash
          
          # NixOS Comprehensive Rescue System
          # Advanced recovery and diagnostic tools
          
          set -e
          
          # Color codes for better visibility
          RED='\033[0;31m'
          GREEN='\033[0;32m'
          YELLOW='\033[1;33m'
          BLUE='\033[0;34m'
          PURPLE='\033[0;35m'
          CYAN='\033[0;36m'
          NC='\033[0m' # No Color
          
          # Function to print colored headers
          print_header() {
              echo -e "\n$${CYAN}============================================$${NC}"
              echo -e "$${CYAN} $1 $${NC}"
              echo -e "$${CYAN}============================================$${NC}\n"
          }
          
          # Function to print status messages
          print_status() {
              echo -e "$${GREEN}[STATUS]$${NC} $1"
          }
          
          print_warning() {
              echo -e "$${YELLOW}[WARNING]$${NC} $1"
          }
          
          print_error() {
              echo -e "$${RED}[ERROR]$${NC} $1"
          }
          
          # Main rescue menu
          show_rescue_menu() {
              clear
              print_header "NixOS Comprehensive Rescue System"
              
              echo -e "$${PURPLE}System Recovery and Diagnostic Tools$${NC}"
              echo ""
              echo "1)  System Information & Hardware Diagnostics"
              echo "2)  Network Diagnostics & Recovery"
              echo "3)  Disk & Filesystem Tools"
              echo "4)  Boot & Generation Management"
              echo "5)  Service & Process Management"
              echo "6)  File Recovery & Backup Tools" 
              echo "7)  Emergency System Repair"
              echo "8)  Performance Analysis & Monitoring"
              echo "9)  Security & Access Recovery"
              echo "10) Configuration Backup & Restore"
              echo "11) Advanced Shell & Development Tools"
              echo "12) System Stress Testing"
              echo ""
              echo "r)  Reboot System"
              echo "s)  Shutdown System"
              echo "q)  Quit Rescue Menu"
              echo ""
              echo -n "Select option: "
          }
          
          # System Information & Hardware Diagnostics
          system_diagnostics() {
              print_header "System Information & Hardware Diagnostics"
              
              echo "1) Complete System Information"
              echo "2) Hardware Information (lshw)"
              echo "3) PCI Device Information"
              echo "4) USB Device Information" 
              echo "5) Memory Information"
              echo "6) CPU Information"
              echo "7) Disk Information"
              echo "8) SMART Disk Health"
              echo "9) DMI/BIOS Information"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) uname -a; hostnamectl; uptime; free -h; df -h; lsblk; pause ;;
                  2) lshw -short; pause ;;
                  3) lspci -v; pause ;;
                  4) lsusb -v; pause ;;
                  5) free -h; cat /proc/meminfo; pause ;;
                  6) lscpu; cat /proc/cpuinfo; pause ;;
                  7) lsblk -a; fdisk -l; pause ;;
                  8) smartctl --scan; read -p "Enter device (e.g., /dev/sda): " dev; smartctl -a "$dev"; pause ;;
                  9) dmidecode | less; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Network Diagnostics & Recovery
          network_diagnostics() {
              print_header "Network Diagnostics & Recovery"
              
              echo "1) Network Interface Status"
              echo "2) IP Configuration"
              echo "3) DNS Resolution Test"
              echo "4) Network Connectivity Test"
              echo "5) Network Performance Test" 
              echo "6) Network Security Scan"
              echo "7) Packet Capture"
              echo "8) Wireless Network Tools"
              echo "9) VPN Tools"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) ip link show; ip addr show; pause ;;
                  2) ip route show; systemd-resolve --status; pause ;;
                  3) read -p "Enter domain to test: " domain; dig "$domain"; nslookup "$domain"; pause ;;
                  4) ping -c 4 8.8.8.8; traceroute 8.8.8.8; pause ;;
                  5) read -p "Enter server for iperf3 test: " server; iperf3 -c "$server"; pause ;;
                  6) read -p "Enter target for nmap scan: " target; nmap -sS "$target"; pause ;;
                  7) read -p "Enter interface (e.g., eth0): " iface; tcpdump -i "$iface"; pause ;;
                  8) iwconfig; iwlist scan; pause ;;
                  9) wg show; systemctl status wg-quick@*; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Disk & Filesystem Tools
          disk_filesystem_tools() {
              print_header "Disk & Filesystem Tools"
              
              echo "1) Disk Usage Analysis"
              echo "2) Filesystem Check & Repair"
              echo "3) Partition Management"
              echo "4) Mount/Unmount Operations"
              echo "5) File Recovery Tools"
              echo "6) Disk Cloning & Imaging"
              echo "7) RAID Status & Management" 
              echo "8) LVM Management"
              echo "9) Encrypted Volume Management"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) df -h; du -sh /*; ncdu /; pause ;;
                  2) read -p "Enter device to check (e.g., /dev/sda1): " dev; fsck "$dev"; pause ;;
                  3) fdisk -l; echo "Use 'fdisk', 'parted', or 'gparted' for partition management"; pause ;;
                  4) mount; echo "Use 'mount' and 'umount' commands"; pause ;;
                  5) echo "Available: testdisk, photorec, ddrescue"; testdisk; pause ;;
                  6) echo "Use 'dd', 'ddrescue', or 'clonezilla' for disk operations"; pause ;;
                  7) cat /proc/mdstat; mdadm --detail --scan; pause ;;
                  8) pvs; vgs; lvs; pause ;;
                  9) lsblk; cryptsetup status; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Boot & Generation Management  
          boot_generation_management() {
              print_header "Boot & Generation Management"
              
              echo "1) List Boot Generations"
              echo "2) Switch to Previous Generation"
              echo "3) Delete Old Generations"
              echo "4) Rebuild System Configuration"
              echo "5) GRUB Configuration"
              echo "6) Boot Loader Repair"
              echo "7) Kernel Module Management"
              echo "8) Bootloader Reinstall"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) /etc/nixos/scripts/generation-manager.sh list; pause ;;
                  2) read -p "Enter generation number: " gen; /etc/nixos/scripts/generation-manager.sh rollback "$gen"; pause ;;
                  3) nix-collect-garbage -d; pause ;;
                  4) nixos-rebuild switch; pause ;;
                  5) cat /boot/grub/grub.cfg | less; pause ;;
                  6) grub-install /dev/sda; update-grub; pause ;;
                  7) lsmod; read -p "Module to load/unload: " mod; modprobe "$mod"; pause ;;
                  8) read -p "Enter boot device (e.g., /dev/sda): " dev; grub-install "$dev"; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Service & Process Management
          service_process_management() {
              print_header "Service & Process Management"
              
              echo "1) SystemD Service Status"
              echo "2) Process Monitoring"
              echo "3) Kill Runaway Processes"
              echo "4) Service Recovery"
              echo "5) Journal Analysis"
              echo "6) Performance Monitoring"
              echo "7) System Resource Usage"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) systemctl --failed; systemctl list-units; pause ;;
                  2) htop; pause ;;
                  3) ps aux | grep -v grep; read -p "Enter PID to kill: " pid; kill -9 "$pid"; pause ;;
                  4) read -p "Enter service name: " svc; systemctl restart "$svc"; systemctl status "$svc"; pause ;;
                  5) journalctl -xe; pause ;;
                  6) top -d 1; pause ;;
                  7) iostat; vmstat; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Emergency System Repair
          emergency_system_repair() {
              print_header "Emergency System Repair"
              
              print_warning "CAUTION: These operations can affect system stability!"
              echo ""
              echo "1) Repair File Permissions"
              echo "2) Fix Broken Packages"
              echo "3) Rebuild Boot Configuration"
              echo "4) Reset Network Configuration"
              echo "5) Emergency User Management"
              echo "6) Service Recovery Mode"
              echo "7) Emergency Chroot Environment"
              echo "b) Back to main menu"
              echo ""
              echo -n "Select option: "
              
              read -r choice
              case $choice in
                  1) chmod -R 755 /etc; chmod 600 /etc/shadow; chmod 644 /etc/passwd; pause ;;
                  2) nix-channel --update; nixos-rebuild switch --repair; pause ;;
                  3) nixos-rebuild boot; grub-install /dev/sda; pause ;;
                  4) systemctl restart NetworkManager; dhclient; pause ;;
                  5) passwd root; passwd mahmoud; pause ;;
                  6) systemctl rescue; pause ;;
                  7) echo "Preparing chroot environment..."; mount --bind /proc /mnt/proc; chroot /mnt; pause ;;
                  b) return ;;
                  *) print_error "Invalid option"; pause ;;
              esac
          }
          
          # Pause function for user interaction
          pause() {
              echo ""
              read -p "Press Enter to continue..." 
          }
          
          # Main program loop
          while true; do
              show_rescue_menu
              read -r choice
              
              case $choice in
                  1) system_diagnostics ;;
                  2) network_diagnostics ;;
                  3) disk_filesystem_tools ;;
                  4) boot_generation_management ;;
                  5) service_process_management ;;
                  6) echo "File Recovery Tools: testdisk, photorec, ddrescue"; pause ;;
                  7) emergency_system_repair ;;
                  8) echo "Performance Tools: htop, iotop, perf, stress"; pause ;;
                  9) echo "Security Tools: nmap, tcpdump, wireshark"; pause ;;
                  10) echo "Backup Tools: rsync, tar, borgbackup"; pause ;;
                  11) echo "Development Tools: gdb, strace, valgrind"; bash; ;;
                  12) stress --cpu 4 --io 4 --vm 2 --vm-bytes 256M --timeout 60; pause ;;
                  r) systemctl reboot ;;
                  s) systemctl poweroff ;;
                  q) exit 0 ;;
                  *) print_error "Invalid option. Please try again."; pause ;;
              esac
          done
        '') ]
      
      # Basic rescue tools
      (mkIf cfg.rescueTools.enable [
        # Essential CLI tools
        pkgs.coreutils pkgs.findutils pkgs.gnugrep
        pkgs.gnused pkgs.gawk pkgs.less pkgs.tree
        pkgs.file pkgs.which pkgs.vim pkgs.nano
        pkgs.tmux pkgs.screen pkgs.bash pkgs.zsh
      ])
      
      # Network diagnostic tools
      (mkIf (cfg.rescueTools.enable && cfg.rescueTools.networkTools) networkTools)
      
      # Disk and filesystem tools
      (mkIf (cfg.rescueTools.enable && cfg.rescueTools.diskTools) diskTools)
      
      # System diagnostic tools  
      (mkIf (cfg.rescueTools.enable && cfg.rescueTools.systemTools) systemTools)
      
      # CLI recovery tools
      (mkIf cfg.rescueTools.enable recoveryCLITools)
    ];

    # Rescue services
    systemd.services.nixos-rescue-boot-check = {
      description = "NixOS Rescue Boot Parameter Handler";
      wantedBy = [ "multi-user.target" ];
      after = [ "basic.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c ''
          # Check for rescue boot parameters
          CMDLINE=$(cat /proc/cmdline)
          
          if [[ \"$$CMDLINE\" == *\"rescue-info=true\"* ]]; then
            /etc/nixos/scripts/generation-manager.sh diagnostics | tee /dev/console
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-list-generations=true\"* ]]; then
            /etc/nixos/scripts/generation-manager.sh list | tee /dev/console
            echo \"Press Enter to continue...\" | tee /dev/console
            read
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-rollback=true\"* ]]; then
            echo \"=== RESCUE ROLLBACK MODE ===\" | tee /dev/console
            /etc/nixos/scripts/generation-manager.sh list date week working | head -10 | tee /dev/console
            echo \"Enter generation number to rollback to (or 'cancel'):\" | tee /dev/console
            read -r gen
            if [[ \"$$gen\" != \"cancel\" && \"$$gen\" =~ ^[0-9]+$$ ]]; then
              /etc/nixos/scripts/generation-manager.sh rollback \"$$gen\"
            fi
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-cleanup=true\"* ]]; then
            echo \"=== RESCUE CLEANUP MODE ===\" | tee /dev/console
            /etc/nixos/scripts/generation-manager.sh cleanup 10 true | tee /dev/console
            echo \"Proceed with cleanup? (yes/no):\" | tee /dev/console
            read -r confirm
            if [[ \"$$confirm\" == \"yes\" ]]; then
              /etc/nixos/scripts/generation-manager.sh cleanup 10 false
            fi
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-disk-check=true\"* ]]; then
            echo \"=== DISK HEALTH CHECK ===\" | tee /dev/console
            for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
              if [[ -e \"$$disk\" ]]; then
                echo \"Checking $$disk...\" | tee /dev/console
                smartctl -a \"$$disk\" 2>/dev/null | tee /dev/console || true
              fi
            done
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-memory-check=true\"* ]]; then
            echo \"=== MEMORY CHECK ===\" | tee /dev/console
            free -h | tee /dev/console
            echo \"Running memory test (5 seconds)...\" | tee /dev/console
            stress-ng --vm 1 --vm-bytes 75%% --timeout 5s | tee /dev/console || true
          fi
          
          if [[ \"$$CMDLINE\" == *\"rescue-network-check=true\"* ]]; then
            echo \"=== NETWORK DIAGNOSTIC ===\" | tee /dev/console
            ip addr show | tee /dev/console
            echo \"Testing connectivity...\" | tee /dev/console
            ping -c 3 8.8.8.8 | tee /dev/console || true
          fi
        ''";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
    };

    # Note: Emergency shell is provided by systemd's emergency.target by default

    # Aliases for easy access
    environment.shellAliases = {
      rescue-list = "/etc/nixos/scripts/generation-manager.sh list";
      rescue-rollback = "/etc/nixos/scripts/generation-manager.sh rollback";
      rescue-cleanup = "/etc/nixos/scripts/generation-manager.sh cleanup";
      rescue-diag = "/etc/nixos/scripts/generation-manager.sh diagnostics";
      rescue-help = "/etc/nixos/scripts/generation-manager.sh help";
    };

    # Emergency access features provided by systemd targets

    
    # Emergency access configuration
    security.sudo.wheelNeedsPassword = mkIf cfg.emergencyAccess.enableRootShell (mkForce false);
    
    # Emergency SSH access (if enabled)
    services.openssh = mkIf cfg.emergencyAccess.enableSSH {
      enable = true;
      settings = {
        PermitRootLogin = "yes";  # Only for emergency access
        PasswordAuthentication = cfg.emergencyAccess.allowPasswordAuth;
      };
    };
    
    # Generation management
    nix.gc = mkIf cfg.generations.autoCleanup {
      automatic = mkDefault true;
      dates = mkDefault "weekly";
      options = mkDefault "--delete-older-than 30d --max-freed 68719476736";  # 64 GB
    };
    
    # Keep more generations for recovery
    boot.loader.grub.configurationLimit = mkDefault cfg.generations.maxCount;
    
    # Environment variables for rescue system
    environment.variables = {
      NIXOS_RESCUE_SYSTEM = "enabled";
      RESCUE_TOOLS_AVAILABLE = "true";
    };
    
    # Create rescue system directories
    system.activationScripts.rescue-system-setup = ''
      # Create rescue system directories
      mkdir -p /var/lib/nixos-rescue
      mkdir -p /var/log/nixos-rescue
      
      # Set permissions
      chmod 755 /var/lib/nixos-rescue
      chmod 755 /var/log/nixos-rescue
      
      # Create rescue system status file
      echo "NixOS Rescue System Enabled" > /var/lib/nixos-rescue/status
      echo "Rescue Menu - nixos-rescue-menu" >> /var/lib/nixos-rescue/status
      echo "Rescue Tools Available" >> /var/lib/nixos-rescue/status
      echo "Run nixos-rescue-menu to access rescue tools" >> /var/lib/nixos-rescue/status
    '';
    
    # Console configuration for rescue access
    console = {
      earlySetup = true;
      keyMap = "us";
    };
    
    # Note: Kernel parameters for rescue functionality are set in configuration.nix
    # to avoid conflicts with mkForce
    
    # Additional rescue kernel modules
    boot.kernelModules = [
      "loop"      # For mounting ISO images
      "overlay"   # For overlay filesystems
      "squashfs"  # For compressed filesystems
    ];
    
    # Initrd tools for early rescue
    boot.initrd.availableKernelModules = [
      "loop" "overlay" "squashfs"
    ];
    
    # Networking configuration for rescue mode
    networking = mkMerge [
      (mkIf cfg.emergencyAccess.enableNetworkAccess {
        networkmanager.enable = mkDefault true;
        wireless.enable = mkDefault false;  # Prefer NetworkManager
      })
      (mkIf cfg.emergencyAccess.enableSSH {
        firewall.allowedTCPPorts = [ 22 ];  # SSH access in rescue mode
      })
    ];
    
    # Create log directory
    systemd.tmpfiles.rules = [
      "d /var/log 0755 root root -"
      "f /var/log/nixos-rescue.log 0644 root root -"
    ];
  };
}
