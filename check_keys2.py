#!/usr/bin/env python3
import json

with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

keys = list(data.get('strings', {}).keys())

# Find keys containing specific patterns
patterns = ['onboard', 'done', 'welcome', 'get_started', 'label_more', 'label_stats',
            'action_done', 'action_read', 'action_filter_unread', 'action_resume',
            'manga_description', 'manga_no_chapters', 'manga_not_found',
            'page', 'scanlator', 'crash', 'support', 'incognito',
            'delete_library', 'updates_empty', 'upcoming_empty', 'browse_empty',
            'global_search', 'extension', 'tracker', 'db_status', 'app_version',
            'cache_cleared', 'demo_extension', 'backup', 'security']

for pattern in patterns:
    matching = [k for k in keys if pattern.lower() in k.lower()]
    if matching:
        print(f'\nPattern "{pattern}":')
        for k in matching[:5]:
            print(f'  {k}')
