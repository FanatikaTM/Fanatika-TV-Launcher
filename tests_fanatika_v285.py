"""Source smoke checks for v2.8.5. Not a replacement for Flutter compilation."""
from pathlib import Path
import unittest

ROOT = Path(__file__).parent

def source(name):
    return (ROOT / name).read_text(encoding='utf-8')

class PlexV285Tests(unittest.TestCase):
    def test_current_version(self):
        self.assertIn('version: 2.8.7+4140', source('pubspec.yaml'))

    def test_plex_hub_and_auth_in_header(self):
        code = source('lib/providers/plex_continue_watching_client.dart')
        self.assertIn('/hubs/continueWatching/items', code)
        self.assertIn("'X-Plex-Token': token", code)
        self.assertIn('request.followRedirects = false', code)
        self.assertIn('_isLocalHost', code)

    def test_plex_can_render_without_android_provider_permission(self):
        code = source('lib/providers/watch_next_service.dart')
        self.assertIn('bool get canShowItems => _hasPermission || plexConfigured', code)
        self.assertIn('plexItems', code)
        self.assertIn('getWatchNextItems()', code)

    def test_on_tv_setup_available(self):
        self.assertIn('Plex Continue Watching', source('lib/widgets/settings/unified_settings_pages.dart'))
        self.assertIn('PlexContinueWatchingPage.routeName', source('lib/widgets/settings/settings_panel.dart'))

    def test_original_favorites_not_modified(self):
        self.assertIn("c.name == 'Favorites'", source('lib/flauncher.dart'))
        self.assertIn('Arc Favorites', source('README_PLEX_WATCH_NEXT_V285.md'))

    def test_export_excludes_token(self):
        code = source('lib/providers/settings_service.dart')
        self.assertIn("'fanatika_plex_token'", code)
        self.assertIn("'token'", code)
        self.assertIn('fanatikaExportPreferences', code)

if __name__ == '__main__': unittest.main()
