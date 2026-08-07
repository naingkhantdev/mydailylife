import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/diet_provider.dart';
import '../theme/app_palette.dart';
import '../widgets/app_drawer.dart';
import '../widgets/section_heading.dart';

class NightSplitScreen extends ConsumerStatefulWidget {
  const NightSplitScreen({super.key});

  @override
  ConsumerState<NightSplitScreen> createState() => _NightSplitScreenState();
}

class _NightSplitScreenState extends ConsumerState<NightSplitScreen> {
  late final TextEditingController _studyController;
  late final TextEditingController _gamingController;

  @override
  void initState() {
    super.initState();
    final log = ref.read(dailyLogProvider);
    _studyController = TextEditingController(text: log.studyNotes);
    _gamingController = TextEditingController(text: log.gamingNotes);
  }

  @override
  void dispose() {
    _studyController.dispose();
    _gamingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.nightSplit),
      appBar: AppBar(title: const Text('Night Split')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeading(
            eyebrow: 'EVENING WIND-DOWN',
            title: 'Study & gaming notes',
          ),
          const SizedBox(height: 6),
          Text(
            'A short note is enough — just what you focused on and how it went.',
            style: TextStyle(color: context.palette.mutedText, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _studyController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Study notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gamingController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Gaming notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              ref.read(dailyLogProvider.notifier).updateNotes(
                    studyNotes: _studyController.text.trim(),
                    gamingNotes: _gamingController.text.trim(),
                  );
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
    );
  }
}
