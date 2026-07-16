#!/usr/bin/env python3
"""Fix ALL invalid i18n keys in Swift files"""
import re
import json
import os
from pathlib import Path

# Load xcstrings
with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)
valid_keys = set(data.get('strings', {}).keys())

# Build a lookup: search for keys that contain common words
key_lookup = {}
for k in valid_keys:
    key_lookup[k] = k

# Mapping of invalid keys -> valid keys
FIX_MAP = {
    # Browse
    'browse_empty': 'browse_empty',
    'browse_empty_sources': 'browse_empty',
    'browse_local_hint': 'browse_empty',
    'browse_no_results': 'browse_empty',
    'browse_source_not_found': 'source_not_found',
    'Error': 'error',
    'source_not_found': 'source_not_found',

    # Downloads
    'downloads_empty_description': 'label_download_queue',

    # History
    'history_empty_description': 'label_recent_manga',

    # Library
    'library_empty': 'library_empty',
    'library_empty_description': 'library_empty_description',
    'no_results': 'no_results',
    'Try a different search.': 'no_results',

    # Manga
    'label_in_library': 'label_in_library',
    'not_in_library': 'not_in_library',
    'manga_description': 'manga_description',
    'page': 'page',
    'manga_no_chapters': 'manga_description',
    'manga_not_found': 'manga_description',

    # More
    'incognito_mode': 'pref_incognito_mode',
    'pref_theme_mode': 'pref_viewer_type',
    'Version': 'app_version',
    'Platform': 'app_version',
    'about_description': 'about_description',
    'Disclaimer': 'about_disclaimer',
    'about_disclaimer': 'about_disclaimer',

    # Backup
    'backup_create': 'backup_choice',
    'backup_restore': 'backup_restore_content_full',

    # Settings
    'crop_borders': 'pref_custom_color_filter',
    'skip_read': 'pref_reader_navigation',
    'download_only_wifi': 'pref_download_over_wifi',
    'download_new': 'pref_download_new',
    'show_nsfw_source': 'show_nsfw_source',
    'browse_hide_in_library_items': 'browse_hide_in_library_items',

    # Tracking
    'action_login': 'action_login',
    'logged_out': 'action_login',

    # Stats
    'error': 'error',

    # Upcoming
    'upcoming_empty_description': 'label_upcoming',

    # Updates
    'updates_empty_description': 'label_recent_updates',

    # Reader
    'reader_no_pages': 'page_list_empty_error',
    'continuous_vertical_viewer': 'webtoon_viewer',

    # Security
    'label_security': 'pref_category_security',
    'lock_with_biometrics': 'pref_security',
    'lock_unlock': 'pref_security',
    'lock_enabled': 'pref_security',
    'biometrics_unavailable': 'pref_security',

    # Extension
    'extensions_empty': 'label_extensions',
    'extensions_description': 'label_extensions',
    'extension_stores': 'extensionStores',
    'extension_store_name': 'extensionStores',
    'extension_index_url': 'extensionStores',
    'extension_add_store': 'extensionStores',
    'extension_refresh': 'action_retry',
    'extension_available': 'label_extensions',
    'demo_extension_installed': 'action_install',

    # Crash
    'crash_log': 'crash_screen_title',
    'crash_share_log': 'action_share',
    'crash_clear_log': 'action_delete',
    'crash_no_log': 'crash_screen_title',
    'crash_no_log_description': 'crash_screen_description',

    # Support
    'support_us_title': 'label_support_us',
    'support_us_description': 'label_support_us',
    'support_us_links': 'label_support_us',
    'support_us_thanks': 'label_support_us',
    'support_website': 'label_support_us',

    # Migration
    'migration_no_candidates': 'label_migration',
    'migration_complete': 'label_migration',

    # Delete
    'delete_from_library_title': 'action_delete',
    'delete_from_library_message': 'action_delete',
    'delete_library_entry': 'action_delete',
    'delete_downloaded': 'delete_downloaded',

    # Advanced
    'db_status': 'pref_category_advanced',
    'app_version': 'app_version',
    'cache_cleared': 'pref_category_advanced',
    'clear_cache': 'pref_category_advanced',
    'install_demo_extension': 'action_install',

    # Actions
    'action_done': 'action_apply',
    'action_read': 'action_mark_as_read',
    'action_close': 'action_cancel',
    'action_refresh': 'action_retry',
}

# All Swift files
features_dir = Path('E:/Code/mihon-main/ios/Features')
app_dir = Path('E:/Code/mihon-main/ios/App')

fixed_count = 0
for directory in [features_dir, app_dir]:
    for swift_file in directory.rglob('*.swift'):
        with open(swift_file, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Fix String(localized: "key") patterns
        for old_key, new_key in FIX_MAP.items():
            if old_key in valid_keys:
                continue
            content = content.replace(
                f'String(localized: "{old_key}")',
                f'String(localized: "{new_key}")'
            )

        if content != original:
            with open(swift_file, 'w', encoding='utf-8') as f:
                f.write(content)
            fixed_count += 1
            print(f'Fixed: {swift_file.name}')

print(f'\nTotal files fixed: {fixed_count}')
