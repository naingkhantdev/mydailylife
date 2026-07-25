import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/diet_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/section_heading.dart';

class WorkLogScreen extends ConsumerStatefulWidget {
  const WorkLogScreen({super.key});

  @override
  ConsumerState<WorkLogScreen> createState() => _WorkLogScreenState();
}

class _WorkLogScreenState extends ConsumerState<WorkLogScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(dailyLogProvider).workNotes,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Log')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(
              eyebrow: 'END OF DAY',
              title: 'Accomplishments & notes',
            ),
            const SizedBox(height: 6),
            const Text(
              'What did you get done today? Future you will thank you for the detail.',
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Accomplishments and notes',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(dailyLogProvider.notifier)
                    .updateNotes(workNotes: _controller.text.trim());
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
