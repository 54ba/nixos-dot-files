#!/run/current-system/sw/bin/bash

# Script to fix NVIDIA Vulkan ICD in NixOS

# Ensure the Vulkan ICD directory exists

sudo mkdir -p /etc/vulkan/icd.d

# Create the NVIDIA ICD file if it exists, otherwise create a default one

if [ -f /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json ]; then

    sudo cp /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json

else

    sudo tee /etc/vulkan/icd.d/nvidia_icd.json > /dev/null <<EOF
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "libGLX_nvidia.so.0",
        "api_version": "1.3.0"
    }
}
EOF

fi

# Link Mesa ICDs

sudo ln -sf /run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json /etc/vulkan/icd.d/intel_icd.x86_64.json

sudo ln -sf /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json /etc/vulkan/icd.d/radeon_icd.x86_64.json

# Update the dynamic linker cache

sudo ldconfig

echo "NVIDIA and Mesa Vulkan ICDs fixed."