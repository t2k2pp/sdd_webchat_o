import '../domain/conversation_thread.dart';

abstract interface class ConversationRepository {
  Future<List<ConversationThread>> list();
  Future<void> upsert(ConversationThread thread);
  Future<ConversationThread?> getById(String id);
  Future<void> delete(String id);
}
