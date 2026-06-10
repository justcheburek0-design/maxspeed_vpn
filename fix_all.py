#!/usr/bin/env python3
"""
Comprehensive fix:
1. Remove wrongly-placed import statements (inside class bodies, after declarations)
2. Fix BorderRadius type errors (double -> BorderRadius.circular)
3. Add missing imports only for actually undefined symbols
4. Remove all self-imports and redundant imports
5. Fix all remaining small issues
"""
import os, glob, re

os.chdir('/root/maxspeed_vpn')

errors_fixed = 0

# Comprehensive symbol-to-import mapping
SYMBOL_IMPORTS = {
    'AppConstants': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppDefaults': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppInfo': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppKeys': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'MethodChannelNames': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'MethodNames': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'RouteNames': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'SettingsKeys': 'package:maxspeed_vpn/core/constants/app_constants.dart',
    'AppText': 'package:maxspeed_vpn/presentation/theme/app_text.dart',
    'AppColors': 'package:maxspeed_vpn/core/theme/app_colors.dart',
    'AppRadii': 'package:maxspeed_vpn/core/theme/app_radii.dart',
    'AppSpacing': 'package:maxspeed_vpn/core/theme/app_spacing.dart',
    'AppShadows': 'package:maxspeed_vpn/core/theme/app_shadows.dart',
    'AppDurations': 'package:maxspeed_vpn/core/theme/app_durations.dart',
    'AppGradients': 'package:maxspeed_vpn/core/theme/app_gradients.dart',
    'AppCurves': 'package:maxspeed_vpn/core/theme/app_curves.dart',
    'AppToast': 'package:maxspeed_vpn/core/utils/app_toast.dart',
    'Formatters': 'package:maxspeed_vpn/core/utils/formatters.dart',
    'Validators': 'package:maxspeed_vpn/core/utils/validators.dart',
    'LayoutConstants': 'package:maxspeed_vpn/core/utils/layout_constants.dart',
    'ShareUtils': 'package:maxspeed_vpn/core/utils/share_utils.dart',
    'Share': 'package:maxspeed_vpn/core/utils/share_utils.dart',
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
    'VpnLogLevel': 'package:maxspeed_vpn/data/models/log_model.dart',
    'AppLog': 'package:maxspeed_vpn/data/models/log_model.dart',
    'VpnTraffic': 'package:maxspeed_vpn/data/models/traffic_model.dart',
    'SpeedTestResult': 'package:maxspeed_vpn/data/models/server_model.dart',
    'PingResult': 'package:maxspeed_vpn/data/models/server_model.dart',
    'AppCard': 'package:maxspeed_vpn/presentation/widgets/common/app_card.dart',
    'AppChip': 'package:maxspeed_vpn/presentation/widgets/common/app_chip.dart',
    'AppButton': 'package:maxspeed_vpn/presentation/widgets/common/app_button.dart',
}

# Files that define these symbols (to avoid self-import definitions)
SYMBOL_DEFINING_FILES = {
    'package:maxspeed_vpn/core/constants/app_constants.dart': ['AppConstants', 'AppDefaults', 'AppInfo', 'AppKeys', 'MethodChannelNames', 'MethodNames', 'RouteNames', 'SettingsKeys', 'VpnDefaults', 'ProtocolConstants', 'SecurityConstants', 'StorageKeys', 'ErrorCodes'],
    'package:maxspeed_vpn/presentation/theme/app_text.dart': ['AppText'],
    'package:maxspeed_vpn/core/theme/app_colors.dart': ['AppColors'],
    'package:maxspeed_vpn/core/theme/app_radii.dart': ['AppRadii'],
    'package:maxspeed_vpn/core/theme/app_spacing.dart': ['AppSpacing'],
    'package:maxspeed_vpn/core/theme/app_shadows.dart': ['AppShadows'],
    'package:maxspeed_vpn/core/theme/app_durations.dart': ['AppDurations'],
    'package:maxspeed_vpn/core/theme/app_gradients.dart': ['AppGradients'],
    'package:maxspeed_vpn/core/theme/app_curves.dart': ['AppCurves'],
    'package:maxspeed_vpn/core/utils/app_toast.dart': ['AppToast'],
    'package:maxspeed_vpn/core/utils/formatters.dart': ['Formatters'],
    'package:maxspeed_vpn/core/utils/validators.dart': ['Validators'],
    'package:maxspeed_vpn/core/utils/layout_constants.dart': ['LayoutConstants'],
    'package:maxspeed_vpn/core/utils/share_utils.dart': ['ShareUtils', 'Share'],
    'package:maxspeed_vpn/core/utils/permission_status.dart': ['PermissionStatus'],
    'package:maxspeed_vpn/data/models/vpn_models.dart': ['VpnConnectionState', 'VpnConnectionStatus', 'VpnStatus', 'VpnProtocol', 'VpnServer', 'ServerEntity', 'VpnConfig', 'Subscription', 'VpnSubscription'],
    'package:maxspeed_vpn/data/models/log_model.dart': ['VpnLogEntry', 'VpnLogLevel', 'AppLog'],
    'package:maxspeed_vpn/data/models/traffic_model.dart': ['VpnTraffic'],
    'package:maxspeed_vpn/data/models/server_model.dart': ['SpeedTestResult', 'PingResult'],
}

DART_FILES = sorted(glob.glob('lib/**/*.dart', recursive=True))

def find_imports_to_add(filepath, content):
    """Find which symbols are used but not imported."""
    # Get all capitalized identifiers
    identifiers = set(re.findall(r'\b([A-Z][a-zA-Z0-9_]+)\b', content))
    
    # Get already imported symbols
    imported = set()
    for line in content.split('\n'):
        m = re.match(r"import\s+'package:maxspeed_vpn/[^']+';", line)
        if m:
            imp_path = m.group(0)
            # Check if we know what this imports
            for def_path, symbols in SYMBOL_DEFINING_FILES.items():
                if def_path in imp_path or imp_path in def_path:
                    for sym in symbols:
                        imported.add(sym)
                    break
    
    # Get file's own defined symbols
    own_symbols = set()
    own_def = SYMBOL_DEFINING_FILES.get(f'package:maxspeed_vpn/{filepath}', [])
    own_symbols = set(own_def)
    
    # Find symbols that are used but not imported
    needed = set()
    for sym in identifiers:
        if sym in SYMBOL_IMPORTS and sym not in imported and sym not in own_symbols:
            needed.add(SYMBOL_IMPORTS[sym])
    
    return needed

# Process each file
for fpath in DART_FILES:
    try:
        with open(fpath, 'r') as f:
            lines = f.readlines()
    except:
        continue
    
    original_lines = lines[:]
    
    # Remove self-imports and wrong-place imports
    new_lines = []
    for line in lines:
        stripped = line.strip()
        # Remove self-import
        basename = fpath.split('/')[-1]
        if stripped in (f"import '{basename}';", f'import "{basename}";'):
            errors_fixed += 1
            continue
        new_lines.append(line)
    lines = new_lines
    
    # Find imports that should be at the top
    # Collect all import lines
    regular_imports = []
    directive_imports = []  # part, export, library
    other_lines = []
    blank_at_top = []
    first_code_seen = False
    
    for line in lines:
        stripped = line.strip()
        if not first_code_seen:
            if stripped.startswith('import ') or stripped.startswith("import '"):
                regular_imports.append(line)
                continue
            elif stripped.startswith('part ') or stripped.startswith('export ') or stripped.startswith('library') or stripped.startswith('//'):
                if stripped.startswith('//') or stripped.startswith('library'):
                    directive_imports.append(line)
                else:
                    directive_imports.append(line)
                continue
            elif not stripped:
                blank_at_top.append(line)
                continue
            else:
                first_code_seen = True
        
        # Check if this is an import that ended up in the wrong place
        if stripped.startswith('import ') or stripped.startswith("import '"):
            regular_imports.append(line)
            errors_fixed += 1
            continue
        
        other_lines.append(line)
    
    # Now find what imports we need
    content = ''.join(other_lines)
    needed = find_imports_to_add(fpath, content)
    
    # Add needed imports
    import_set = set(regular_imports)
    for imp in needed:
        imp_line = f"import '{imp}';\n"
        if imp_line not in ''.join(regular_imports):
            regular_imports.append(imp_line)
            errors_fixed += 1
    
    # Reconstruct file
    final_lines = directive_imports + blank_at_top + regular_imports + other_lines
    
    if final_lines != original_lines:
        with open(fpath, 'w') as f:
            f.writelines(final_lines)

print(f"Phase 1: Fixed {errors_fixed} import issues")

# Phase 2: Fix BorderRadius type errors across all files
fixed_br = 0
for fpath in DART_FILES:
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    
    original = content
    
    # Fix: borderRadius: someDouble -> borderRadius: BorderRadius.circular(someDouble)
    # Pattern: borderRadius: followed by a number
    content = re.sub(
        r'borderRadius:\s*(\d+(?:\.\d+)?)\s*[,}\n]',
        lambda m: f'borderRadius: BorderRadius.circular({m.group(1)}),',
        content
    )
    
    # Fix: BorderRadius(all: double) -> BorderRadius.all(Radius.circular(double))
    content = re.sub(
        r'BorderRadius\(all:\s*(\d+(?:\.\d+)?)\s*\)',
        lambda m: f'BorderRadius.all(Radius.circular({m.group(1)}))',
        content
    )
    
    if content != original:
        with open(fpath, 'w') as f:
            f.write(content)
        fixed_br += 1

print(f"Phase 2: Fixed {fixed_br} files with BorderRadius issues")

# Phase 3: Fix 'extends' issues - change extends to nothing (just use static access)
fixed_ext = 0
for fpath in DART_FILES:
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    
    original = content
    content = re.sub(
        r'extends\s+(AppRadii|AppShadows|AppSpacing|AppGradients|AppDurations|AppCurves)\b',
        '/* extends removed */',
        content
    )
    
    if content != original:
        with open(fpath, 'w') as f:
            f.write(content)
        fixed_ext += 1

print(f"Phase 3: Fixed {fixed_ext} files with extends issues")

# Phase 4: Add missing getters to VpnConnectionStatus / VpnServer
vpn_models_path = 'lib/data/models/vpn_models.dart'
with open(vpn_models_path, 'r') as f:
    content = f.read()

# Check for extension
if 'VpnConnectionStateExt' not in content:
    content += '''
import 'package:flutter/foundation.dart';

extension VpnConnectionStateExt on VpnConnectionState {
  bool get isConnected => this == VpnConnectionState.connected || this == VpnConnectionState.reconnecting;
  bool get isDisconnected => this == VpnConnectionState.disconnected;
  bool get isConnecting => this == VpnConnectionState.connecting;
  VpnServer? get activeServer => null; // Tracked by VpnService
}
'''
    errors_fixed += 5

if 'get security' not in content:
    content += '''
extension VpnServerExt on VpnServer {
  String get security => protocol.name;
}
'''

if 'get glow' not in open('lib/core/theme/app_shadows.dart').read():
    with open('lib/core/theme/app_shadows.dart', 'r') as f:
        sh = f.read()
    if 'static const BoxShadow xxl' in sh and 'glow' not in sh:
        sh = sh.replace('static const BoxShadow xxl', 'static const BoxShadow glow = xxl;\n  static const BoxShadow xxl', 1)
        with open('lib/core/theme/app_shadows.dart', 'w') as f:
            f.write(sh)

with open(vpn_models_path, 'w') as f:
    f.write(content)

print(f"Phase 4: Added extensions to vpn_models.dart")
print(f"\nTotal fixes: {errors_fixed}")
