import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/post.dart';
import 'bottom_sheet_menu.dart';
import 'report_sheet.dart';

class PostOverflowMenu extends StatelessWidget {
  final Post post;
  final ColorScheme cs;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onBlock;

  const PostOverflowMenu({
    super.key,
    required this.post,
    required this.cs,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final primaryActions = <BottomSheetAction>[];
    final authorActions = <BottomSheetAction>[];

    // Copy actions
    primaryActions.add(
      BottomSheetAction(
        icon: Icons.link,
        label: 'Copy Reddit link',
        onTap: () {
          final link = 'https://www.reddit.com${post.permalink}';
          Clipboard.setData(ClipboardData(text: link));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    );

    if (post.url != null &&
        !post.url!.startsWith('https://www.reddit.com') &&
        post.type != PostType.self_) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.open_in_new,
          label: 'Copy external link',
          onTap: () {
            Clipboard.setData(ClipboardData(text: post.url!));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Copied')));
          },
        ),
      );
    }

    final textToCopy = post.selftext != null && post.selftext!.isNotEmpty
        ? '${post.title}\n\n${post.selftext}'
        : post.title;
    primaryActions.add(
      BottomSheetAction(
        icon: Icons.content_copy,
        label: 'Copy text',
        onTap: () {
          Clipboard.setData(ClipboardData(text: textToCopy));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    );
    primaryActions.add(
      BottomSheetAction(
        icon: Icons.flag_outlined,
        label: 'Report',
        onTap: () => showReportSheet(
          context,
          thingId: post.fullname,
          subreddit: post.subreddit.name,
        ),
      ),
    );

    if (onHide != null) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.visibility_off_outlined,
          label: 'Hide',
          onTap: () => onHide!(),
        ),
      );
    }
    if (onUnhide != null) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.visibility_outlined,
          label: 'Unhide',
          onTap: () => onUnhide!(),
        ),
      );
    }
    if (onEdit != null) {
      authorActions.add(
        BottomSheetAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () => onEdit!(),
        ),
      );
    }
    if (onDelete != null) {
      authorActions.add(
        BottomSheetAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: () => onDelete!(),
          isDestructive: true,
        ),
      );
    }

    if (onBlock != null) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.block,
          label: 'Block u/${post.author}',
          onTap: () => onBlock!(),
        ),
      );
    }

    if (primaryActions.isEmpty && authorActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => showPostActionSheet(
        context,
        primaryActions: primaryActions,
        authorActions: authorActions,
      ),
      borderRadius: BorderRadius.circular(4),
      child: Semantics(
        button: true,
        label: 'More actions',
        child: Tooltip(
          message: 'More actions',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: Icon(
                Icons.more_horiz,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
