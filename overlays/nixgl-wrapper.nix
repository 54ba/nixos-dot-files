final: prev: {
  # Wrapper function to easily create nixGL-wrapped packages
  nixGLWrap = package: 
    if (final ? nixgl) then
      final.runCommand "${package.name}-nixgl" {} ''
        mkdir -p $out/bin
        for bin in ${package}/bin/*; do
          if [ -f "$bin" ]; then
            cat > "$out/bin/$(basename "$bin")" << EOF
#!/bin/sh
exec ${final.nixgl.nixGLIntel}/bin/nixGLIntel "$bin" "\$@"
EOF
            chmod +x "$out/bin/$(basename "$bin")"
          fi
        done
        
        # Copy other directories if they exist
        for dir in share lib include; do
          if [ -d "${package}/$dir" ]; then
            ln -s "${package}/$dir" "$out/$dir"
          fi
        done
      ''
    else package;

  # Pre-wrapped common GUI applications that need OpenGL (conditional)
  blender-nixgl = if (final ? nixgl) then final.nixGLWrap final.blender else final.blender;
  gimp-nixgl = if (final ? nixgl) then final.nixGLWrap final.gimp else final.gimp;
  inkscape-nixgl = if (final ? nixgl) then final.nixGLWrap final.inkscape else final.inkscape;
  obs-studio-nixgl = if (final ? nixgl) then final.nixGLWrap final.obs-studio else final.obs-studio;
  vlc-nixgl = if (final ? nixgl) then final.nixGLWrap final.vlc else final.vlc;
  mpv-nixgl = if (final ? nixgl) then final.nixGLWrap final.mpv else final.mpv;
  steam-nixgl = if (final ? nixgl) then final.nixGLWrap final.steam else final.steam;
  lutris-nixgl = if (final ? nixgl) then final.nixGLWrap final.lutris else final.lutris;
  heroic-nixgl = if (final ? nixgl) then final.nixGLWrap final.heroic else final.heroic;
  figma-linux-nixgl = if (prev ? figma-linux && final ? nixgl) then final.nixGLWrap final.figma-linux else if (prev ? figma-linux) then final.figma-linux else null;
  
  # Add aliases for convenience
  blenderGL = final.blender-nixgl;
  gimpGL = final.gimp-nixgl;
  inkscapeGL = final.inkscape-nixgl;
  obsGL = final.obs-studio-nixgl;
  vlcGL = final.vlc-nixgl;
  mpvGL = final.mpv-nixgl;
  steamGL = final.steam-nixgl;
  lutrisGL = final.lutris-nixgl;
  heroicGL = final.heroic-nixgl;
}

