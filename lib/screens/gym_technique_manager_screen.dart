import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/gym_day_model.dart';
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
    final days = ref.watch(gymDayPlanProvider);
    final strings = context.strings;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.gymTechniques),
      appBar: AppBar(
        title: Text(strings.manageGymTechniques),
        actions: [
          IconButton(
            tooltip: strings.addBuiltInExercises,
            onPressed: () => _addBuiltInExercises(context, ref),
            icon: const Icon(Icons.library_add_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addTechnique),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionHeading(
            eyebrow: strings.exerciseLibraryEyebrow,
            title: strings.buildYourPlan,
          ),
          const SizedBox(height: 7),
          Text(
            strings.techniqueManagerIntro,
            style: TextStyle(color: context.palette.mutedText, height: 1.45),
          ),
          const SizedBox(height: 22),
          for (final day in days) ...[
            _DaySection(
              day: day,
              techniques: [
                for (final technique in techniques)
                  if (technique.weekday == day.weekday) technique,
              ],
              onEditDay: () => _openDayEditor(context, ref, day),
              onSwapDay: () => _swapDay(context, ref, day),
              onEdit: (technique) => _openEditor(
                context,
                ref,
                technique: technique,
              ),
              onMove: (technique) => _moveTechnique(context, ref, technique),
              onDelete: (technique) => _confirmDelete(
                context,
                ref,
                technique,
              ),
              onAdd: () => _openEditor(
                context,
                ref,
                initialWeekday: day.weekday,
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
        days: ref.read(gymDayPlanProvider),
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
          technique == null
              ? context.strings.techniqueAdded
              : context.strings.techniqueUpdated,
        ),
      ),
    );
  }

  /// Only a brand new account is seeded automatically, so this is how a plan
  /// that already has data picks up exercises added to the built-in library.
  Future<void> _addBuiltInExercises(BuildContext context, WidgetRef ref) async {
    final added =
        await ref.read(gymTechniqueProvider.notifier).addMissingDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.strings.builtInAdded(added)),
      ),
    );
  }

  Future<void> _openDayEditor(
    BuildContext context,
    WidgetRef ref,
    GymDayModel day,
  ) async {
    final result = await showModalBottomSheet<_DayEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DayEditorSheet(
        day: day,
        existingNames: {
          for (final technique in ref.read(gymTechniqueProvider))
            if (technique.weekday == day.weekday) technique.name.toLowerCase(),
        },
      ),
    );
    if (result == null) return;

    await ref.read(gymDayPlanProvider.notifier).updateDay(result.day);
    // Renaming a day to `Arm day` leaves it holding the old day's bench press,
    // so the day type can bring its own exercises in the same save.
    final seed = result.seed;
    final added = seed == null
        ? 0
        : await ref
            .read(gymTechniqueProvider.notifier)
            .addPresetExercises(seed, result.day.weekday);
    if (!context.mounted) return;
    final strings = context.strings;
    final dayName = strings.weekday(result.day.weekday);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.dayUpdated(dayName, added))),
    );
  }

  /// Trades two whole weekdays: the names, the focus lines and every exercise
  /// on them. Turning Monday into the leg day that currently sits on Wednesday
  /// is one action rather than a rename plus ten exercise edits.
  Future<void> _swapDay(
    BuildContext context,
    WidgetRef ref,
    GymDayModel day,
  ) async {
    final strings = context.strings;
    final target = await _pickDay(
      context,
      ref,
      title: strings.swapDayWith(strings.weekday(day.weekday)),
      subtitle: strings.swapDayHint,
      excludedWeekday: day.weekday,
    );
    if (target == null) return;

    await ref.read(gymDayPlanProvider.notifier).swapDays(day.weekday, target);
    await ref
        .read(gymTechniqueProvider.notifier)
        .swapWeekdays(day.weekday, target);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.daysSwapped(
            strings.weekday(day.weekday),
            strings.weekday(target),
          ),
        ),
      ),
    );
  }

  /// Moves a single exercise without opening the full editor, which is the
  /// long way round when the only thing changing is the day.
  Future<void> _moveTechnique(
    BuildContext context,
    WidgetRef ref,
    GymTechniqueModel technique,
  ) async {
    final strings = context.strings;
    final target = await _pickDay(
      context,
      ref,
      title: strings.moveTo(technique.name),
      subtitle: strings.moveHint,
      excludedWeekday: technique.weekday,
    );
    if (target == null) return;

    final controller = ref.read(gymTechniqueProvider.notifier);
    if (controller.hasNameOnWeekday(
      technique.name,
      target,
      ignoreId: technique.id,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.alreadyOnDay(technique.name, strings.weekday(target)),
          ),
        ),
      );
      return;
    }

    await controller.moveTechnique(technique, target);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.movedTo(technique.name, strings.weekday(target)),
        ),
      ),
    );
  }

  Future<int?> _pickDay(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required int excludedWeekday,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DayPickerSheet(
        title: title,
        subtitle: subtitle,
        days: ref.read(gymDayPlanProvider),
        techniques: ref.read(gymTechniqueProvider),
        excludedWeekday: excludedWeekday,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GymTechniqueModel technique,
  ) async {
    final strings = context.strings;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTechniqueTitle),
        content: Text(
          strings.deleteTechniqueBody(
            technique.name,
            gymDayLabel(
              strings,
              technique.weekday,
              ref.read(gymDayPlanProvider),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.palette.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await ref.read(gymTechniqueProvider.notifier).deleteTechnique(technique.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.techniqueDeleted)),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.techniques,
    required this.onEditDay,
    required this.onSwapDay,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    required this.onAdd,
  });

  final GymDayModel day;
  final List<GymTechniqueModel> techniques;
  final VoidCallback onEditDay;
  final VoidCallback onSwapDay;
  final ValueChanged<GymTechniqueModel> onEdit;
  final ValueChanged<GymTechniqueModel> onMove;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gymDayLabel(context.strings, day.weekday, [day]),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (day.focus.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      day.focus,
                      style: TextStyle(
                        color: context.palette.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (day.isRestDay) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.palette.blueSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  context.strings.restBadge,
                  style: TextStyle(
                    color: context.palette.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
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
            PopupMenuButton<String>(
              tooltip: context.strings.dayActions,
              icon: const Icon(Icons.more_horiz_rounded, size: 21),
              onSelected: (value) {
                if (value == 'edit') onEditDay();
                if (value == 'swap') onSwapDay();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: MenuRow(
                    icon: Icons.edit_outlined,
                    label: context.strings.renameDay,
                  ),
                ),
                PopupMenuItem(
                  value: 'swap',
                  child: MenuRow(
                    icon: Icons.swap_vert_rounded,
                    label: context.strings.swapWithAnotherDay,
                  ),
                ),
              ],
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
                          context.strings.noExercisesOnDay,
                          style: TextStyle(color: context.palette.mutedText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(context.strings.add),
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
                        onMove: () => onMove(techniques[index]),
                        onDelete: () => onDelete(techniques[index]),
                      ),
                      if (index != techniques.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          color: context.palette.divider,
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
    required this.onMove,
    required this.onDelete,
  });

  final GymTechniqueModel technique;
  final VoidCallback onEdit;
  final VoidCallback onMove;
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
                      ? context.strings.usesBuiltInGuide
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
            tooltip: context.strings.techniqueActions,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'move') onMove();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: MenuRow(
                  icon: Icons.edit_outlined,
                  label: context.strings.edit,
                ),
              ),
              PopupMenuItem(
                value: 'move',
                child: MenuRow(
                  icon: Icons.swap_horiz_rounded,
                  label: context.strings.moveToAnotherDay,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: MenuRow(
                  icon: Icons.delete_outline_rounded,
                  label: context.strings.delete,
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

/// What the day editor hands back: the edited day, plus the day type whose
/// exercises the user asked to come along with it.
class _DayEditorResult {
  const _DayEditorResult({required this.day, this.seed});

  final GymDayModel day;
  final GymDayPreset? seed;
}

class _DayEditorSheet extends StatefulWidget {
  const _DayEditorSheet({required this.day, required this.existingNames});

  final GymDayModel day;

  /// Lowercased names already on this day, so the offer counts only what the
  /// day is actually missing instead of promising nine and adding three.
  final Set<String> existingNames;

  @override
  State<_DayEditorSheet> createState() => _DayEditorSheetState();
}

class _DayEditorSheetState extends State<_DayEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _focusController;
  late bool _isRestDay;

  /// The chip that was last tapped, and whether its exercises are still wanted.
  GymDayPreset? _pickedPreset;
  bool _addPresetExercises = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.day.title);
    _focusController = TextEditingController(text: widget.day.focus);
    _isRestDay = widget.day.isRestDay;
    // A quick-pick chip is highlighted by comparing it against the name field,
    // so typing `Leg day` by hand lights the same chip that tapping it would.
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seed = _seedOnOffer;

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
              context.strings.editDay(
                context.strings.weekday(widget.day.weekday),
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              context.strings.editDayHint,
              style: TextStyle(color: context.palette.mutedText),
            ),
            const SizedBox(height: 18),
            Text(
              context.strings.quickPick,
              style: TextStyle(
                color: context.palette.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in gymDayPresets)
                  ChoiceChip(
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        color: _matchesPreset(preset)
                            ? context.palette.onPrimary
                            : context.palette.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: _matchesPreset(preset),
                    onSelected: (_) => _applyPreset(preset),
                  ),
              ],
            ),
            if (seed != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.palette.border),
                ),
                child: CheckboxListTile(
                  value: _addPresetExercises,
                  onChanged: (value) => setState(
                    () => _addPresetExercises = value ?? false,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.fromLTRB(6, 4, 14, 8),
                  title: Text(
                    context.strings.alsoAddExercises(
                      seed.missing.length,
                      seed.preset.title,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    seed.missing.join(', '),
                    style: TextStyle(
                      color: context.palette.mutedText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.strings.dayName,
                hintText: context.strings.dayNameHint,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return context.strings.enterDayName;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _focusController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.strings.focus,
                hintText: context.strings.focusHint,
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isRestDay,
              onChanged: (value) => setState(() => _isRestDay = value),
              title: Text(context.strings.restDay),
              subtitle: Text(
                context.strings.restDayHint,
                style: TextStyle(color: context.palette.mutedText),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(context.strings.saveChanges),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _restoreDefault,
              child: Text(context.strings.resetBuiltInSplit),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesPreset(GymDayPreset preset) {
    return _titleController.text.trim().toLowerCase() ==
        preset.title.toLowerCase();
  }

  /// Fills both fields in one tap. Nothing is saved yet, so the wording is
  /// still free to be edited before the day changes.
  void _applyPreset(GymDayPreset preset) {
    _titleController.text = preset.title;
    _focusController.text = preset.focus;
    setState(() {
      _isRestDay = preset.isRestDay;
      _pickedPreset = preset;
      _addPresetExercises = true;
    });
  }

  /// The exercises currently on offer, or null when there is nothing to add.
  ///
  /// Gated on the name still matching the chip, so typing a different day name
  /// afterwards withdraws the offer instead of quietly seeding a day type the
  /// user has moved on from.
  ({GymDayPreset preset, List<String> missing})? get _seedOnOffer {
    final preset = _pickedPreset;
    if (preset == null || !_matchesPreset(preset)) return null;
    final missing = [
      for (final name in preset.exercises)
        if (!widget.existingNames.contains(name.toLowerCase())) name,
    ];
    if (missing.isEmpty) return null;
    return (preset: preset, missing: missing);
  }

  /// Refills the fields rather than saving straight away, so the built-in
  /// wording can still be tweaked before it replaces what is there.
  void _restoreDefault() {
    final fallback = defaultGymDays[widget.day.weekday - 1];
    _titleController.text = fallback.title;
    _focusController.text = fallback.focus;
    setState(() {
      _isRestDay = fallback.isRestDay;
      _pickedPreset = null;
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _DayEditorResult(
        day: widget.day.copyWith(
          title: _titleController.text.trim(),
          focus: _focusController.text.trim(),
          isRestDay: _isRestDay,
        ),
        seed: _addPresetExercises ? _seedOnOffer?.preset : null,
      ),
    );
  }
}

/// Picks a weekday for a swap or a move. Both actions need the same thing —
/// the user's own day names plus how full each day already is — so they share
/// one sheet instead of two dropdowns that drift apart.
class _DayPickerSheet extends StatelessWidget {
  const _DayPickerSheet({
    required this.title,
    required this.subtitle,
    required this.days,
    required this.techniques,
    required this.excludedWeekday,
  });

  final String title;
  final String subtitle;
  final List<GymDayModel> days;
  final List<GymTechniqueModel> techniques;

  /// The day the exercise or the swap is coming from. Offering it back would
  /// be a no-op, so it is left out of the list.
  final int excludedWeekday;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: context.palette.mutedText),
          ),
          const SizedBox(height: 14),
          for (var weekday = 1; weekday <= 7; weekday++)
            if (weekday != excludedWeekday)
              _DayPickerRow(
                day: gymDayFor(weekday, days),
                exerciseCount: techniques
                    .where((technique) => technique.weekday == weekday)
                    .length,
                onTap: () => Navigator.of(context).pop(weekday),
              ),
        ],
      ),
    );
  }
}

class _DayPickerRow extends StatelessWidget {
  const _DayPickerRow({
    required this.day,
    required this.exerciseCount,
    required this.onTap,
  });

  final GymDayModel day;
  final int exerciseCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.strings.weekday(day.weekday),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.title.trim().isEmpty
                            ? context.strings.exercisesCount(exerciseCount)
                            : '${day.title} · '
                                '${context.strings.exercisesCount(exerciseCount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.palette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TechniqueEditorSheet extends StatefulWidget {
  const _TechniqueEditorSheet({
    required this.technique,
    required this.existingTechniques,
    required this.days,
    this.initialWeekday,
  });

  final GymTechniqueModel? technique;
  final List<GymTechniqueModel> existingTechniques;

  /// The user's own split, so the day picker shows the names they gave it.
  final List<GymDayModel> days;

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
              widget.technique == null
                  ? context.strings.addGymTechnique
                  : context.strings.editTechnique,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              value: _weekday,
              decoration: InputDecoration(
                labelText: context.strings.trainingDay,
              ),
              items: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  DropdownMenuItem(
                    value: weekday,
                    child: Text(
                      gymDayLabel(context.strings, weekday, widget.days),
                    ),
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
              decoration: InputDecoration(
                labelText: context.strings.exerciseName,
                hintText: context.strings.exerciseNameHint,
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cueController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.strings.coachingCue,
                hintText: context.strings.coachingCueHint,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _instructionsController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 7,
              decoration: InputDecoration(
                labelText: context.strings.techniqueSteps,
                hintText: context.strings.oneStepPerLine,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: context.strings.imageUrlOptional,
                prefixIcon: const Icon(Icons.link_rounded),
              ),
              validator: _validateImageUrl,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                widget.technique == null
                    ? context.strings.addTechnique
                    : context.strings.saveChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return context.strings.enterExerciseName;
    final duplicate = widget.existingTechniques.any(
      (technique) =>
          technique.id != widget.technique?.id &&
          technique.weekday == _weekday &&
          technique.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) return context.strings.exerciseExistsOnDay;
    return null;
  }

  String? _validateImageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return context.strings.enterCompleteUrl;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return context.strings.useHttpUrl;
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
