final: prev: {
  warp-terminal = prev.stdenv.mkDerivation {
    name = "warp-terminal";
    version = "0.2024.02.20.08.01.stable.02";
    
    src = prev.fetchurl {
      url = "https://releases.warp.dev/stable/v0.2024.02.20.08.01.stable_02/warp-terminal_0.2024.02.20.08.01.stable.02_amd64.deb";
      sha256 = "0fd0fxcl17ikhx32vc2k8vzrb0km585199r74qgfl7307clryh0p"; # Updated with actual hash
    };
    
    nativeBuildInputs = with prev; [
      autoPatchelfHook
      dpkg
    ];
    
    buildInputs = with prev; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libglvnd
      libnotify
      libpulseaudio
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      wayland
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libxcb
      zlib
    ];
    
    unpackPhase = "dpkg-deb -x $src .";
    
    installPhase = ''
      mkdir -p $out
      cp -R usr/* $out/
      cp -R opt/ $out/
      
      # Create bin directory and symlink the warp binary
      mkdir -p $out/bin
      ln -s $out/opt/warpdotdev/warp-terminal/warp $out/bin/warp-terminal
    '';
    
    meta = with prev.lib; {
      description = "Warp Terminal";
      homepage = "https://warp.dev";
      license = licenses.unfree;
      maintainers = with maintainers; [ ];
      platforms = [ "x86_64-linux" ];
    };
  };
}

