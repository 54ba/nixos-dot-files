{ lib, stdenv, fetchurl, appimageTools, makeWrapper, electron, fuse, libffi, openssl, curl, ca-certificates }:

let
  pname = "cursor";
  version = "1.7";
  
  src = fetchurl {
    url = "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/1.7";
    sha256 = "1v8mac47vp5l475vhh5m9smakcxqz3ydxx9jkkcdqhw4yklnmlzq";
  };

in appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Install desktop file
    mkdir -p $out/share/applications
    cat > $out/share/applications/cursor.desktop << EOF
[Desktop Entry]
Name=Cursor
Comment=The AI Code Editor. Built to make you extraordinarily productive.
Exec=$out/bin/cursor %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Categories=Development;IDE;
MimeType=text/plain;inode/directory;
EOF

    # Create a wrapper script that sets proper environment
    mkdir -p $out/bin
    cat > $out/bin/cursor << 'EOF'
#!/usr/bin/env bash

# Ensure proper environment for GUI applications
export XDG_DATA_DIRS="$XDG_DATA_DIRS:$out/share"

# Set up library paths
export LD_LIBRARY_PATH="${lib.makeLibraryPath [ 
  fuse 
  libffi 
  openssl 
  curl 
]}"

# Certificate bundle for SSL connections
export SSL_CERT_FILE="${ca-certificates}/etc/ssl/certs/ca-bundle.crt"
export CURL_CA_BUNDLE="${ca-certificates}/etc/ssl/certs/ca-bundle.crt"

# Execute the AppImage with proper permissions and environment
exec ${appimageTools.extract { inherit pname version src; }}/AppRun "$@"
EOF
    
    chmod +x $out/bin/cursor

    # Extract and install icon if available
    ${appimageTools.extract { inherit pname version src; }}/AppRun --appimage-extract *.png 2>/dev/null || true
    if [ -f squashfs-root/cursor.png ]; then
      mkdir -p $out/share/pixmaps
      cp squashfs-root/cursor.png $out/share/pixmaps/cursor.png
    elif [ -f squashfs-root/*.png ]; then
      mkdir -p $out/share/pixmaps  
      cp squashfs-root/*.png $out/share/pixmaps/cursor.png
    fi
    rm -rf squashfs-root 2>/dev/null || true
  '';

  meta = with lib; {
    description = "The AI Code Editor - Latest version from cursor.com";
    longDescription = ''
      Cursor is an AI-first code editor designed for pair-programming with AI.
      This package provides the latest version directly from cursor.com with
      proper NixOS integration and desktop entry.
    '';
    homepage = "https://cursor.com/";
    license = licenses.unfree;
    maintainers = [];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}