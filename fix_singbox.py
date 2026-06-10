with open('lib/vpn/singbox_config_generator.dart', 'rb') as f:
    content = f.read()

# Fix the REDACTED placeholders
fixed = bytearray(content)

# Strategy: find and replace byte sequences
import re

# Replace "p = <REDACTED> with "p = <REDACTED>
# Using bytes replacement
patterns = [
    (b'p = <REDACTED> b'p = <REDACTED>
    (b'} else { u = s.username; p = <REDACTED>
     b'} else { u = s.username; p = <REDACTED>
]

for old, new in patterns:
    fixed = fixed.replace(old, new)

with open('lib/vpn/singbox_config_generator.dart', 'wb') as f:
    f.write(fixed)

# Verify
text = bytes(fixed).decode('utf-8')
print(text)
