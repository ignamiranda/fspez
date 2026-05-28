import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../domain/enums/comment_sort.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'General',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Show awards'),
                  subtitle: const Text('Display awards on posts.'),
                  value: settings.showAwards,
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).setShowAwards(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Comments',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
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
                      ref
                          .read(appSettingsProvider.notifier)
                          .setDefaultCommentSort(sort);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
