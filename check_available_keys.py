#!/usr/bin/env python3
"""Check available keys for specific patterns"""
import json

with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

keys = sorted(data.get('strings', {}).keys())

# Search for keys matching patterns
patterns = [
    'error', 'empty', 'library', 'browse', 'source', 'manga', 'page',
    'download', 'backup', 'security', 'tracking', 'action_login',
    'about', 'version', 'platform', 'disclaimer', 'pref_download',
    'show_nsfw', 'browse_hide', 'incognito', 'crop', 'skip_read',
    'label_in_library', 'not_in_library', 'no_results',
]

for pattern in patterns:
    matching = [k for k in keys if pattern in k.lower()]
    if matching:
        print(f'\n"{pattern}":')
        for k in matching[:5]:
            print(f'  {k}')
