{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, wrapGAppsHook3
, alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, fontconfig, freetype
, gdk-pixbuf, glib, gtk3, libdrm, libnotify, libsecret, libuuid, libxkbcommon
, mesa, nss, pango, systemd, xorg, zlib, libgbm, gnome-keyring
, wayland, libGL, vulkan-loader, addDriverRunpath }:

stdenv.mkDerivation rec {
  pname = "void-editor";
  version = "1.99.30044";

  src = fetchurl {
    url = "https://github.com/voideditor/binaries/releases/download/${version}/Void-linux-x64-${version}.tar.gz";
    sha256 = "013aq1k0f5mayz73wfb5acadfpk20g0y0874jxryfsvia95rgsvv";
  };

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    wrapGAppsHook3
    addDriverRunpath
  ];

  buildInputs = [
    # Core system libraries
    alsa-lib at-spi2-atk cairo cups dbus expat fontconfig freetype
    gdk-pixbuf glib gtk3 libdrm libnotify libsecret libuuid libxkbcommon
    mesa nss pango systemd zlib libgbm gnome-keyring
    
    # Graphics and display
    wayland libGL vulkan-loader
  ] ++ (with xorg; [
    # X11 libraries
    libX11 libxcb libXcomposite libXdamage libXext libXfixes libXrandr
    libXrender libXtst libXScrnSaver libxkbfile libxshmfence libXi
    libXcursor libXinerama
  ]);

  dontConfigure = true;
  dontBuild = true;
  
  sourceRoot = ".";

  # Disable automatic wrapping since we'll do it manually
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    
    # Create directory structure
    mkdir -p $out/{bin,lib/void-editor,share/applications,share/icons/hicolor/512x512/apps}
    
    # Install application files
    cp -r * $out/lib/void-editor/
    
    # Make the main executable, well, executable
    chmod +x $out/lib/void-editor/void
    
    runHook postInstall
  '';

  postFixup = ''
    # Add driver runpath for hardware acceleration
    addDriverRunpath $out/lib/void-editor/void
    
    # Create working wrapper with minimal, stable Wayland flags
    makeWrapper $out/lib/void-editor/void $out/bin/void \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "--no-sandbox" \
      --add-flags "--disable-gpu" \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--password-store=basic" \
      --set WAYLAND_DISPLAY "wayland-0" \
      --set GDK_BACKEND "wayland" \
      --set ELECTRON_OZONE_PLATFORM_HINT "wayland" \
      --set NIXOS_OZONE_WL "1" \
      --set ELECTRON_IS_DEV "0" \
      --set ELECTRON_ENABLE_LOGGING "0" \
      --set ELECTRON_DISABLE_SECURITY_WARNINGS "1" \
      --prefix PATH : "${lib.makeBinPath [ gnome-keyring ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libGL vulkan-loader ]}"
      
    # Create desktop entry with working Wayland configuration
    cat > $out/share/applications/void-editor.desktop << EOF
[Desktop Entry]
Name=Void
Comment=Open source Cursor alternative - AI-powered code editor
GenericName=Code Editor
Exec=$out/bin/void %F
Icon=accessories-text-editor
Type=Application
Categories=Development;TextEditor;IDE;
MimeType=text/plain;text/x-markdown;application/json;text/x-python;text/x-javascript;text/x-typescript;text/x-c++;text/x-java;text/x-go;text/x-rust;
StartupNotify=true
StartupWMClass=void
Keywords=editor;code;development;programming;cursor;ai;
Actions=new-window;

[Desktop Action new-window]
Name=New Window
Exec=$out/bin/void --new-window
EOF
  '';

  meta = with lib; {
    description = "Void is an open source Cursor alternative - AI-powered code editor";
    homepage = "https://voideditor.com";
    license = licenses.mit; # Check actual license
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
