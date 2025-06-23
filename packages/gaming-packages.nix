{ pkgs }:

with pkgs; [
  # Gaming platforms
  steam
  lutris
  heroic
  bottles         # Wine prefix manager
  
  # Game performance and utilities
  gamemode
  mangohud
  goverlay        # GUI for MangoHud
  
  # Wine and compatibility layers
  wine
  winetricks
  dxvk
  
  # Game development
  godot_4
  # unity3d  # Not available in nixpkgs
  
  # Emulators
  retroarch
  dolphin-emu
  pcsx2
  rpcs3
  # yuzu-mainline  # May not be available
  
  # Gaming utilities
  antimicrox      # Gamepad to keyboard/mouse mapper
  jstest-gtk      # Joystick tester
  
  # Game engines
  love            # 2D game engine
  
  # Steam utilities
  steam-run
  steamcmd
  
  # Discord Rich Presence
  discord-rpc
  
  # Game recording
  # obs-studio is in media packages
  
  # Minecraft
  prismlauncher   # Minecraft launcher
  
  # ROM management
  # romm            # ROM manager - check availability
]

