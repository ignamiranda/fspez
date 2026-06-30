import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_settings.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/enums/comment_sort.dart';
import '../../domain/enums/feed_density.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(label: 'Appearance'),
          _SettingsCard(children: [
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(settings.themeMode.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, settings, notifier),
            ),
          ]),
          const _SectionHeader(label: 'Content'),
          _SettingsCard(children: [
            SwitchListTile(
              title: const Text('Blur NSFW content'),
              subtitle: const Text('Blur media on posts marked NSFW.'),
              value: settings.nsfwBlur,
              onChanged: (v) => notifier.setNsfwBlur(v),
            ),
            SwitchListTile(
              title: const Text('Blur spoiler content'),
              subtitle: const Text('Blur media on posts marked as spoiler.'),
              value: settings.spoilerBlur,
              onChanged: (v) => notifier.setSpoilerBlur(v),
            ),
            SwitchListTile(
              title: const Text('Show awards'),
              subtitle: const Text('Display awards on posts.'),
              value: settings.showAwards,
              onChanged: (v) => notifier.setShowAwards(v),
            ),
          ]),
          const _SectionHeader(label: 'Feed'),
          _SettingsCard(children: [
            ListTile(
              title: const Text('Feed density'),
              subtitle: Text(settings.feedDensity.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFeedDensityPicker(context, settings, notifier),
            ),
            SwitchListTile(
              title: const Text('Prefetch feed images'),
              subtitle: const Text(
                'Preload images for upcoming posts for smoother browsing.',
              ),
              value: settings.prefetchMedia,
              onChanged: (v) => notifier.setPrefetchMedia(v),
            ),
          ]),
          const _SectionHeader(label: 'Comments'),
          _SettingsCard(children: [
            ListTile(
              title: const Text('Default comment sort'),
              subtitle: const Text('Used when opening a post.'),
              trailing: DropdownButton<CommentSort?>(
                value: settings.defaultCommentSort,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<CommentSort?>(
                    value: null,
                    child: Text('Reddit default'),
                  ),
                  ...CommentSort.values.map((sort) {
                    return DropdownMenuItem<CommentSort?>(
                      value: sort,
                      child: Text(sort.label),
                    );
                  }),
                ],
                onChanged: (sort) {
                  notifier.setDefaultCommentSort(sort);
                },
              ),
            ),
          ]),
          const _SectionHeader(label: 'About'),
          _SettingsCard(children: [
            ListTile(
              title: const Text('Report Issue'),
              subtitle: const Text('Open a GitHub issue to report a bug or request a feature.'),
              leading: const Icon(Icons.bug_report_outlined),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse('https://github.com/ignamiranda/fspez/issues/new'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    AppSettings settings,
    AppSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Choose theme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              RadioGroup<AppThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    notifier.setThemeMode(value);
                    Navigator.of(ctx).pop();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppThemeMode.values
                      .map((mode) => RadioListTile<AppThemeMode>(
                            title: Text(mode.label),
                            value: mode,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedDensityPicker(
    BuildContext context,
    AppSettings settings,
    AppSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Feed density',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              RadioGroup<FeedDensity>(
                groupValue: settings.feedDensity,
                onChanged: (value) {
                  if (value != null) {
                    notifier.setFeedDensity(value);
                    Navigator.of(ctx).pop();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: FeedDensity.values
                      .map((density) => RadioListTile<FeedDensity>(
                            title: Text(density.label),
                            value: density,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(children: children),
      ),
    );
  }
}
