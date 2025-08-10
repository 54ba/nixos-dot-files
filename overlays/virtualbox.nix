# VirtualBox overlay for binary cache optimizations
self: super: {
  # Override VirtualBox to prefer pre-built packages when possible
  virtualbox = super.virtualbox.override {
    # Try to use cached builds for dependencies
    enableHardening = true;
    pulseSupport = true;
  };
}
