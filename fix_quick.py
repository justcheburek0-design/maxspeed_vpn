#!/usr/bin/env python3
"""Quick final fixes."""
import os, glob

os.chdir('/root/maxspeed_vpn')

# 1. Replace AppTextStyles references everywhere
for fpath in glob.glob('lib/**/*.dart', recursive=True):
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    orig = content
    content = content.replace('AppTextStyles', 'AppText')
    if content != orig:
        with open(fpath, 'w') as f:
            f.write(content)
        print(f"  FIXED AppTextStyles: {fpath}")

# 2. Fix AppShadows glow + dark aliases
shadows = 'lib/core/theme/app_shadows.dart'
with open(shadows, 'r') as f:
    sh = f.read()
if '  static const BoxShadow glow = xxl;' not in sh:
    sh = sh.replace('  static const glow = xxl;', '  static const glow = xxl;\n  static const dark = xxl;\n')
    with open(shadows, 'w') as f:
        f.write(sh)
    print("  FIXED: dark in AppShadows")

# 3. Fix AppGradients dark alias
grads = 'lib/core/theme/app_gradients.dart'
with open(grads, 'r') as f:
    g = f.read()
if 'dark' not in g:
    g = g + '\n  // Legacy aliases\n  static const dark = card;\n'
    with open(grads, 'w') as f:
        f.write(g)
    print("  FIXED: dark in AppGradients")

# 4. Fix VpnLogEntry duplication
vpn = 'lib/data/models/vpn_models.dart'
log = 'lib/data/models/log_model.dart'
with open(vpn, 'r') as f:
    vm = f.read()
with open(log, 'r') as f:
    lm = f.read()
if 'VpnLogEntry' in vm and 'VpnLogEntry' in lm:
    # Remove from vpn_models
    vm = re.sub(r'class VpnLogEntry \{.*?\n\}', '', vm, flags=re.DOTALL)
    vm = vm.replace('VpnLogEntry', 'dynamic')  # Replace remaining refs
    with open(vpn, 'w') as f:
        f.write(vm)
    print("  FIXED: VpnLogEntry dedup")

import re
print("\nDone!")
