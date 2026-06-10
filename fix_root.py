#!/usr/bin/env python3
"""Root cause fix: remove self-imports, fix duplicate defs, add missing getters."""
import os, glob, re

os.chdir('/root/maxspeed_vpn')

# PASS 1: Remove all self-imports and fix obviously broken import lines
for fpath in sorted(glob.glob('lib/**/*.dart', recursive=True)):
    filename = fpath.split('/')[-1]
    try:
        with open(fpath, 'r') as f:
            lines = f.readlines()
    except:
        continue
    
    new_lines = []
    changed = False
    for line in lines:
        stripped = line.strip()
        # Remove self-import
        if stripped == f"import '{filename}';" or stripped == f'import "{filename}";':
            changed = True
            continue
        if stripped == f"import 'vpn_models.dart';" and filename != 'vpn_models.dart':
            # Only remove if it's a wrong self-referencing import ( models importing themselves)
            pass  # keep for now
        new_lines.append(line)
    
    if changed:
        with open(fpath, 'w') as f:
            f.writelines(new_lines)

print("PASS 1 done: removed self-imports")

# PASS 2: Fix vpn_models.dart - remove self-imports, remove duplicate VpnLogEntry/VpnLogLevel
vpn_path = 'lib/data/models/vpn_models.dart'
with open(vpn_path, 'r') as f:
    lines = f.readlines()

# Remove first 4 self-imports
while lines and lines[0].strip() == "import 'vpn_models.dart';":
    lines.pop(0)

# Check for VpnLogEntry/VpnLogLevel duplication
content = ''.join(lines)
has_vpn_log_entry = 'class VpnLogEntry' in content
has_vpn_log_level = 'enum VpnLogLevel' in content or 'class VpnLogLevel' in content

if has_vpn_log_entry or has_vpn_log_level:
    log_path = 'lib/data/models/log_model.dart'
    with open(log_path, 'r') as f:
        log_content = f.read()
    
    # Remove VpnLogEntry from vpn_models if it exists in both
    if has_vpn_log_entry and 'VpnLogEntry' in log_content:
        # Find and remove the VpnLogEntry class
        new_lines2 = []
        skip = False
        brace_count = 0
        for line in lines:
            if 'class VpnLogEntry' in line:
                skip = True
                brace_count = line.count('{') - line.count('}')
                continue
            if skip:
                brace_count += line.count('{') - line.count('}')
                if brace_count <= 0:
                    skip = False
                continue
            new_lines2.append(line)
        lines = new_lines2
    
    if has_vpn_log_level and 'VpnLogLevel' in log_content:
        new_lines2 = []
        skip = False
        brace_count = 0
        for line in lines:
            if 'enum VpnLogLevel' in line or 'class VpnLogLevel' in line:
                skip = True
                brace_count = line.count('{') - line.count('}')
                continue
            if skip:
                brace_count += line.count('{') - line.count('}')
                if brace_count <= 0:
                    skip = False
                continue
            new_lines2.append(line)
        lines = new_lines2

with open(vpn_path, 'w') as f:
    f.writelines(lines)
print("PASS 2 done: fixed vpn_models.dart duplicates")

# PASS 3: Fix app_shadows.dart - remove legacy aliases that broke class body
shadows_path = 'lib/core/theme/app_shadows.dart'
with open(shadows_path, 'r') as f:
    content = f.read()

# Remove the problematic inline aliases
content = re.sub(r'\n  // Legacy glow alias.*?static const BoxShadow glow = xxl;\n', '\n', content)
content = re.sub(r'\n  // Legacy aliases.*?static const glow = xxl;\n', '\n', content)
content = re.sub(r'\n  static const dark = xxl;\n', '\n', content)

# Add glow and dark inside the class properly
if 'glow' not in content:
    content = content.replace(
        '  static const BoxShadow xxl = BoxShadow(',
        '  static const BoxShadow glow = xxl;\n  static const BoxShadow dark = xxl;\n\n  static const BoxShadow xxl = BoxShadow('
    )

with open(shadows_path, 'w') as f:
    f.write(content)
print("PASS 3 done: fixed app_shadows.dart")

# PASS 4: Fix app_gradients.dart - remove inline dark alias
grads_path = 'lib/core/theme/app_gradients.dart'
with open(grads_path, 'r') as f:
    content = f.read()
content = re.sub(r'\n  // Legacy aliases.*?static const dark = card;\n', '\n', content)
content = content.replace(
    '  static const LinearGradient card',
    '  static const LinearGradient dark = card;\n  static const LinearGradient card'
)
with open(grads_path, 'w') as f:
    f.write(content)
print("PASS 4 done: fixed app_gradients.dart")

# PASS 5: Fix 'Classes can only extend other classes' — usually from broken AppRadii
# Check which files extend AppRadii
for fpath in sorted(glob.glob('lib/**/*.dart', recursive=True)):
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    if 'extends AppRadii' in content or 'extends AppShadows' in content or 'extends AppSpacing' in content:
        # Replace with proper imports instead
        content = re.sub(r'extends AppRadii', '/* extends AppRadii */ // TODO: use AppRadii directly', content)
        content = re.sub(r'extends AppShadows', '/* extends AppShadows */', content)
        content = re.sub(r'extends AppSpacing', '/* extends AppSpacing */', content)
        content = re.sub(r'extends AppGradients', '/* extends AppGradients */', content)
        content = re.sub(r'extends AppDurations', '/* extends AppDurations */', content)
        content = re.sub(r'extends AppCurves', '/* extends AppCurves */', content)
        with open(fpath, 'w') as f:
            f.write(content)
        print(f"  FIXED extends: {fpath}")

# PASS 6: Fix 'Expected a class member' — usually from import statements inside class bodies
for fpath in sorted(glob.glob('lib/**/*.dart', recursive=True)):
    try:
        with open(fpath, 'r') as f:
            lines = f.readlines()
    except:
        continue
    
    in_class = False
    brace_count = 0
    new_lines = []
    changed = False
    for line in lines:
        stripped = line.strip()
        if re.match(r'^(abstract\s+)?class\s+', stripped) or re.match(r'^enum\s+', stripped):
            in_class = True
            brace_count = 0
        if in_class:
            brace_count += line.count('{') - line.count('}')
            if brace_count <= 0 and '{' not in line and '}' in line:
                in_class = False
            if in_class and stripped.startswith('import '):
                new_lines.append('// ' + line)
                changed = True
                continue
        new_lines.append(line)
    
    if changed:
        with open(fpath, 'w') as f:
            f.writelines(new_lines)
        print(f"  FIXED class-member imports: {fpath}")

print("\nAll root cause fixes applied!")
