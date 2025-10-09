{ lib, fetchurl, appimageTools }:

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