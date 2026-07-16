#!/usr/bin/env python3
import json

with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

keys = list(data.get('strings', {}).keys())
print(f'Total keys: {len(keys)}')
print('\nFirst 30 keys:')
for k in keys[:30]:
    print(f'  {k}')

# Check if specific keys exist
check_keys = [
    'onboarding_welcome', 'label_library', 'label_download_queue',
    'categories', 'action_search', 'action_add', 'action_delete',
    'loading', 'all', 'action_done', 'action_cancel',
    'pref_category_reader', 'pref_category_downloads',
]
print('\nChecking specific keys:')
for k in check_keys:
    exists = k in data.get('strings', {})
    print(f'  {k}: {"EXISTS" if exists else "MISSING"}')
