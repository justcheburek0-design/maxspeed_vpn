#!/usr/bin/env python3
"""Final cleanup pass."""
import os, re, glob

os.chdir('/root/maxspeed_vpn')

# 1. Remove app_text_styles.dart and fix references
app_text_styles = 'lib/presentation/theme/app_text_styles.dart'
if os.path.exists(app_text_styles):
    os.remove(app_text_styles)

for fpath in glob.glob('lib/**/*.dart', recursive=True):
    try:
        with open(fpath, 'r') as f:
            content = f.read()
    except:
        continue
    if 'app_text_styles.dart' in content:
        content = content.replace("app_text_styles.dart", "app_text.dart")
        with open(fpath, 'w') as f:
            f.write(content)
        print(f"  FIXED import: {fpath}")

# 2. Ensure LayoutConstants exists
layout = 'lib/core/utils/layout_constants.dart'
os.makedirs(os.path.dirname(layout), exist_ok=True)
if not os.path.exists(layout):
    with open(layout, 'w') as f:
        f.write("""class LayoutConstants {
  static const double maxContentWidth = 600;
  static const double sidebarWidth = 280;
  static const double bottomNavHeight = 64;
  static const double topBarHeight = 56;
  static const double fabSize = 56;
  static const double drawerWidth = 300;
  static const double dialogMaxWidth = 480;
  static const double listItemHeight = 72;
  static const double cardMinHeight = 120;
}""")
    print("  CREATED: LayoutConstants")

# 3. Ensure ShareUtils exists
share = 'lib/core/utils/share_utils.dart'
os.makedirs(os.path.dirname(share), exist_ok=True)
if not os.path.exists(share):
    with open(share, 'w') as f:
        f.write("""class ShareUtils {
  static Future<void> shareText(String text) async {}
  static Future<void> copyToClipboard(String text) async {}
  static Future<String?> getClipboard() async => null;
}""")
    print("  CREATED: ShareUtils")

# 4. Fix AppShadows - add glow
shadows = 'lib/core/theme/app_shadows.dart'
with open(shadows, 'r') as f:
    sh = f.read()
if 'glow' not in sh:
    sh = sh + '\n  // Legacy aliases\n  static const glow = xxl;\n'
    with open(shadows, 'w') as f:
        f.write(sh)
    print("  FIXED: glow in AppShadows")

print("\nDone!")
