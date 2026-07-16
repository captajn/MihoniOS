#!/usr/bin/env python3
"""Check for invalid i18n keys in Swift files"""
import re
import json
import os
from pathlib import Path

with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)
valid_keys = set(data.get('strings', {}).keys())

features_dir = Path('E:/Code/mihon-main/ios/Features')
app_dir = Path('E:/Code/mihon-main/ios/App')

invalid_found = []
for directory in [features_dir, app_dir]:
    for swift_file in directory.rglob('*.swift'):
        content = open(swift_file, 'r', encoding='utf-8').read()
        matches = re.findall(r'String\(localized: "([^"]+)"\)', content)
        for key in matches:
            if key not in valid_keys:
                invalid_found.append((swift_file.name, key))

if invalid_found:
    print('Invalid keys found:')
    for fname, key in invalid_found[:50]:
        print(f'  {fname}: {key}')
else:
    print('All keys are valid!')
