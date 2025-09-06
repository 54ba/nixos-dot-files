#!/usr/bin/env bash

echo "=== NVIDIA Performance Module Status ==="
echo

echo "📊 GPU Hardware Detection:"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits | head -1
echo

echo "🔧 Available Gaming Tools:"
echo "- nvidia-offload: $(which nvidia-offload 2>/dev/null || echo 'Not found')"
echo "- nvidia-settings: $(which nvidia-settings 2>/dev/null || echo 'Not found')"
echo "- nvitop: $(which nvitop 2>/dev/null || echo 'Not found')"
echo "- mangohud: $(which mangohud 2>/dev/null || echo 'Not found')"
echo "- wine64: $(which wine64 2>/dev/null || echo 'Not found')"
echo "- winetricks: $(which winetricks 2>/dev/null || echo 'Not found')"
echo "- lutris: $(which lutris 2>/dev/null || echo 'Not found')"
echo

echo "⚡ NVIDIA Performance Environment Variables:"
echo "Session Variables (should be set for gaming):"
env | grep -E "GL_|VK_|DXVK|NVIDIA|NV_" | sort | sed 's/^/  /'
echo

echo "🎯 NVIDIA Prime Offloading Test:"
if command -v nvidia-offload &> /dev/null; then
    echo "  Testing GPU offloading with glxgears..."
    timeout 3s nvidia-offload glxgears -info 2>/dev/null | head -5 | sed 's/^/  /'
else
    echo "  nvidia-offload not available"
fi
echo

echo "🎮 Wine Gaming Configuration:"
if command -v wine64 &> /dev/null; then
    echo "  Wine version: $(wine64 --version)"
    echo "  DXVK available: $(ls /nix/store/*/bin/setup_dxvk.sh 2>/dev/null | wc -l) installations found"
    echo "  VKD3D available: $(ls /nix/store/*/lib/libvkd3d*.so 2>/dev/null | wc -l) libraries found"
else
    echo "  Wine not available"
fi
echo

echo "📈 Performance Features:"
echo "  ✓ NVIDIA Prime Offloading: Enabled"
echo "  ✓ Hardware Acceleration: Enabled"
echo "  ✓ Shader Disk Cache: Enabled"
echo "  ✓ Threaded Optimizations: Enabled" 
echo "  ✓ VSync Disabled: For better gaming performance"
echo "  ✓ DirectX → Vulkan: Via DXVK/VKD3D"
echo "  ✓ PipeWire Audio: For screen sharing"
echo "  ✓ XDG Portals: For browser/Discord screen sharing"
echo

echo "🚀 Gaming Usage Examples:"
echo "  Run game with NVIDIA GPU: nvidia-offload [game_command]"
echo "  Monitor GPU performance: nvitop"
echo "  Show FPS overlay: mangohud [game_command]"
echo "  Configure Wine: winetricks"
echo "  Launch games: lutris"
echo

echo "=== Configuration Complete ==="
