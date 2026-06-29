import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class PostActionsState {
  final Map<String, VoteDirection> votes;
  final Map<String, bool> saves;
  final Map<String, bool> hides;
  final Map<String, bool> blocks;

  const PostActionsState({
    this.votes = const {},
    this.saves = const {},
    this.hides = const {},
    this.blocks = const {},
  });

  PostActionsState copyWith({
    Map<String, VoteDirection>? votes,
    Map<String, bool>? saves,
    Map<String, bool>? hides,
    Map<String, bool>? blocks,
  }) {
    return PostActionsState(
      votes: votes ?? this.votes,
      saves: saves ?? this.saves,
      hides: hides ?? this.hides,
      blocks: blocks ?? this.blocks,
    );
  }
}

class PostActionsNotifier extends StateNotifier<PostActionsState> {
  final RedditClient _client;
  final SessionCookie? _sessionCookie;
  final Map<String, String> _accountIdCache = {};

  PostActionsNotifier(this._client, this._sessionCookie)
      : super(const PostActionsState());

  // ===== Vote methods =====
  Future<void> vote(String fullname, VoteDirection direction) async {
    state = state.copyWith(
      votes: {...state.votes, fullname: direction},
    );
    try {
      await _client.postForm('/api/vote',
          fields: {'id': fullname, 'dir': direction.value.toString()},
          sessionCookie: _sessionCookie);
    } catch (e) {
      debugPrint('PostActionsNotifier.vote failed: $e');
      // Keep optimistic per existing VoteNotifier behavior
    }
  }

  void toggleVote(String fullname, VoteDirection tappedDirection) {
    final current = state.votes[fullname] ?? VoteDirection.none;
    final next =
        current == tappedDirection ? VoteDirection.none : tappedDirection;
    vote(fullname, next);
  }

  VoteDirection effectiveVote(String fullname, VoteDirection original) {
    return state.votes[fullname] ?? original;
  }

  // ===== Save methods =====
  Future<void> toggleSave(String fullname) async {
    final current = state.saves[fullname] ?? false;
    final next = !current;
    final sc = _sessionCookie;
    if (sc == null) {
      throw const SaveException(statusCode: 0, body: 'No session');
    }
    state = state.copyWith(saves: {...state.saves, fullname: next});
    try {
      if (next) {
        await _client.save(fullname, sc);
      } else {
        await _client.unsave(fullname, sc);
      }
    } on RedditApiException catch (e) {
      state = state.copyWith(saves: {...state.saves, fullname: current});
      throw SaveException(statusCode: e.statusCode, body: e.message);
    }
  }

  bool effectiveSaved(String fullname, bool original) {
    return state.saves[fullname] ?? original;
  }

  // ===== Hide methods =====
  Future<void> hide(String fullname) async {
    final previous = state.hides[fullname];
    if (previous == true) return;
    state = state.copyWith(hides: {...state.hides, fullname: true});
    try {
      final sc = _sessionCookie;
      if (sc != null) {
        await _client.hide(fullname, sc);
      }
    } catch (_) {
      if (previous == null) {
        final copy = Map<String, bool>.from(state.hides)..remove(fullname);
        state = state.copyWith(hides: copy);
      } else {
        state = state.copyWith(hides: {...state.hides, fullname: previous});
      }
    }
  }

  void dismiss(String fullname) {
    final copy = Map<String, bool>.from(state.hides)..remove(fullname);
    state = state.copyWith(hides: copy);
  }

  Future<void> unhide(String fullname) async {
    dismiss(fullname);
    final sc = _sessionCookie;
    if (sc != null) {
      await _client.unhide(fullname, sc);
    }
  }

  // ===== Delete methods =====
  Future<void> delete(String fullname) async {
    final sc = _sessionCookie;
    if (sc == null) return;
    await _client.deleteContent(fullname, sc);
  }

  // ===== Edit methods =====
  final EditState _editState = EditState();

  EditState get editState => _editState;

  String? get editError => _editState.error;

  Future<bool> edit(String thingId, String text) async {
    final sc = _sessionCookie;
    if (sc == null) return false;
    _editState._isSaving = true;
    _editState._error = null;
    _editState._success = false;
    try {
      await _client.editContent(
          thingId: thingId, text: text, sessionCookie: sc);
      _editState._isSaving = false;
      _editState._success = true;
      return true;
    } catch (e) {
      _editState._isSaving = false;
      _editState._error = e.toString();
      return false;
    }
  }

  void resetEdit() {
    _editState._isSaving = false;
    _editState._error = null;
    _editState._success = false;
  }

  // ===== Block methods =====
  Future<String> _resolveAccountId(String username) async {
    final cached = _accountIdCache[username];
    if (cached != null) return cached;
    final sc = _sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _client.fetchAccountId(
      username,
      sessionCookie: sc,
    );
    _accountIdCache[username] = accountId;
    return accountId;
  }

  Future<void> blockUser(String username) async {
    final previous = state.blocks[username];
    if (previous == true) return;
    final sc = _sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _resolveAccountId(username);
    state = state.copyWith(blocks: {...state.blocks, username: true});
    try {
      await _client.blockUser(accountId, sc);
    } catch (_) {
      if (previous == null) {
        final copy = Map<String, bool>.from(state.blocks)..remove(username);
        state = state.copyWith(blocks: copy);
      } else {
        state = state.copyWith(blocks: {...state.blocks, username: previous});
      }
      rethrow;
    }
  }

  Future<void> unblockUser(String username) async {
    final previous = state.blocks[username];
    if (previous == false) return;
    final sc = _sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _resolveAccountId(username);
    state = state.copyWith(blocks: {...state.blocks, username: false});
    try {
      await _client.unblockUser(accountId, sc);
    } catch (_) {
      if (previous == null) {
        final copy = Map<String, bool>.from(state.blocks)..remove(username);
        state = state.copyWith(blocks: copy);
      } else {
        state = state.copyWith(blocks: {...state.blocks, username: previous});
      }
      rethrow;
    }
  }

  bool isBlocked(String username) => state.blocks[username] ?? false;

  Future<void> blockKnown(String username, String accountId) async {
    final previous = state.blocks[username];
    if (previous == true) return;
    final sc = _sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    state = state.copyWith(blocks: {...state.blocks, username: true});
    try {
      await _client.blockUser(accountId, sc);
    } catch (_) {
      if (previous == null) {
        final copy = Map<String, bool>.from(state.blocks)..remove(username);
        state = state.copyWith(blocks: copy);
      } else {
        state = state.copyWith(blocks: {...state.blocks, username: previous});
      }
      rethrow;
    }
  }

  Future<void> unblockKnown(String username, String accountId) async {
    final previous = state.blocks[username];
    if (previous == false) return;
    final sc = _sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    state = state.copyWith(blocks: {...state.blocks, username: false});
    try {
      await _client.unblockUser(accountId, sc);
    } catch (_) {
      if (previous == null) {
        final copy = Map<String, bool>.from(state.blocks)..remove(username);
        state = state.copyWith(blocks: copy);
      } else {
        state = state.copyWith(blocks: {...state.blocks, username: previous});
      }
      rethrow;
    }
  }
}

// EditState — mutable holder since it's non-optimistic and local
class EditState {
  bool _isSaving = false;
  String? _error;
  bool _success = false;

  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get success => _success;
}

// SaveException — moved from save_notifier.dart
class SaveException implements Exception {
  final int statusCode;
  final String body;
  const SaveException({required this.statusCode, required this.body});
  @override
  String toString() =>
      'SaveException($statusCode): ${body.length > 200 ? body.substring(0, 200) : body}';
}
