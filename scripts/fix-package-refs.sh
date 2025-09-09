#!/usr/bin/env bash

# NixOS Package Reference Fixer
# This script helps identify and fix common package reference issues in nix files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NixOS Package Reference Fixer ===${NC}"

# Source environment variables
if [ -f ".env" ]; then
    source .env
    echo -e "${GREEN}✓ Loaded environment variables${NC}"
else
    echo -e "${YELLOW}⚠ No .env file found, using defaults${NC}"
fi

# Find all nix files that contain package references
echo -e "\n${BLUE}Scanning for nix files with package references...${NC}"
nix_files=$(find . -name "*.nix" -type f -exec grep -l "pkgs\." {} \;)

for file in $nix_files; do
    echo -e "\n${BLUE}Checking $file for package issues...${NC}"
    
    # Check for packages that might not exist
    problematic_pkgs=$(grep -E "pkgs\.[a-zA-Z0-9]+[a-zA-Z0-9_-]*" "$file" | grep -v "#" | sed 's/.*pkgs\.\([a-zA-Z0-9][a-zA-Z0-9_-]*\).*/\1/g' | sort | uniq)
    
    for pkg in $problematic_pkgs; do
        # Check if package exists in nixpkgs
        if ! nix-env -qaP --json "^$pkg\$" >/dev/null 2>&1; then
            # Try to find similar packages
            echo -e "${YELLOW}⚠ Possible issue: Package '$pkg' might not exist in nixpkgs${NC}"
            echo -e "  Suggestions:"
            
            # Check with lowercase version
            if [[ "$pkg" != "${pkg,,}" ]]; then
                echo -e "    - Try ${pkg,,} (lowercase version)"
            fi
            
            # Check with common replacements
            if [[ "$pkg" == *"-"* ]]; then
                echo -e "    - Try ${pkg//-/_} (replace hyphens with underscores)"
            fi
            
            # Search for similar packages
            similar=$(nix-env -qaP --json | grep -i "$pkg" | head -3)
            if [ -n "$similar" ]; then
                echo -e "    - Similar packages found: $similar"
            fi
            
            read -p "  Would you like to automatically fix references to '$pkg'? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Prompt for replacement
                read -p "  Enter replacement package name: " replacement
                if [ -n "$replacement" ]; then
                    sed -i "s/pkgs\.$pkg/pkgs.$replacement/g" "$file"
                    echo -e "${GREEN}✓ Replaced 'pkgs.$pkg' with 'pkgs.$replacement' in $file${NC}"
                fi
            fi
        fi
    done
    
    # Check for nodePackages references which should use nodePackages.
    node_refs=$(grep -E "pkgs\.node[a-zA-Z0-9_-]+" "$file" | grep -v "pkgs\.nodePackages" | grep -v "#")
    if [ -n "$node_refs" ]; then
        echo -e "${YELLOW}⚠ Found Node.js package references that might need correction:${NC}"
        echo "$node_refs"
        
        read -p "  Would you like to automatically fix Node.js package references? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i 's/pkgs\.node\([a-zA-Z0-9_-]\+\)/pkgs.nodePackages.\1/g' "$file"
            echo -e "${GREEN}✓ Fixed Node.js package references in $file${NC}"
        fi
    fi
    
    # Check for python packages that should use python3Packages
    python_refs=$(grep -E "pkgs\.python[a-zA-Z0-9_-]+" "$file" | grep -v "pkgs\.python3Packages" | grep -v "pkgs\.python3" | grep -v "#")
    if [ -n "$python_refs" ]; then
        echo -e "${YELLOW}⚠ Found Python package references that might need correction:${NC}"
        echo "$python_refs"
        
        read -p "  Would you like to automatically fix Python package references? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i 's/pkgs\.python\([a-zA-Z0-9_-]\+\)/pkgs.python3Packages.\1/g' "$file"
            echo -e "${GREEN}✓ Fixed Python package references in $file${NC}"
        fi
    fi
done

echo -e "\n${GREEN}=== Package reference check completed! ===${NC}"
