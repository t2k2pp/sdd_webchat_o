import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conversation_repository.dart';
import '../../data/sqlite_conversation_repository.dart';
import '../../domain/conversation_thread.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return SqliteConversationRepository();
});

final conversationListProvider = FutureProvider<List<ConversationThread>>((
  ref,
) async {
  return ref.read(conversationRepositoryProvider).list();
});
