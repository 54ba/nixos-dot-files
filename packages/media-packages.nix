{ pkgs }:

with pkgs; [
  # Video editing and processing
  ffmpeg-full
  kdePackages.kdenlive  # Qt 6 version
  openshot-qt
  # davinci-resolve  # If available
  handbrake
  
  # Image editing and graphics
  imagemagick
  gimp
  inkscape
  krita
  darktable
  rawtherapee
  
  # 3D modeling and animation
  blender
  
  # Vector graphics and design
  # figma-linux  # Uncomment if available in your nixpkgs
  
  # Screen recording and streaming
  obs-studio
  simplescreenrecorder
  peek  # GIF recorder
  
  # Audio editing and production
  audacity
  # reaper  # If available
  ardour
  lmms
  
  # Media players
  vlc
  mpv
  celluloid   # GTK frontend for mpv
  
  # Media codecs and libraries
  gst_all_1.gstreamer
  gst_all_1.gst-plugins-base
  gst_all_1.gst-plugins-good
  gst_all_1.gst-plugins-bad
  gst_all_1.gst-plugins-ugly
  gst_all_1.gst-libav
  
  # Photo management
  digikam
  shotwell
  
  # Font management
  font-manager
  
  # Color management
  displaycal
]

