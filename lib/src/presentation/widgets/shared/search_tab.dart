import 'package:flutter/material.dart';
import '../../../data/paginated_list_state.dart';
import '../../../data/paginated_notifier.dart';
import '../../utils/error_messages.dart';
import 'error_retry_widget.dart';

class SearchTab<T> extends StatelessWidget {
  final PaginatedListState<T> state;
  final PaginatedNotifier<T> notifier;
  final ScrollController scrollController;
  final Widget Function(T item, int index) itemBuilder;
  final List<T> Function(List<T> items)? filter;
  final String emptyMessage;

  const SearchTab({
    super.key,
    required this.state,
    required this.notifier,
    required this.scrollController,
    required this.itemBuilder,
    this.filter,
    this.emptyMessage = 'No results found.',
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: userFriendlyErrorMessage(state.error!),
        onRetry: () => notifier.refresh(),
      );
    }

    final items = filter != null ? filter!(state.items) : state.items;

    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return itemBuilder(items[index], index);
        },
      ),
    );
  }
}
