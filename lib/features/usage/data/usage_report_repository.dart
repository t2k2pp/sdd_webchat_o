import '../domain/usage_event.dart';

abstract interface class UsageReportRepository {
  Future<List<UsageEvent>> listEvents();
  Future<void> addEvent(UsageEvent event);
  Future<void> clear();
}
