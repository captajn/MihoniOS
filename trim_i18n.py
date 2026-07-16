#!/usr/bin/env python3
"""Trim Localizable.xcstrings to only English and Vietnamese"""
import json

path = 'E:/Code/mihon-main/ios/Resources/Localizable.xcstrings'

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Keep only en and vi
keep_langs = {'en', 'vi'}
strings = data.get('strings', {})

for key, value in strings.items():
    localizations = value.get('localizations', {})
    # Filter to only en and vi
    filtered = {lang: loc for lang, loc in localizations.items() if lang in keep_langs}
    value['localizations'] = filtered

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Trimmed to {len(strings)} keys, only en+vi")
