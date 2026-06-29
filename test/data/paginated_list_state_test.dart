import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/paginated_list_state.dart';

void main() {
  group('PaginatedListState', () {
    test('default constructor creates empty idle state', () {
      const state = PaginatedListState<String>();

      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.hasMore, isFalse);
      expect(state.isStale, isFalse);
    });

    test('initial() returns loading state', () {
      const state = PaginatedListState<String>.initial();

      expect(state.items, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.hasMore, isFalse);
      expect(state.isStale, isFalse);
    });

    test('custom constructor sets all fields', () {
      const state = PaginatedListState<String>(
        items: ['a', 'b'],
        isLoading: false,
        isLoadingMore: true,
        error: 'something went wrong',
        hasMore: true,
        isStale: true,
      );

      expect(state.items, ['a', 'b']);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isTrue);
      expect(state.error, 'something went wrong');
      expect(state.hasMore, isTrue);
      expect(state.isStale, isTrue);
    });

    group('copyWith', () {
      test('replaces items', () {
        const state = PaginatedListState<int>(items: [1, 2]);
        final copy = state.copyWith(items: [3, 4]);
        expect(copy.items, [3, 4]);
      });

      test('replaces isLoading', () {
        const state = PaginatedListState<int>(isLoading: false);
        final copy = state.copyWith(isLoading: true);
        expect(copy.isLoading, isTrue);
      });

      test('replaces isLoadingMore', () {
        const state = PaginatedListState<int>(isLoadingMore: false);
        final copy = state.copyWith(isLoadingMore: true);
        expect(copy.isLoadingMore, isTrue);
      });

      test('replaces error', () {
        const state = PaginatedListState<int>();
        final copy = state.copyWith(error: 'err');
        expect(copy.error, 'err');
      });

      test('replaces hasMore', () {
        const state = PaginatedListState<int>(hasMore: false);
        final copy = state.copyWith(hasMore: true);
        expect(copy.hasMore, isTrue);
      });

      test('replaces isStale', () {
        const state = PaginatedListState<int>(isStale: false);
        final copy = state.copyWith(isStale: true);
        expect(copy.isStale, isTrue);
      });

      test('clearError forces error to null', () {
        const state = PaginatedListState<int>(error: 'old');
        final copy = state.copyWith(clearError: true);
        expect(copy.error, isNull);
      });

      test('clearError overwrites even when error is passed', () {
        const state = PaginatedListState<int>(error: 'old');
        final copy = state.copyWith(error: 'new', clearError: true);
        expect(copy.error, isNull);
      });

      test('preserves unset fields', () {
        const state = PaginatedListState<int>(
          items: [1],
          isLoading: true,
          isLoadingMore: true,
          error: 'err',
          hasMore: true,
          isStale: true,
        );
        final copy = state.copyWith(items: [2]);

        expect(copy.items, [2]);
        expect(copy.isLoading, isTrue);
        expect(copy.isLoadingMore, isTrue);
        expect(copy.error, 'err');
        expect(copy.hasMore, isTrue);
        expect(copy.isStale, isTrue);
      });
    });

    group('removeItem', () {
      test('removes matching item', () {
        const state = PaginatedListState<String>(items: ['a', 'b', 'c']);
        final result = state.removeItem((s) => s == 'b');
        expect(result.items, ['a', 'c']);
      });

      test('returns same list when no item matches', () {
        const state = PaginatedListState<String>(items: ['a', 'b']);
        final result = state.removeItem((s) => s == 'z');
        expect(result.items, ['a', 'b']);
      });

      test('preserves other fields', () {
        const state = PaginatedListState<String>(
          items: ['a', 'b'],
          hasMore: true,
          isStale: true,
        );
        final result = state.removeItem((s) => s == 'a');
        expect(result.items, ['b']);
        expect(result.hasMore, isTrue);
        expect(result.isStale, isTrue);
      });
    });

    group('replaceItem', () {
      test('replaces first matching item', () {
        const state = PaginatedListState<String>(items: ['a', 'b', 'a']);
        final result = state.replaceItem((s) => s == 'a', 'x');
        expect(result.items, ['x', 'b', 'a']);
      });

      test('preserves other fields', () {
        const state = PaginatedListState<String>(
          items: ['a'],
          hasMore: true,
          error: 'err',
          isStale: true,
        );
        final result = state.replaceItem((s) => s == 'a', 'b');
        expect(result.items, ['b']);
        expect(result.hasMore, isTrue);
        expect(result.error, 'err');
        expect(result.isStale, isTrue);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const a = PaginatedListState<String>(items: ['a'], hasMore: true);
        const b = PaginatedListState<String>(items: ['a'], hasMore: true);
        expect(a, equals(b));
      });

      test('different isStale are not equal', () {
        const a = PaginatedListState<String>(isStale: true);
        const b = PaginatedListState<String>(isStale: false);
        expect(a, isNot(equals(b)));
      });

      test('different items are not equal', () {
        const a = PaginatedListState<String>(items: ['a']);
        const b = PaginatedListState<String>(items: ['b']);
        expect(a, isNot(equals(b)));
      });

      test('different isLoading are not equal', () {
        const a = PaginatedListState<String>(isLoading: true);
        const b = PaginatedListState<String>(isLoading: false);
        expect(a, isNot(equals(b)));
      });

      test('different hasMore are not equal', () {
        const a = PaginatedListState<String>(hasMore: true);
        const b = PaginatedListState<String>(hasMore: false);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
