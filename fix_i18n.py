#!/usr/bin/env python3
"""Fix i18n keys in Swift files to match moko-resources keys"""
import json
import re
import os

# Load xcstrings keys
with open('E:/Code/mihon-main/ios/Resources/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)
valid_keys = set(data.get('strings', {}).keys())

# Mapping from our custom keys to moko-resources keys
KEY_MAP = {
    # Onboarding
    'onboarding_welcome': 'onboarding_description',
    'onboarding_welcome_description': 'onboarding_description',
    'onboarding_next': 'onboarding_action_next',
    'onboarding_get_started': 'onboarding_action_finish',
    'onboarding_theme_hint': 'onboarding_description',
    'onboarding_local_library': 'onboarding_description',
    'onboarding_local_library_description': 'onboarding_description',

    # Actions
    'action_done': 'action_apply',
    'action_read': 'action_mark_as_read',
    'action_close': 'action_cancel',

    # Library
    'label_in_library': 'label_in_library',
    'not_in_library': 'not_in_library',
    'Empty library': 'library_empty',
    'No results': 'no_results',

    # Reader
    'reader_no_pages': 'page_list_empty_error',
    'page': 'page',

    # Browse
    'browse_empty_sources': 'browse_empty',
    'browse_empty': 'browse_empty',
    'browse_local_hint': 'browse_empty',
    'browse_no_results': 'browse_empty',
    'browse_source_not_found': 'source_not_found',

    # Categories
    'categories': 'categories',

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
    'extension_refresh': 'action_refresh',
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
}

# Files to fix
files_to_fix = [
    'E:/Code/mihon-main/ios/Features/Onboarding/OnboardingView.swift',
    'E:/Code/mihon-main/ios/Features/Library/LibraryScreen.swift',
    'E:/Code/mihon-main/ios/Features/Reader/ReaderScreen.swift',
    'E:/Code/mihon-main/ios/Features/More/MoreScreen.swift',
    'E:/Code/mihon-main/ios/Features/Manga/MangaDetailScreen.swift',
    'E:/Code/mihon-main/ios/Features/Browse/BrowseScreen.swift',
    'E:/Code/mihon-main/ios/Features/Browse/ExtensionsScreen.swift',
    'E:/Code/mihon-main/ios/Features/History/HistoryScreen.swift',
    'E:/Code\mihon-main/ios/Features/Updates/UpdatesScreen.swift',
    'E:/Code/mihon-main/ios/Features/Downloads/DownloadsScreen.swift',
    'E:/Code/mihon-main/ios/Features/Stats/StatsScreen.swift',
    'E:/Code/mihon-main/ios/Features/Settings/SettingsScreens.swift',
    'E:/Code/mihon-main/ios/Features/Settings/TrackingSettingsScreen.swift',
    'E:/Code/mihon-main/ios/Features/Settings/DataBackupScreen.swift',
    'E:/Code/mihon-main/ios/Features/Security/AppLockView.swift',
    'E:/Code/mihon-main/ios/Features/Crash/CrashScreen.swift',
    'E:/Code/mihon-main/ios/Features/Support/SupportScreen.swift',
    'E:/Code/mihon-main/ios/Features/Upcoming/UpcomingScreen.swift',
    'E:/Code/mihon-main/ios/Features/Updates/UpdatesFilterDialog.swift',
    'E:/Code/mihon-main/ios/Features/Library/DeleteLibraryDialog.swift',
    'E:/Code/mihon-main/ios/Features/Migration/MigrateScreen.swift',
    'E:/Code/mihon-main/ios/Features/Category/CategoriesScreen.swift',
    'E:/Code/mihon-main/ios/Features/More/MoreScreen.swift',
]

fixed_count = 0
for filepath in files_to_fix:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace String(localized: "key") with String(localized: "mapped_key")
    for old_key, new_key in KEY_MAP.items():
        if old_key in valid_keys:
            continue  # Skip if old key is already valid
        # Pattern: String(localized: "old_key")
        content = content.replace(f'String(localized: "{old_key}")', f'String(localized: "{new_key}")')
        # Pattern: Text("old_key")
        content = content.replace(f'Text("{old_key}")', f'Text(String(localized: "{new_key}"))')

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        fixed_count += 1
        print(f'Fixed: {os.path.basename(filepath)}')

print(f'\nTotal files fixed: {fixed_count}')
