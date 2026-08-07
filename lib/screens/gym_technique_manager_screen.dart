import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_technique_model.dart';
import '../providers/gym_provider.dart';
import '../theme/app_palette.dart';
import '../widgets/app_drawer.dart';
import '../widgets/menu_row.dart';
import '../widgets/section_heading.dart';

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
          const SectionHeading(
            eyebrow: 'EXERCISE LIBRARY',
            title: 'Build your own training plan',
          ),
          const SizedBox(height: 7),
          Text(
            'Add exercises to any training day, update their coaching cues '
            'and instructions, or remove techniques you no longer use.',
            style: TextStyle(color: context.palette.mutedText, height: 1.45),
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
              onAdd: () => _openEditor(context, ref, initialWeekday: weekday),
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
    int? initialWeekday,
  }) async {
    final result = await showModalBottomSheet<GymTechniqueModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _TechniqueEditorSheet(
        technique: technique,
        existingTechniques: ref.read(gymTechniqueProvider),
        initialWeekday: initialWeekday,
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
          '${technique.name} will be removed from ${gymDayLabel(technique.weekday)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.palette.danger),
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
    required this.onAdd,
  });

  final int weekday;
  final List<GymTechniqueModel> techniques;
  final ValueChanged<GymTechniqueModel> onEdit;
  final ValueChanged<GymTechniqueModel> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                gymDayLabel(weekday),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: context.palette.blueSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${techniques.length}',
                style: TextStyle(
                  color: context.palette.primary,
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
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.border),
          ),
          child: techniques.isEmpty
              // A bare "nothing here" line renders seven times on a fresh
              // install; each one now offers the action that fills it.
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'No exercises on this day yet.',
                          style: TextStyle(color: context.palette.mutedText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
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
                        Divider(
                          height: 1,
                          indent: 68,
                          color: context.palette.border,
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
                      color: context.palette.blueSoft,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: context.palette.primary,
                        size: 19,
                      ),
                    )
                  : Image.network(
                      technique.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.palette.blueSoft,
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
                  style: TextStyle(
                    color: context.palette.mutedText,
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: MenuRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: context.palette.danger,
                ),
              ),
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
    this.initialWeekday,
  });

  final GymTechniqueModel? technique;
  final List<GymTechniqueModel> existingTechniques;

  /// Preselects the day when adding from a specific day's empty state, so the
  /// user does not have to re-pick the day they just tapped.
  final int? initialWeekday;

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
    _weekday =
        technique?.weekday ?? widget.initialWeekday ?? DateTime.now().weekday;
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
              ),
              items: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  DropdownMenuItem(
                    value: weekday,
                    child: Text(gymDayLabel(weekday)),
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
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.link_rounded),
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
