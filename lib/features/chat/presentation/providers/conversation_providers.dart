import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conversation_repository.dart';
import '../../data/file_conversation_repository.dart';
import '../../domain/conversation_thread.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return FileConversationRepository();
});

final conversationListProvider = FutureProvider<List<ConversationThread>>((
  ref,
) async {
  return ref.read(conversationRepositoryProvider).list();
});
