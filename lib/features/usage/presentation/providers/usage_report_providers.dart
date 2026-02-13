import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/file_usage_report_repository.dart';
import '../../data/usage_report_repository.dart';
import '../../domain/usage_event.dart';

final usageReportRepositoryProvider = Provider<UsageReportRepository>((ref) {
  return FileUsageReportRepository();
});

final usageEventsProvider = FutureProvider<List<UsageEvent>>((ref) async {
  return ref.read(usageReportRepositoryProvider).listEvents();
});
