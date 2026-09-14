import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalog.dart';

class TopicPickerViewModel extends Notifier<String> {
  @override
  String build() => '';
  void search(String value) => state = value;
  List<Topic> filtered(List<Topic> topics) {
    String normalize(String value) =>
        value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final query = normalize(state.trim());
    return topics
        .where((t) => normalize('${t.name} ${t.groupLabel}').contains(query))
        .toList();
  }
}
