#!/usr/bin/env python3
"""Final fix for all invalid i18n keys"""
import json
import os
from pathlib import Path

# Load xcstrings
with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)
valid_keys = set(data.get('strings', {}).keys())

# Correct mapping based on actual moko-resources keys
FIX_MAP = {
    # Browse
    'browse_empty': 'empty_screen',
    'browse_empty_sources': 'empty_screen',
    'browse_local_hint': 'empty_screen',
    'browse_no_results': 'empty_screen',
    'browse_source_not_found': 'local_source',
    'Error': 'action_show_errors',
    'source_not_found': 'local_source',

    # Downloads
    'downloads_empty_description': 'label_download_queue',

    # History
    'history_empty_description': 'information_empty_library',

    # Library
    'library_empty': 'information_empty_library',
    'library_empty_description': 'information_empty_library',
    'no_results': 'no_results_found',
    'Try a different search.': 'no_results_found',

    # Manga
    'label_in_library': 'in_library',
    'not_in_library': 'in_library',
    'manga_description': 'action_show_manga',
    'page': 'page_list_empty_error',
    'manga_no_chapters': 'action_show_manga',
    'manga_not_found': 'action_show_manga',

    # More
    'incognito_mode': 'pref_incognito_mode',
    'pref_theme_mode': 'pref_viewer_type',
    'Version': 'version',
    'Platform': 'version',
    'about_description': 'about_dont_kill_my_app',
    'Disclaimer': 'about_dont_kill_my_app',
    'about_disclaimer': 'about_dont_kill_my_app',

    # Backup
    'backup_create': 'backup_choice',
    'backup_restore': 'backup_restore_content_full',

    # Settings
    'crop_borders': 'pref_crop_borders',
    'skip_read': 'pref_skip_read_chapters',
    'download_only_wifi': 'pref_download_new',
    'download_new': 'pref_download_new',
    'show_nsfw_source': 'pref_show_nsfw_source',
    'browse_hide_in_library_items': 'pref_browse_summary',

    # Tracking
    'action_login': 'add_tracking',
    'logged_out': 'add_tracking',

    # Stats
    'error': 'action_show_errors',

    # Upcoming
    'upcoming_empty_description': 'empty_screen',

    # Updates
    'updates_empty_description': 'empty_screen',

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
    'extensions_empty': 'extensionStoresScreen.emptyLabel',
    'extensions_description': 'label_extensions',
    'extension_stores': 'extensionStores',
    'extension_store_name': 'extensionStores',
    'extension_index_url': 'extensionStores',
    'extension_add_store': 'extensionStores',
    'extension_refresh': 'action_retry',
    'extension_available': 'label_extensions',
    'demo_extension_installed': 'action_install',

    # Crash
    'crash_log': 'action_show_errors',
    'crash_share_log': 'action_share',
    'crash_clear_log': 'action_delete',
    'crash_no_log': 'action_show_errors',
    'crash_no_log_description': 'action_show_errors',

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
    'app_version': 'version',
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
