#!/usr/bin/env python3
"""Fix ALL Swift files to use correct moko-resources keys"""
import json
import re
import os
from pathlib import Path

# Load xcstrings keys
with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    xcstrings = json.load(f)
valid_keys = set(xcstrings.get('strings', {}).keys())

# Also load Vietnamese values for reference
vi_values = {}
for key, val in xcstrings.get('strings', {}).items():
    vi_loc = val.get('localizations', {}).get('vi', {})
    vi_str = vi_loc.get('stringUnit', {}).get('value', '')
    if vi_str:
        vi_values[key] = vi_str

# Mapping: wrong key -> correct key (from moko-resources)
KEY_MAP = {
    # Onboarding - already fixed but ensure consistency
    'onboarding_welcome': 'onboarding_heading',
    'onboarding_welcome_description': 'onboarding_description',
    'onboarding_theme_hint': 'onboarding_description',
    'onboarding_local_library': 'onboarding_storage_info',
    'onboarding_local_library_description': 'onboarding_storage_help_info',

    # Actions
    'action_done': 'action_apply',
    'action_read': 'action_mark_as_read',
    'action_close': 'action_cancel',
    'action_refresh': 'action_retry',

    # Library
    'label_in_library': 'label_in_library',
    'not_in_library': 'not_in_library',
    'Empty library': 'library_empty',
    'No results': 'no_results',
    'library_empty_description': 'library_empty_description',
    'label_sources': 'label_sources',

    # Reader
    'reader_no_pages': 'page_list_empty_error',
    'continuous_vertical_viewer': 'webtoon_viewer',

    # Browse
    'browse_empty_sources': 'browse_empty',
    'browse_empty': 'browse_empty',
    'browse_local_hint': 'browse_empty',
    'browse_no_results': 'browse_empty',
    'browse_source_not_found': 'source_not_found',

    # Stats
    'stats_titles': 'label_stats',
    'stats_completed': 'label_stats',
    'stats_tracked': 'label_stats',
    'stats_total': 'chapters',
    'stats_reading_time': 'label_stats',
    'stats_hours': 'label_stats',

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

    # Upcoming
    'upcoming_empty_description': 'label_upcoming',

    # Updates
    'updates_empty_description': 'label_recent_updates',

    # Delete
    'delete_from_library_title': 'action_delete',
    'delete_from_library_message': 'action_delete',
    'delete_library_entry': 'action_delete',
    'delete_downloaded': 'delete_downloaded',

    # Tracker
    'tracking_description': 'label_tracker_section',
    'logged_in': 'action_login',
    'not_logged_in': 'action_login',
    'tracker_login': 'action_login',
    'tracker_unknown': 'label_tracker_section',
    'tracker_server_url': 'label_tracker_section',
    'tracker_username': 'label_tracker_section',
    'tracker_api_key': 'label_tracker_section',
    'tracker_password': 'label_tracker_section',

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

    # Security
    'label_security': 'pref_category_security',
    'lock_with_biometrics': 'pref_security',
    'lock_unlock': 'pref_security',
    'lock_enabled': 'pref_security',
    'biometrics_unavailable': 'pref_security',

    # Advanced
    'db_status': 'pref_category_advanced',
    'app_version': 'pref_category_advanced',
    'cache_cleared': 'pref_category_advanced',
    'clear_cache': 'pref_category_advanced',
    'install_demo_extension': 'action_install',

    # Migration
    'migration_no_candidates': 'label_migration',
    'migration_complete': 'label_migration',

    # Manga
    'manga_description': 'manga_description',
    'manga_no_chapters': 'manga_description',
    'manga_not_found': 'manga_description',

    # Backup
    'backup_created_format': 'backup_created',
    'backup_restore_complete': 'backup_restore_content_full',
    'backup_downloads_path': 'label_data_storage',
    'backup_local_source_path': 'label_data_storage',
    'backup_extensions_path': 'label_data_storage',

    # Misc
    'Database not ready': 'error',
    'Incognito mode': 'pref_incognito_mode',
    'Global search': 'action_global_search',
    'global_search_hint': 'action_global_search_hint',
    'global_search_results': 'action_global_search',
    'label_security': 'pref_category_security',
}

# All Swift files in Features
features_dir = Path('E:/Code/mihon-main/ios/Features')
app_dir = Path('E:/Code/mihon-main/ios/App')

fixed_count = 0
total_replacements = 0

for directory in [features_dir, app_dir]:
    for swift_file in directory.rglob('*.swift'):
        with open(swift_file, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Fix String(localized: "key") patterns
        for old_key, new_key in KEY_MAP.items():
            if old_key in valid_keys:
                continue  # Old key is already valid
            # Replace in String(localized: "old_key")
            content = content.replace(
                f'String(localized: "{old_key}")',
                f'String(localized: "{new_key}")'
            )
            # Replace in Text("old_key") - only if it looks like a localized string
            if old_key.startswith(('action_', 'label_', 'pref_', 'onboarding_', 'manga_', 'backup_', 'crash_', 'support_', 'browse_', 'updates_', 'delete_', 'tracker_', 'extension_', 'lock_', 'migration_', 'stats_', 'tracking_', 'global_', 'scanlator', 'page', 'loading', 'all', 'categories', 'history', 'chapters', 'name', 'scanlator')):
                content = content.replace(
                    f'Text("{old_key}")',
                    f'Text(String(localized: "{new_key}"))'
                )

        if content != original:
            with open(swift_file, 'w', encoding='utf-8') as f:
                f.write(content)
            fixed_count += 1
            # Count replacements
            for old_key, new_key in KEY_MAP.items():
                if old_key not in valid_keys:
                    total_replacements += content.count(f'String(localized: "{new_key}")')

            print(f'Fixed: {swift_file.name}')

print(f'\nTotal files fixed: {fixed_count}')
