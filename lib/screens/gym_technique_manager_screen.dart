import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_technique_model.dart';
import '../providers/gym_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class GymTechniqueManagerScreen extends ConsumerWidget {
  const GymTechniqueManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniques = ref.watch(gymTechniqueProvider);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.gymTechniques),
      appBar: AppBar(title: const Text('Manage gym techniques')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add technique'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Text(
            'EXERCISE LIBRARY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Build your own training plan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          const Text(
            'Add exercises to any training day, update their coaching cues '
            'and instructions, or remove techniques you no longer use.',
            style: TextStyle(color: AppColors.mutedText, height: 1.45),
          ),
          const SizedBox(height: 22),
          for (var weekday = 1; weekday <= 7; weekday++) ...[
            _DaySection(
              weekday: weekday,
              techniques: [
                for (final technique in techniques)
                  if (technique.weekday == weekday) technique,
              ],
              onEdit: (technique) => _openEditor(
                context,
                ref,
                technique: technique,
              ),
              onDelete: (technique) => _confirmDelete(
                context,
                ref,
                technique,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    GymTechniqueModel? technique,
  }) async {
    final result = await showModalBottomSheet<GymTechniqueModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _TechniqueEditorSheet(
        technique: technique,
        existingTechniques: ref.read(gymTechniqueProvider),
      ),
    );
    if (result == null) return;

    final controller = ref.read(gymTechniqueProvider.notifier);
    if (technique == null) {
      await controller.addTechnique(result);
    } else {
      await controller.updateTechnique(result);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          technique == null ? 'Technique added' : 'Technique updated',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GymTechniqueModel technique,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete technique?'),
        content: Text(
          '${technique.name} will be removed from ${_dayName(technique.weekday)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await ref.read(gymTechniqueProvider.notifier).deleteTechnique(technique.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Technique deleted')),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.weekday,
    required this.techniques,
    required this.onEdit,
    required this.onDelete,
  });

  final int weekday;
  final List<GymTechniqueModel> techniques;
  final ValueChanged<GymTechniqueModel> onEdit;
  final ValueChanged<GymTechniqueModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _dayName(weekday),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${techniques.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: techniques.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No techniques assigned to this day.',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < techniques.length; index++) ...[
                      _TechniqueRow(
                        technique: techniques[index],
                        onEdit: () => onEdit(techniques[index]),
                        onDelete: () => onDelete(techniques[index]),
                      ),
                      if (index != techniques.length - 1)
                        const Divider(
                          height: 1,
                          indent: 68,
                          color: AppColors.border,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({
    required this.technique,
    required this.onEdit,
    required this.onDelete,
  });

  final GymTechniqueModel technique;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 44,
              height: 44,
              child: technique.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.blueSoft,
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    )
                  : Image.network(
                      technique.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.blueSoft,
                          child: const Icon(Icons.broken_image_outlined),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technique.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  technique.cue.isEmpty
                      ? 'Uses the built-in technique guide'
                      : technique.cue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Technique actions',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechniqueEditorSheet extends StatefulWidget {
  const _TechniqueEditorSheet({
    required this.technique,
    required this.existingTechniques,
  });

  final GymTechniqueModel? technique;
  final List<GymTechniqueModel> existingTechniques;

  @override
  State<_TechniqueEditorSheet> createState() => _TechniqueEditorSheetState();
}

class _TechniqueEditorSheetState extends State<_TechniqueEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cueController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _imageUrlController;
  late int _weekday;

  @override
  void initState() {
    super.initState();
    final technique = widget.technique;
    _weekday = technique?.weekday ?? DateTime.now().weekday;
    _nameController = TextEditingController(text: technique?.name ?? '');
    _cueController = TextEditingController(text: technique?.cue ?? '');
    _instructionsController = TextEditingController(
      text: technique?.instructions ?? '',
    );
    _imageUrlController = TextEditingController(
      text: technique?.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cueController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.technique == null ? 'Add gym technique' : 'Edit technique',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              value: _weekday,
              decoration: const InputDecoration(
                labelText: 'Training day',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  DropdownMenuItem(
                    value: weekday,
                    child: Text(_dayName(weekday)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _weekday = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              autofocus: widget.technique == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                hintText: 'Example: Dumbbell pullover',
                border: OutlineInputBorder(),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cueController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Quick coaching cue',
                hintText: 'Example: Keep ribs down and move slowly.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _instructionsController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Technique steps',
                hintText: 'Enter one step per line',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
              validator: _validateImageUrl,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                widget.technique == null ? 'Add technique' : 'Save changes',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter an exercise name.';
    final duplicate = widget.existingTechniques.any(
      (technique) =>
          technique.id != widget.technique?.id &&
          technique.weekday == _weekday &&
          technique.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) return 'This exercise already exists on this day.';
    return null;
  }

  String? _validateImageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a complete image URL.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Use an http or https image URL.';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      GymTechniqueModel(
        id: widget.technique?.id ??
            'gym-${DateTime.now().microsecondsSinceEpoch}',
        weekday: _weekday,
        name: _nameController.text.trim(),
        cue: _cueController.text.trim(),
        instructions: _instructionsController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      ),
    );
  }
}

String _dayName(int weekday) {
  const names = [
    'Monday · Push 1',
    'Tuesday · Pull 1',
    'Wednesday · Legs 1 & Core',
    'Thursday · Push 2',
    'Friday · Pull 2',
    'Saturday · Legs 2 & Core',
    'Sunday · Rest & Recovery',
  ];
  return names[weekday - 1];
}
