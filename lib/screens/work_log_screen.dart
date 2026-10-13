import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/diet_provider.dart';
import '../theme/app_palette.dart';
import '../widgets/app_drawer.dart';
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
    final strings = context.strings;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.workLog),
      appBar: AppBar(title: Text(strings.workLog)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              eyebrow: strings.endOfDayEyebrow,
              title: strings.accomplishmentsTitle,
            ),
            const SizedBox(height: 6),
            Text(
              strings.workLogPrompt,
              style: TextStyle(color: context.palette.mutedText, height: 1.4),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: strings.accomplishmentsField,
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
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(strings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
