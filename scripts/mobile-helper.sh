#!/usr/bin/env bash
# Mobile Device Helper Script
# Helps manage mobile device connections and KDE Connect

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}   Mobile Device Manager${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

check_kdeconnect() {
    echo -e "${YELLOW}Checking KDE Connect status...${NC}"
    if systemctl --user is-active --quiet kdeconnect.service; then
        echo -e "${GREEN}✓ KDE Connect is running${NC}"
    else
        echo -e "${RED}✗ KDE Connect is not running${NC}"
        echo -e "${YELLOW}  Starting KDE Connect...${NC}"
        systemctl --user start kdeconnect.service kdeconnect-indicator.service
        sleep 2
        if systemctl --user is-active --quiet kdeconnect.service; then
            echo -e "${GREEN}✓ KDE Connect started successfully${NC}"
        else
            echo -e "${RED}✗ Failed to start KDE Connect${NC}"
        fi
    fi
    echo
}

list_usb_devices() {
    echo -e "${YELLOW}Connected USB devices:${NC}"
    lsusb
    echo
}

check_adb_devices() {
    echo -e "${YELLOW}Checking ADB devices...${NC}"
    adb devices -l
    echo
}

check_mtp_devices() {
    echo -e "${YELLOW}Checking MTP devices (may take a moment)...${NC}"
    if command -v jmtpfs &> /dev/null; then
        jmtpfs -l || echo "No MTP devices found"
    else
        echo "MTP tools not available"
    fi
    echo
}

enable_kdeconnect_autostart() {
    echo -e "${YELLOW}Enabling KDE Connect auto-start...${NC}"
    systemctl --user enable kdeconnect.service kdeconnect-indicator.service
    echo -e "${GREEN}✓ KDE Connect will start automatically on login${NC}"
    echo
}

show_firewall_ports() {
    echo -e "${YELLOW}KDE Connect requires the following ports:${NC}"
    echo "  TCP/UDP: 1714-1724"
    echo
    echo -e "${YELLOW}Current firewall status:${NC}"
    sudo firewall-cmd --list-ports 2>/dev/null || sudo nft list ruleset | grep -E "1714|1724" || echo "Firewall not using firewalld/nftables"
    echo
}

pair_android_adb() {
    echo -e "${YELLOW}Pairing Android device via ADB...${NC}"
    echo "1. Connect your device via USB"
    echo "2. Enable USB debugging on your device"
    echo "3. Accept the debugging prompt on your device"
    echo
    read -p "Press Enter when ready..."
    adb devices
    echo
    if adb devices | grep -q "device$"; then
        echo -e "${GREEN}✓ Device connected successfully${NC}"
        echo
        echo "To use wireless ADB:"
        echo "  1. Run: adb tcpip 5555"
        echo "  2. Find device IP: adb shell ip addr show wlan0"
        echo "  3. Disconnect USB"
        echo "  4. Connect: adb connect DEVICE_IP:5555"
    else
        echo -e "${RED}✗ No devices found. Check USB debugging is enabled${NC}"
    fi
    echo
}

show_kdeconnect_devices() {
    echo -e "${YELLOW}KDE Connect paired devices:${NC}"
    if command -v kdeconnect-cli &> /dev/null; then
        kdeconnect-cli -l
    else
        echo "KDE Connect CLI not found"
    fi
    echo
}

show_menu() {
    print_header
    echo "1. Check KDE Connect status"
    echo "2. List USB devices"
    echo "3. Check ADB devices"
    echo "4. Check MTP devices"
    echo "5. Enable KDE Connect auto-start"
    echo "6. Show firewall ports"
    echo "7. Pair Android device (ADB)"
    echo "8. Show KDE Connect devices"
    echo "9. Run all checks"
    echo "0. Exit"
    echo
    read -p "Select an option: " choice
    
    case $choice in
        1) check_kdeconnect ;;
        2) list_usb_devices ;;
        3) check_adb_devices ;;
        4) check_mtp_devices ;;
        5) enable_kdeconnect_autostart ;;
        6) show_firewall_ports ;;
        7) pair_android_adb ;;
        8) show_kdeconnect_devices ;;
        9)
            check_kdeconnect
            list_usb_devices
            check_adb_devices
            check_mtp_devices
            show_kdeconnect_devices
            ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    read -p "Press Enter to continue..."
    show_menu
}

# If run with argument, execute directly
if [ $# -gt 0 ]; then
    case $1 in
        check) check_kdeconnect; list_usb_devices; check_adb_devices ;;
        start) systemctl --user start kdeconnect.service kdeconnect-indicator.service ;;
        enable) enable_kdeconnect_autostart ;;
        adb) check_adb_devices ;;
        *) echo "Usage: $0 {check|start|enable|adb}" ;;
    esac
else
    show_menu
fi
