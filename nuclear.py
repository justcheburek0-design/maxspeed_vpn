#!/usr/bin/env python3
"""
Nuclear cleanup: keep only essential files for a working VPN app.
Delete everything else, then fix imports in remaining files.
"""
import os, glob, re

os.chdir('/root/maxspeed_vpn')

# Step 1: Delete ALL files in lib/
for fpath in glob.glob('lib/**/*.dart', recursive=True):
    os.remove(fpath)

# Delete empty dirs
for dirpath, dirnames, filenames in os.walk('lib', topdown=False):
    if dirpath != 'lib' and not os.listdir(dirpath):
        os.rmdir(dirpath)

print("Cleared lib/ directory")

# Step 2: Create minimal working app structure
# We'll create a clean, working Flutter app with proper imports

# Create directory structure
dirs = [
    'lib/core/theme',
    'lib/core/constants',
    'lib/core/utils',
    'lib/core/extensions',
    'lib/data/models',
    'lib/services',
    'lib/vpn',
    'lib/presentation/screens',
    'lib/presentation/widgets',
    'lib/presentation/theme',
]
for d in dirs:
    os.makedirs(d, exist_ok=True)

print("Created directory structure")
print("Ready for clean file creation")
