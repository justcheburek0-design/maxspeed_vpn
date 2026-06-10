#!/usr/bin/env python3
"""Comprehensive import fix for maxspeed_vpn."""
import os, glob, re

os.chdir('/root/maxspeed_vpn')

# Symbol -> import path mapping
SYMBOL_IMPORTS = {
    # Our app symbols
    'AppConstants': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppDefaults': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppInfo': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppKeys': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppText': 'package:maxspeed_vpn/presentation/theme/app_text.dart',
    'AppTextStyles': 'package:maxspeed_vpn/presentation/theme/app_text.dart',
    'AppColors': 'package:maxspeed_vpn/core/theme/app_colors.dart',
    'AppRadii': 'package:maxspeed_vpn/core/theme/app_radii.dart',
    'AppSpacing': 'package:maxspeed_vpn/core/theme/app_spacing.dart',
    'AppShadows': 'package:maxspeed_vpn/core/theme/app_shadows.dart',
    'AppDurations': 'package:maxspeed_vpn/core/theme/app_durations.dart',
    'AppGradients': 'package:maxspeed_vpn/core/theme/app_gradients.dart',
    'AppCurves': 'package:maxspeed_vpn/core/theme/app_curves.dart',
    'AppToast': 'package:maxspeed_vpn/core/utils/app_toast.dart',
    'Formatters': 'package:maxspeed_vpn/core/utils/formatters.dart',
    'Validation': 'package:maxspeed_vpn/core/utils/validators.dart',
    'LayoutConstants': 'package:maxspeed_vpn/core/utils/layout_constants.dart',
    'Share': 'package:maxspeed_vpn/core/utils/share_utils.dart',
    'ShareResult': 'package:maxspeed_vpn/core/utils/share_utils.dart',
    'ShareUtils': 'package:maxspeed_vpn/core/utils/share_utils.dart',
    'PermissionStatus': 'package:maxspeed_vpn/core/utils/permission_status.dart',
    'VpnConnectionState': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnConnectionStatus': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnStatus': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnProtocol': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnServer': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'ServerEntity': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnConfig': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'Subscription': 'package:maxspeed_vpn/data/models/vpn_models.dart',
    'VpnLogEntry': 'package:maxspeed_vpn/data/models/log_model.dart',
    'AppLog': 'package:maxspeed_vpn/data/models/log_model.dart',
    'Vpn_traffic': 'package:maxspeed_vpn/data/models/traffic_model.dart',
    'SpeedTestResult': 'package:maxspeed_vpn/data/models/server_model.dart',
    'PingResult': 'package:maxspeed_vpn/data/models/server_model.dart',
}

DART_FILES = glob.glob('lib/**/*.dart', recursive=True)
fixed_count = 0

for fpath in sorted(DART_FILES):
    try:
        with open(fpath, 'r') as f:
            lines = f.readlines()
    except:
        continue

    content = ''.join(lines)
    
    # Find all identifiers in the file
    identifiers = set(re.findall(r'\b([A-Z][a-zA-Z0-9_]+)\b', content))
    
    # Check which ones might need imports
    needed_imports = set()
    for sym in identifiers:
        if sym in SYMBOL_IMPORTS:
            imp = SYMBOL_IMPORTS[sym]
            # Don't add self-import
            if imp.split('/')[-1] != fpath.split('/')[-1]:
                if imp not in content:
                    needed_imports.add(imp)
    
    if needed_imports:
        # Find where to insert imports (after existing imports)
        insert_idx = 0
        for i, line in enumerate(lines):
            if line.strip().startswith('import ') or line.strip().startswith("import '"):
                insert_idx = i + 1
            elif line.strip().startswith('library'):
                insert_idx = i + 1
            elif line.strip().startswith('//') and i < 5:
                continue
            elif not line.strip() and i > 0 and (lines[i-1].strip().startswith('import') or lines[i-1].strip().startswith('//')):
                insert_idx = i + 1
        
        for imp in sorted(needed_imports):
            lines.insert(insert_idx, f"import '{imp}';\n")
            insert_idx += 1
            fixed_count += 1
        
        with open(fpath, 'w') as f:
            f.writelines(lines)

print(f"Added {fixed_count} imports across {len(DART_FILES)} files")
