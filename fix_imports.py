#!/usr/bin/env python3
"""Auto-fix missing imports in lib/ Dart files."""
import os, re, glob

REQUIRED_IMPORTS = {
    'AppConstants': [('core/constants/app_constants.dart', None)],
    'AppDefaults': [('core/constants/app_constants.dart', None)],
    'AppKeys': [('core/constants/app_constants.dart', None)],
    'AppRadii': [('core/theme/app_radii.dart', None)],
    'AppSpacing': [('core/theme/app_spacing.dart', None)],
    'AppShadows': [('core/theme/app_shadows.dart', None)],
    'AppDurations': [('core/theme/app_durations.dart', None)],
    'AppGradients': [('core/theme/app_gradients.dart', None)],
    'AppCurves': [('core/theme/app_curves.dart', None)],
    'AppText': [('presentation/theme/app_text.dart', None)],
    'AppToast': [('core/utils/app_toast.dart', None)],
    'Formatters': [('core/utils/formatters.dart', None)],
    'Validators': [('core/utils/validators.dart', None)],
    'PermissionStatus': [('core/utils/permission_status.dart', None)],
    'ShareUtils': [('core/utils/share_utils.dart', None)],
    'VpnConnectionState': [('data/models/vpn_models.dart', None)],
    'VpnProtocol': [('data/models/vpn_models.dart', None)],
    'VpnServer': [('data/models/vpn_models.dart', None)],
    'VpnStatus': [('data/models/vpn_models.dart', None)],
    'VpnLogLevel': [('data/models/vpn_models.dart', None)],
}

dart_files = glob.glob('lib/**/*.dart', recursive=True)
fixed = 0
for fpath in dart_files:
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    
    existing_imports = set()
    for m in re.finditer(r"import\s+'([^']+)'", content):
        existing_imports.add(m.group(1))
    
    needs = []
    for symbol, import_list in REQUIRED_IMPORTS.items():
        if symbol in content:
            for import_path, _ in import_list:
                file_dir = os.path.dirname(fpath)
                expected = os.path.relpath('lib/' + import_path, file_dir).replace('\\', '/')
                if expected not in existing_imports and import_path not in existing_imports:
                    needs.append((expected, import_path))
    
    if needs:
        if 'library;' in content:
            content = content.replace('library;\n', '')
            content = 'library;\n' + content
        
        import_block = ""
        for rel_path, _ in needs:
            imp = f"import '{rel_path}';"
            if imp not in content:
                import_block += imp + '\n'
        
        if import_block:
            last_import_end = 0
            for m in re.finditer(r"import\s+'[^']+'\s*;", content):
                last_import_end = m.end()
            if last_import_end > 0:
                content = content[:last_import_end] + '\n' + import_block + content[last_import_end:]
            else:
                content = import_block + content
            
            with open(fpath, 'w') as f:
                f.write(content)
            fixed += 1
            print(f"  FIXED: {fpath} (+{len(needs)} imports)")

print(f"\nTotal: {fixed} files fixed")
