import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widget/components.dart';
import '../domain/catalog.dart';

class TopicPickerScreen extends ConsumerWidget {
  const TopicPickerScreen({super.key, required this.topics});
  final List<Topic> topics;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(topicPickerViewModelProvider);
    final vm = ref.read(topicPickerViewModelProvider.notifier);
    final visible = vm.filtered(topics);
    final groups = <String, List<Topic>>{};
    for (final topic in visible) {
      (groups[topic.groupLabel] ??= []).add(topic);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Konu seç')),
      body: PageBody(
        children: [
          TextField(
            onChanged: vm.search,
            decoration: const InputDecoration(
              labelText: 'Konu veya ders ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (visible.isEmpty)
            const EmptyView(
              title: 'Konu bulunamadı',
              message: 'Başka bir kelimeyle aramayı dene.',
            ),
          for (final group in groups.entries) ...[
            SectionHeader(group.key),
            ...group.value.map(
              (topic) => Card(
                child: ListTile(
                  title: Text(topic.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pop(topic),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
