# Flutter Development Shell
# Usage: nix-shell /etc/nixos/shells/flutter-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "flutter-dev-shell";
  
  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter
    dart
    
    # Android development tools
    android-tools  # ADB, fastboot
    android-studio  # IDE (optional)
    
    # Chrome for web development
    google-chrome
    
    # Additional development tools
    git
    vim
    curl
    jq
    unzip
    
    # Build tools
    cmake
    ninja
    pkg-config
    
    # Graphics libraries for Linux desktop development
    gtk3
    glib
    
    # Development utilities
    fish  # Better shell for development
  ];
  
  shellHook = ''
    echo "📱 Flutter Development Environment"
    echo "Flutter version: $(flutter --version | head -n 1)"
    echo "Dart version: $(dart --version)"
    echo "Android tools: adb, fastboot"
    echo ""
    echo "Supported platforms:"
    echo "  • Android (via Android Studio/adb)"
    echo "  • Web (via Chrome)"
    echo "  • Linux desktop"
    echo ""
    echo "Quick start:"
    echo "  flutter create my_app          # Create new Flutter app"
    echo "  flutter doctor                 # Check Flutter setup"
    echo "  flutter devices                # List available devices"
    echo "  flutter run                    # Run app"
    echo "  flutter build apk              # Build Android APK"
    echo "  flutter build web              # Build for web"
    echo "  flutter build linux            # Build for Linux desktop"
    echo ""
    echo "Useful commands:"
    echo "  flutter pub get                # Get dependencies"
    echo "  flutter pub upgrade            # Upgrade dependencies"
    echo "  flutter clean                  # Clean build cache"
    echo "  flutter analyze                # Analyze code"
    echo "  flutter test                   # Run tests"
    
    # Set up Flutter environment
    export FLUTTER_ROOT="$(dirname $(which flutter))"
    export ANDROID_HOME="$HOME/Android/Sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
    
    # Enable Flutter web and desktop
    flutter config --enable-web
    flutter config --enable-linux-desktop
    
    echo ""
    echo "Running flutter doctor to check setup..."
    flutter doctor
  '';
}

