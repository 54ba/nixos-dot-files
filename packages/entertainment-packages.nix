{ pkgs }:

with pkgs; [
  # Music streaming and players
  spotify
  youtube-music
  rhythmbox
  clementine
  
  # Video streaming and media centers
  stremio
  plex-desktop  # Renamed from plex-media-player
  jellyfin-media-player
  kodi
  
  # Torrenting and file sharing
  qbittorrent
  transmission_3  # Renamed from transmission
  deluge
  
  # YouTube and video downloading
  yt-dlp
  # youtube-dl  # Marked as insecure, use yt-dlp instead
  
  # Podcast players
  gpodder
  vocal
  
  # E-book readers
  calibre
  foliate
  
  # Comic book readers
  comix
  mcomix3
  
  # Radio and audio streaming
  radio-tray
  shortwave
  
  # Media servers
  plex
  jellyfin
  
  # Social media clients
  whatsapp-for-linux
  
  # Reading and news
  newsflash
  liferea
  
  # Weather
  gnome-weather
  
  # Games (casual)
  solitaire
  gnome-games
]

