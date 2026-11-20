import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/chat_failure.dart';
import '../domain/chat_gif.dart';
import '../domain/chat_message.dart';
import '../domain/chat_poll.dart';
import '../domain/chat_repository.dart';
import '../domain/chat_thread.dart';

/// Reads and writes the thread for one circle.
///
/// Sends are echoed locally so the sender's own message appears before the
/// round-trip lands; the server row replaces the echo when it is fetched.
/// Realtime events are coalesced for 250 ms. Inserts only fetch rows newer
/// than the newest one already shown; edits and deletes rebuild the window.
///
/// Changes arrive over the circle's private broadcast topic, fed by a database
/// trigger, so delivery skips per-subscriber RLS checks.
class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  /// Newest server timestamp in the thread. Incremental fetches start a few
  /// seconds earlier so a transaction that commits late is not skipped.
  DateTime? _cursor;

  /// Messages shown before the server confirms them, keyed by the id we
  /// inserted so the fetched row replaces them.
  final List<ChatMessage> _pending = [];
  final StreamController<void> _wake = StreamController<void>.broadcast();

  /// The last good thread, used to resolve what a tap should toggle.
  List<ChatMessage> _lastThread = const [];

  /// Votes this device has cast but not yet seen in a fetch, keyed by message
  /// id; the value is the chosen option, or null when the vote was cleared.
  final Map<String, String?> _voteOverrides = {};

  static const _cursorOverlap = Duration(seconds: 5);
  static const _refreshDebounce = Duration(milliseconds: 250);

  static const _columns =
      'id, sender_id, kind, body, latitude, longitude, place_label, '
      'created_at, mentioned_user_ids, edited_at, reply_to_id, '
      'poll_options:chat_poll_options(id, position, label, latitude, '
      'longitude, place_label, votes:chat_poll_votes(user_id)), '
      'sender:profiles!chat_messages_sender_id_fkey'
      '(display_name, avatar_color)';

  static const _replyColumns =
      'id, sender_id, kind, body, place_label, '
      'sender:profiles!chat_messages_sender_id_fkey(display_name)';

  @override
  Stream<List<ChatMessage>> watchMessages() {
    final out = StreamController<List<ChatMessage>>();
    Timer? debounce;
    sb.RealtimeChannel? channel;
    StreamSubscription<void>? wake;
    var thread = const <ChatMessage>[];
    var needsFullFetch = true;
    var fetching = false;
    var fetchAgain = false;

    Future<void> refresh() async {
      if (fetching) {
        fetchAgain = true;
        return;
      }
      fetching = true;
      try {
        do {
          fetchAgain = false;
          try {
            thread = needsFullFetch
                ? await _fetch()
                : await _fetchSince(thread);
            needsFullFetch = false;
            _dropConfirmed(thread);
            _lastThread = thread;
            final me = _client.auth.currentUser?.id;
            _settleVotes(thread, me);
            if (!out.isClosed) {
              out.add(
                mergeChatThread(
                  thread: _withVotes(thread, me),
                  optimistic: _pending,
                ),
              );
            }
          } catch (error) {
            // Keep showing the last good thread; the next event retries.
            developer.log(
              'Could not refresh the chat thread',
              name: 'pathfinders.chat',
              error: error,
            );
          }
        } while (fetchAgain);
      } finally {
        fetching = false;
      }
    }

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(_refreshDebounce, () => unawaited(refresh()));
    }

    // Inserts are append-only; edits and deletes touch rows the incremental
    // query would never see. Votes are inserts too, but of poll tables, so
    // only a chat_messages insert may take the incremental path.
    void onChange(Map<String, dynamic> message) {
      final body = message['payload'];
      final table = body is Map ? body['table'] : message['table'];
      final messageInsert =
          message['event'] == 'INSERT' &&
          (table == null || table == 'chat_messages');
      if (!messageInsert) needsFullFetch = true;
      scheduleRefresh();
    }

    out.onListen = () {
      channel =
          _client.channel(
              'chat:$circleId',
              opts: const sb.RealtimeChannelConfig(private: true),
            )
            ..onBroadcast(event: '*', callback: (message) => onChange(message))
            ..subscribe((status, error) {
              if (status != sb.RealtimeSubscribeStatus.channelError &&
                  status != sb.RealtimeSubscribeStatus.timedOut) {
                return;
              }
              developer.log(
                'Could not join the chat broadcast topic',
                name: 'pathfinders.chat',
                error: error,
              );
            });
      wake = _wake.stream.listen((_) => unawaited(refresh()));
      unawaited(refresh());
    };

    out.onCancel = () async {
      debounce?.cancel();
      await wake?.cancel();
      final active = channel;
      channel = null;
      if (active != null) await _client.removeChannel(active);
      await out.close();
    };

    return out.stream;
  }

  @override
  Future<void> sendText({
    required String senderId,
    required String text,
    ChatMessage? replyTo,
    List<String> mentionedUserIds = const [],
    ChatSender? localEcho,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _insert(
      senderId,
      {
        'kind': 'text',
        'body': clean,
        'reply_to_id': ?replyTo?.id,
        if (mentionedUserIds.isNotEmpty) 'mentioned_user_ids': mentionedUserIds,
      },
      echo: localEcho == null
          ? null
          : _echo(
              senderId: senderId,
              sender: localEcho,
              kind: ChatMessageKind.text,
              body: clean,
              replyTo: replyTo,
              mentionedUserIds: mentionedUserIds,
            ),
    );
  }

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {
    final label = placeLabel?.trim();
    await _insert(
      senderId,
      {
        'kind': 'location_share',
        'latitude': latitude,
        'longitude': longitude,
        if (label != null && label.isNotEmpty) 'place_label': label,
        'reply_to_id': ?replyTo?.id,
      },
      echo: localEcho == null
          ? null
          : _echo(
              senderId: senderId,
              sender: localEcho,
              kind: ChatMessageKind.locationShare,
              latitude: latitude,
              longitude: longitude,
              placeLabel: label,
              replyTo: replyTo,
            ),
    );
  }

  @override
  Future<void> sendGif({
    required String senderId,
    required String url,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {
    final clean = url.trim();
    if (!isAllowedGifUrl(clean)) {
      throw const ChatFailure('That GIF link is not supported.');
    }
    await _insert(
      senderId,
      {'kind': 'gif', 'body': clean, 'reply_to_id': ?replyTo?.id},
      echo: localEcho == null
          ? null
          : _echo(
              senderId: senderId,
              sender: localEcho,
              kind: ChatMessageKind.gif,
              body: clean,
              replyTo: replyTo,
            ),
    );
  }

  @override
  Future<void> createPoll({
    required String senderId,
    required String question,
    required List<ChatPollDraftOption> options,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {
    final clean = question.trim();
    if (clean.isEmpty) {
      throw const ChatFailure('Write a question before starting the vote.');
    }
    if (options.length < 2 || options.length > 6) {
      throw const ChatFailure('Give the vote between 2 and 6 options.');
    }
    final labels = [for (final option in options) option.label.trim()];
    if (labels.any((label) => label.isEmpty || label.length > 80)) {
      throw const ChatFailure(
        'Each option needs a label of up to 80 characters.',
      );
    }

    final messageId = _newMessageId();
    final optionIds = [for (final _ in options) _newMessageId()];

    ChatMessage? echo;
    if (localEcho != null) {
      echo = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: localEcho.displayName,
        senderAvatarColor: localEcho.avatarColor,
        kind: ChatMessageKind.poll,
        text: clean,
        poll: ChatPoll(
          options: [
            for (var i = 0; i < options.length; i++)
              ChatPollOption(
                id: optionIds[i],
                position: i,
                label: labels[i],
                latitude: options[i].latitude,
                longitude: options[i].longitude,
                placeLabel: _text(options[i].placeLabel),
              ),
          ],
        ),
        createdAt: DateTime.now(),
        replyTo: replyTo?.toReply(),
      );
      _pending.add(echo);
      _wake.add(null);
    }

    try {
      await _client.rpc(
        'create_chat_poll',
        params: {
          'p_circle_id': circleId,
          'p_question': clean,
          'p_message_id': messageId,
          'p_options': [
            for (var i = 0; i < options.length; i++)
              {
                'id': optionIds[i],
                'label': labels[i],
                'latitude': options[i].latitude,
                'longitude': options[i].longitude,
                'place_label': _text(options[i].placeLabel),
              },
          ],
        },
      );
      if (echo != null) _wake.add(null);
    } on sb.PostgrestException catch (error) {
      _dropEcho(echo);
      throw _mapFailure(
        error,
        fallback:
            'Could not start that vote. Check your connection and try again.',
      );
    } on Exception {
      _dropEcho(echo);
      throw const ChatFailure(
        'Could not start that vote. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> castVote({
    required String messageId,
    required String optionId,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me != null) {
      // The database toggles: tapping the chosen option clears the vote.
      _voteOverrides[messageId] = _voteStateOf(messageId, me) == optionId
          ? null
          : optionId;
      _wake.add(null);
    }

    try {
      await _client.rpc(
        'cast_chat_vote',
        params: {'p_message_id': messageId, 'p_option_id': optionId},
      );
    } on sb.PostgrestException catch (error) {
      _voteOverrides.remove(messageId);
      _wake.add(null);
      throw _mapFailure(
        error,
        fallback:
            'Could not count that vote. Check your connection and try again.',
      );
    } on Exception {
      _voteOverrides.remove(messageId);
      _wake.add(null);
      throw const ChatFailure(
        'Could not count that vote. Check your connection and try again.',
      );
    }
  }

  /// What this member's vote looks like right now: the pending override wins
  /// over the last fetched copy.
  String? _voteStateOf(String messageId, String userId) {
    if (_voteOverrides.containsKey(messageId)) {
      return _voteOverrides[messageId];
    }
    for (final message in _lastThread) {
      if (message.id == messageId) {
        return message.poll?.votedOptionId(userId);
      }
    }
    return null;
  }

  /// Drops overrides the server already reflects.
  void _settleVotes(List<ChatMessage> thread, String? me) {
    if (me == null || _voteOverrides.isEmpty) return;
    _voteOverrides.removeWhere((messageId, vote) {
      for (final message in thread) {
        if (message.id == messageId) {
          return message.poll?.votedOptionId(me) == vote;
        }
      }
      // Not in the fetched window: keep showing the local choice.
      return false;
    });
  }

  List<ChatMessage> _withVotes(List<ChatMessage> thread, String? me) {
    if (me == null || _voteOverrides.isEmpty) return thread;
    return [
      for (final message in thread)
        if (message.poll case final poll?
            when _voteOverrides.containsKey(message.id))
          message.withPoll(
            poll.withVote(userId: me, optionId: _voteOverrides[message.id]),
          )
        else
          message,
    ];
  }

  @override
  Future<void> editText({
    required String messageId,
    required String text,
    List<String> mentionedUserIds = const [],
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      throw const ChatFailure('Write something before saving the edit.');
    }

    final List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('chat_messages')
          .update({'body': clean, 'mentioned_user_ids': mentionedUserIds})
          .eq('id', messageId)
          .select('id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not save that edit. Check your connection and try again.',
      );
    } on Exception {
      throw const ChatFailure(
        'Could not save that edit. Check your connection and try again.',
      );
    }

    // RLS quietly matches nothing when the message is not the caller's.
    if (rows.isEmpty) {
      throw const ChatFailure('Only the sender can edit a message.');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .select('id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not delete that message. Check your connection and try '
            'again.',
      );
    } on Exception {
      throw const ChatFailure(
        'Could not delete that message. Check your connection and try again.',
      );
    }

    if (rows.isEmpty) {
      throw const ChatFailure('Only the sender can delete a message.');
    }
  }

  Future<void> _insert(
    String senderId,
    Map<String, Object?> fields, {
    ChatMessage? echo,
  }) async {
    if (echo != null) {
      _pending.add(echo);
      _wake.add(null);
    }
    try {
      await _client.from('chat_messages').insert({
        if (echo != null) 'id': echo.id,
        'circle_id': circleId,
        'sender_id': senderId,
        ...fields,
      });
      // The broadcast topic skips the sender (self: false), so pull the stored
      // row back ourselves to swap it in for the echo.
      if (echo != null) _wake.add(null);
    } on sb.PostgrestException catch (error) {
      _dropEcho(echo);
      throw _mapFailure(
        error,
        fallback:
            'Could not send that message. Check your connection and try again.',
      );
    } on Exception {
      _dropEcho(echo);
      throw const ChatFailure(
        'Could not send that message. Check your connection and try again.',
      );
    }
  }

  ChatMessage _echo({
    required String senderId,
    required ChatSender sender,
    required ChatMessageKind kind,
    String? body,
    double? latitude,
    double? longitude,
    String? placeLabel,
    ChatMessage? replyTo,
    List<String> mentionedUserIds = const [],
  }) {
    return ChatMessage(
      id: _newMessageId(),
      senderId: senderId,
      senderName: sender.displayName,
      senderAvatarColor: sender.avatarColor,
      kind: kind,
      text: kind == ChatMessageKind.text ? body : null,
      gifUrl: kind == ChatMessageKind.gif ? body : null,
      latitude: latitude,
      longitude: longitude,
      placeLabel: placeLabel,
      createdAt: DateTime.now(),
      replyTo: replyTo?.toReply(),
      mentionedUserIds: mentionedUserIds,
    );
  }

  void _dropEcho(ChatMessage? echo) {
    if (echo == null) return;
    _pending.removeWhere((message) => message.id == echo.id);
    _wake.add(null);
  }

  void _dropConfirmed(List<ChatMessage> thread) {
    final confirmed = {for (final message in thread) message.id};
    _pending.removeWhere((message) => confirmed.contains(message.id));
  }

  Future<List<ChatMessage>> _fetch() async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select(_columns)
          .eq('circle_id', circleId)
          .order('created_at', ascending: false)
          .limit(100);

      final replies = await _replyIndex(const [], rows);
      _advanceCursor(rows);

      // The query is newest-first for the limit; the thread renders oldest
      // first like every other chat app.
      return [for (final row in rows.reversed) _message(row, replies)];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach the crew chat. Check your connection and '
            'try again.',
      );
    }
  }

  /// Fetches only rows the thread does not have yet and appends them.
  Future<List<ChatMessage>> _fetchSince(List<ChatMessage> thread) async {
    final cursor = _cursor;
    if (cursor == null) return _fetch();

    try {
      final rows = await _client
          .from('chat_messages')
          .select(_columns)
          .eq('circle_id', circleId)
          .gte(
            'created_at',
            cursor.subtract(_cursorOverlap).toUtc().toIso8601String(),
          )
          .order('created_at', ascending: true)
          .limit(100);

      // A burst this large could have pushed rows past the page; rebuild.
      if (rows.length >= 100) return await _fetch();

      final replies = await _replyIndex(thread, rows);
      _advanceCursor(rows);
      final fresh = [for (final row in rows) _message(row, replies)];
      return mergeChatThread(thread: thread, optimistic: fresh);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach the crew chat. Check your connection and '
            'try again.',
      );
    }
  }

  /// Reply snippets for the rows about to be rendered: quoted messages already
  /// in the thread, quoted messages in the same batch, and finally anything
  /// older than the window, fetched by id.
  Future<Map<String, ChatMessageReply>> _replyIndex(
    List<ChatMessage> known,
    List<Map<String, dynamic>> rows,
  ) async {
    final index = <String, ChatMessageReply>{
      for (final message in known) message.id: message.toReply(),
    };
    for (final row in rows) {
      final id = row['id'];
      if (id is String) {
        index.putIfAbsent(id, () => _message(row, const {}).toReply());
      }
    }

    final missing = <String>{
      for (final row in rows)
        if (row['reply_to_id'] case final String replyId
            when !index.containsKey(replyId))
          replyId,
    };
    if (missing.isEmpty) return index;

    final parents = await _client
        .from('chat_messages')
        .select(_replyColumns)
        .inFilter('id', missing.toList());
    for (final parent in parents) {
      final id = parent['id'];
      if (id is String) index[id] = _reply(parent);
    }
    return index;
  }

  void _advanceCursor(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final stamp = switch (row['created_at']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      };
      if (stamp == null) continue;
      final cursor = _cursor;
      if (cursor == null || stamp.isAfter(cursor)) _cursor = stamp;
    }
  }

  static String _newMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static ChatMessage _message(
    Map<String, dynamic> row,
    Map<String, ChatMessageReply> replies,
  ) {
    final sender = switch (row['sender']) {
      final Map<String, dynamic> profile => profile,
      final List<dynamic> profiles when profiles.isNotEmpty =>
        profiles.first is Map<String, dynamic>
            ? profiles.first as Map<String, dynamic>
            : const <String, dynamic>{},
      _ => const <String, dynamic>{},
    };
    final kind = _kind(row['kind']);
    final body = _text(row['body']);

    return ChatMessage(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      senderName: _text(sender['display_name']) ?? 'A member',
      senderAvatarColor:
          (sender['avatar_color'] as num?)?.toInt() ?? 0xFF6F9E62,
      kind: kind,
      text: kind == ChatMessageKind.gif ? null : body,
      gifUrl: kind == ChatMessageKind.gif && isAllowedGifUrl(body)
          ? body
          : null,
      poll: kind == ChatMessageKind.poll ? _poll(row['poll_options']) : null,
      placeLabel: _text(row['place_label']),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      replyTo: switch (row['reply_to_id']) {
        final String replyId => replies[replyId],
        _ => null,
      },
      mentionedUserIds:
          (row['mentioned_user_ids'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      editedAt: _timestamp(row['edited_at']),
    );
  }

  static ChatMessageReply _reply(Map<String, dynamic> reply) {
    final sender = switch (reply['sender']) {
      final Map<String, dynamic> profile => profile,
      final List<dynamic> profiles when profiles.isNotEmpty =>
        profiles.first is Map<String, dynamic>
            ? profiles.first as Map<String, dynamic>
            : const <String, dynamic>{},
      _ => const <String, dynamic>{},
    };
    final kind = reply['kind'];
    final place = _text(reply['place_label']);

    return ChatMessageReply(
      id: reply['id'] as String,
      senderId: reply['sender_id'] as String? ?? '',
      senderName: _text(sender['display_name']) ?? 'A member',
      text: switch (kind) {
        'text' || 'poll' => _text(reply['body']),
        'destination_update' =>
          place == null
              ? 'Updated the destination'
              : 'Updated the destination to $place',
        _ => null,
      },
      mediaPreview: switch (kind) {
        'location_share' =>
          place == null ? 'Shared a location' : 'Shared $place',
        'gif' => 'GIF',
        _ => null,
      },
    );
  }

  static ChatPoll? _poll(Object? value) {
    if (value is! List) return null;
    final options = <ChatPollOption>[];
    for (final entry in value) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'];
      final label = _text(entry['label']);
      if (id is! String || label == null) continue;
      options.add(
        ChatPollOption(
          id: id,
          position: (entry['position'] as num?)?.toInt() ?? options.length,
          label: label,
          latitude: (entry['latitude'] as num?)?.toDouble(),
          longitude: (entry['longitude'] as num?)?.toDouble(),
          placeLabel: _text(entry['place_label']),
          voterIds: switch (entry['votes']) {
            final List<dynamic> votes => [
              for (final vote in votes)
                if (vote is Map<String, dynamic>)
                  if (vote['user_id'] case final String voterId) voterId,
            ],
            _ => const <String>[],
          },
        ),
      );
    }
    if (options.length < 2) return null;
    options.sort((a, b) => a.position.compareTo(b.position));
    return ChatPoll(options: List.unmodifiable(options));
  }

  static DateTime? _timestamp(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static ChatMessageKind _kind(Object? value) => switch (value) {
    'location_share' => ChatMessageKind.locationShare,
    'destination_update' => ChatMessageKind.destinationUpdate,
    'gif' => ChatMessageKind.gif,
    'poll' => ChatMessageKind.poll,
    _ => ChatMessageKind.text,
  };

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static ChatFailure _mapFailure(
    sb.PostgrestException error, {
    required String fallback,
  }) {
    final message = switch (error.code) {
      '23514' || '22001' => 'That message is a little too long.',
      '42501' || 'PGRST301' => 'Sign in again to send messages.',
      '23503' || 'P0001' => 'That message is no longer in this thread.',
      _ => null,
    };
    return ChatFailure(message ?? fallback, code: error.code);
  }
}
