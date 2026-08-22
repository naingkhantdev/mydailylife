import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_technique_model.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/number_format.dart';

/// 40 kg, not 40.0 kg — but 42.5 keeps its half plate.
String _formatKg(double weightKg) {
  return weightKg == weightKg.roundToDouble()
      ? weightKg.toStringAsFixed(0)
      : weightKg.toStringAsFixed(1);
}

GymTechniqueModel? _findTechnique(
  List<GymTechniqueModel> techniques,
  int weekday,
  String exercise,
) {
  for (final technique in techniques) {
    if (technique.weekday == weekday && technique.name == exercise) {
      return technique;
    }
  }
  return null;
}

class GymTechniqueCard extends ConsumerStatefulWidget {
  const GymTechniqueCard({
    super.key,
    required this.gymDay,
  });

  final GymDay gymDay;

  @override
  ConsumerState<GymTechniqueCard> createState() => _GymTechniqueCardState();
}

class _GymTechniqueCardState extends ConsumerState<GymTechniqueCard> {
  @override
  Widget build(BuildContext context) {
    // Watched so a tick — or the first Firestore load after a refresh —
    // rebuilds the rows.
    ref.watch(gymSessionProvider);
    final techniques = ref.watch(gymTechniqueProvider);
    final sessionController = ref.read(gymSessionProvider.notifier);
    final isWorkoutDone =
        sessionController.isWorkoutComplete(widget.gymDay.exercises);
    final volumeKg = sessionController.todayVolumeKg;
    final heaviest = sessionController.todayLoadedExercises;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: context.palette.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.gymDay.title} technique',
                  style: TextStyle(
                    color: context.palette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                isWorkoutDone
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                color: isWorkoutDone ? context.palette.success : context.palette.mutedText,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.gymDay.focus,
            style: TextStyle(color: context.palette.mutedText),
          ),
          // Only once something has been lifted — an empty "0 kg" reads as a
          // failed workout rather than one that has not started.
          if (volumeKg > 0) ...[
            const SizedBox(height: 12),
            _VolumeSummary(volumeKg: volumeKg, heaviest: heaviest),
          ],
          const SizedBox(height: 12),
          for (final exercise in widget.gymDay.exercises) ...[
            _TechniqueRow(
              exercise: exercise,
              technique: _findTechnique(
                techniques,
                widget.gymDay.weekday,
                exercise,
              ),
              session: sessionController.sessionFor(exercise),
              lastSession: sessionController.lastLoggedSession(exercise),
              onToggleSet: (setNumber) {
                ref
                    .read(gymSessionProvider.notifier)
                    .toggleSet(exercise, setNumber);
              },
              onSetTarget: (sets, reps, weightKg) {
                ref.read(gymSessionProvider.notifier).setTarget(
                      exercise: exercise,
                      sets: sets,
                      reps: reps,
                      weightKg: weightKg,
                    );
              },
              onMarkDone: () {
                ref.read(gymSessionProvider.notifier).markExerciseDone(
                      exercise,
                    );
              },
              onClearDone: () {
                ref.read(gymSessionProvider.notifier).clearExercise(
                      exercise,
                    );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Today's total load, with the two heaviest lifts behind it.
///
/// Sets answer "did I do the work"; this answers "how much did I move", which
/// is the number that has to go up over weeks for the split to be worth doing.
class _VolumeSummary extends StatelessWidget {
  const _VolumeSummary({
    required this.volumeKg,
    required this.heaviest,
  });

  final int volumeKg;
  final List<MapEntry<String, GymExerciseSession>> heaviest;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final top = heaviest.take(2).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.violetSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.scale_rounded, size: 18, color: palette.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCount(volumeKg),
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'kg lifted today',
                        style: TextStyle(
                          color: palette.bodyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (top.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      for (final entry in top)
                        '${entry.key} ${_formatKg(entry.value.weightKg)} kg',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({
    required this.exercise,
    required this.technique,
    required this.session,
    required this.lastSession,
    required this.onToggleSet,
    required this.onSetTarget,
    required this.onMarkDone,
    required this.onClearDone,
  });

  final String exercise;
  final GymTechniqueModel? technique;
  final GymExerciseSession session;

  /// The last earlier day this exercise carried a weight, or null the first
  /// time it is logged.
  final GymExerciseSession? lastSession;
  final ValueChanged<int> onToggleSet;
  final void Function(int sets, int reps, double weightKg) onSetTarget;
  final VoidCallback onMarkDone;
  final VoidCallback onClearDone;

  /// "Last: 40 kg x 3x10", or null before this exercise has ever been loaded.
  String? get _lastLoadLabel {
    final previous = lastSession;
    if (previous == null || !previous.hasWeight) {
      return null;
    }
    return 'Last ${_formatKg(previous.weightKg)} kg · '
        '${previous.targetSets} x ${previous.targetReps}';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = session.completedSets.length >= session.targetSets;
    final guide = _ExerciseTechnique.forExercise(
      exercise,
      custom: technique,
    );

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              width: 44,
              height: 44,
              child: guide.photoUrl == null
                  ? Container(
                      color: context.palette.blueSoft,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: context.palette.primary,
                      ),
                    )
                  : Image.network(
                      guide.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.palette.blueSoft,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 18,
                            color: context.palette.primary,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 44 high so opening the technique detail is a real tap
                // target; the bare text row was ~17px.
                SizedBox(
                  height: 44,
                  child: InkWell(
                    onTap: () => _openTechniqueDetail(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise,
                            style: TextStyle(
                              color: context.palette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: context.palette.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  technique?.cue.isNotEmpty ?? false
                      ? technique!.cue
                      : _cueFor(exercise),
                  style: TextStyle(
                    color: context.palette.mutedText,
                    fontSize: 12,
                  ),
                ),
                if (_lastLoadLabel != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 12,
                        color: context.palette.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _lastLoadLabel!,
                        style: TextStyle(
                          color: context.palette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(
                      height: 48,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        onTap: () => _openTargetDialog(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                session.hasWeight
                                    ? '${session.targetSets} x '
                                        '${session.targetReps} · '
                                        '${_formatKg(session.weightKg)} kg'
                                    : '${session.targetSets} x '
                                        '${session.targetReps}',
                                style: TextStyle(
                                  color: context.palette.bodyText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: context.palette.mutedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Doubles as the undo: once every set is ticked the
                    // button clears them again, so a mistaken "All done" is
                    // not a dead end.
                    TextButton(
                      onPressed: isDone ? onClearDone : onMarkDone,
                      child: Text(isDone ? 'Clear' : 'All done'),
                    ),
                  ],
                ),
                // Set toggles get their own row at 48x48 each. They are the
                // most-tapped control in the app, and at five sets they no
                // longer fit beside the target and "All done" controls.
                Wrap(
                  children: [
                    for (var setNumber = 1;
                        setNumber <= session.targetSets;
                        setNumber++)
                      SizedBox.square(
                        dimension: 48,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          onTap: () => onToggleSet(setNumber),
                          child: Icon(
                            session.completedSets.contains(setNumber)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 22,
                            color: session.completedSets.contains(setNumber)
                                ? context.palette.success
                                : context.palette.mutedText,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
    );
  }

  void _openTechniqueDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TechniqueDetailSheet(
        exercise: exercise,
        technique: technique,
      ),
    );
  }

  Future<void> _openTargetDialog(BuildContext context) async {
    final result = await showDialog<({int sets, int reps, double weightKg})>(
      context: context,
      builder: (context) => _TargetDialog(
        initialSets: session.targetSets,
        initialReps: session.targetReps,
        // Prefilled from the last time this exercise was loaded, so the usual
        // action is "add 2.5" rather than remembering the number from scratch.
        initialWeightKg: session.hasWeight
            ? session.weightKg
            : (lastSession?.hasWeight ?? false)
                ? lastSession!.weightKg
                : null,
        lastLoadLabel: _lastLoadLabel,
      ),
    );

    if (result == null) {
      return;
    }

    // Let the dialog route fully detach before the provider update rebuilds
    // the gym card and save-status overlay.
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) {
      return;
    }

    onSetTarget(result.sets, result.reps, result.weightKg);
  }

  String _cueFor(String exercise) {
    final name = exercise.toLowerCase();
    if (name.contains('bench') || name.contains('press')) {
      return 'Brace, keep shoulder blades tight, lower with control, press through mid-foot.';
    }
    if (name.contains('squat') || name.contains('leg press')) {
      return 'Brace first, knees track with toes, control depth, drive evenly through feet.';
    }
    if (name.contains('deadlift') || name.contains('romanian')) {
      return 'Hinge at hips, keep lats tight, neutral spine, move the bar close to body.';
    }
    if (name.contains('row') || name.contains('pull')) {
      return 'Lead with elbows, keep chest stable, squeeze back, avoid swinging.';
    }
    if (name.contains('curl')) {
      return 'Pin elbows, slow lower, avoid shoulder swing, squeeze at the top.';
    }
    if (name.contains('raise')) {
      return 'Use light control, soft elbows, stop near shoulder height, no momentum.';
    }
    if (name.contains('plank') || name.contains('knee')) {
      return 'Ribs down, glutes tight, breathe steady, stop before form breaks.';
    }
    return 'Use controlled reps, full range you can own, and stop if form breaks.';
  }
}

/// Sets, reps and working weight for one exercise.
///
/// Stateful so it owns its text controllers. They used to be created and
/// disposed around the `await showDialog(...)` in the caller, but that future
/// completes as soon as `Navigator.pop` runs: the route is still mounted and
/// animating out, so the controllers were disposed out from under live
/// `TextField`s and the unfocus during teardown called `clearComposing()` on a
/// disposed notifier.
class _TargetDialog extends StatefulWidget {
  const _TargetDialog({
    required this.initialSets,
    required this.initialReps,
    required this.initialWeightKg,
    required this.lastLoadLabel,
  });

  final int initialSets;
  final int initialReps;

  /// Null when this exercise has never carried a weight, so the field opens
  /// empty rather than at a zero the user has to clear.
  final double? initialWeightKg;

  final String? lastLoadLabel;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.initialSets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.initialReps.toString(),
    );
    _weightController = TextEditingController(
      text: widget.initialWeightKg == null
          ? ''
          : _formatKg(widget.initialWeightKg!),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save() {
    final sets = int.tryParse(_setsController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    if (sets == null || reps == null) {
      Navigator.of(context).pop();
      return;
    }

    // An empty field means bodyweight, which stores as zero. So does anything
    // that parses to a number the day's volume total could not hold: that
    // total is an int, and rounding an infinity throws.
    final parsed = double.tryParse(_weightController.text.trim()) ?? 0;
    final weightKg = parsed.isFinite && parsed > 0 ? parsed : 0.0;

    Navigator.of(context).pop((sets: sets, reps: reps, weightKg: weightKg));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              helperText: widget.lastLoadLabel ?? 'Leave empty for bodyweight',
              prefixIcon: const Icon(Icons.fitness_center_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TechniqueDetailSheet extends StatefulWidget {
  const _TechniqueDetailSheet({
    required this.exercise,
    required this.technique,
  });

  final String exercise;
  final GymTechniqueModel? technique;

  @override
  State<_TechniqueDetailSheet> createState() => _TechniqueDetailSheetState();
}

class _TechniqueDetailSheetState extends State<_TechniqueDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final type = _ExerciseTechnique.forExercise(
      widget.exercise,
      custom: widget.technique,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exercise,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (type.photoUrl != null) ...[
                _PhotoGuide(technique: type),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              _DetailBlock(title: 'How to do it', items: type.steps),
              const SizedBox(height: 14),
              _DetailBlock(title: 'Hold / setup', items: type.hold),
              const SizedBox(height: 14),
              _DetailBlock(title: 'Avoid', items: type.avoid),
              const SizedBox(height: 14),
              _DetailBlock(title: 'Tempo', items: type.tempo),
              const SizedBox(height: 14),
              const _SafetyNote(),
            ],
          );
        },
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palette.blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: context.palette.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(color: context.palette.bodyText),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PhotoGuide extends StatelessWidget {
  const _PhotoGuide({required this.technique});

  final _ExerciseTechnique technique;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                technique.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.palette.blueSoft,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: context.palette.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            technique.photoTitle,
            style: TextStyle(
              color: context.palette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            technique.setup,
            style: TextStyle(color: context.palette.bodyText),
          ),
          if (technique.benchAngle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.straighten_rounded,
                  size: 18,
                  color: context.palette.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bench angle: ${technique.benchAngle}',
                    style: TextStyle(
                      color: context.palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            technique.photoCredit,
            style: TextStyle(color: context.palette.mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    // Injury copy was the smallest, faintest text in the sheet. It now reads
    // at body size in a warning-tinted block so it cannot be skimmed past.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.warningSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.palette.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 20,
            color: context.palette.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use a weight you can control for your chosen sets and reps. '
              'Stop if pain, dizziness, numbness, or joint pinching happens. '
              'For heavy bench, squat, or overhead work, use safety pins or a '
              'spotter.',
              style: TextStyle(
                color: context.palette.bodyText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTechnique {
  const _ExerciseTechnique({
    required this.photoTitle,
    required this.photoCredit,
    required this.setup,
    required this.hold,
    required this.steps,
    required this.avoid,
    required this.tempo,
    this.photoUrl,
    this.benchAngle,
  });

  final String? photoUrl;
  final String photoTitle;
  final String photoCredit;
  final String setup;
  final List<String> hold;
  final List<String> steps;
  final List<String> avoid;
  final List<String> tempo;
  final String? benchAngle;

  factory _ExerciseTechnique.forExercise(
    String exercise, {
    GymTechniqueModel? custom,
  }) {
    if (custom?.hasCustomGuide ?? false) {
      final customSteps = custom!.instructions
          .split('\n')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
      return _ExerciseTechnique(
        photoUrl: custom.imageUrl.isEmpty ? null : custom.imageUrl,
        photoTitle: '${custom.name} guide',
        photoCredit: 'Custom RoutineSync technique',
        setup: custom.cue.isEmpty
            ? 'Set up in a stable position and choose a load you can control.'
            : custom.cue,
        hold: const [
          'Keep a stable base and brace before each repetition.',
          'Use a comfortable grip and controlled range of motion.',
        ],
        steps: customSteps.isEmpty
            ? const [
                'Move through a controlled range without using momentum.',
                'Pause briefly, then return to the start under control.',
              ]
            : customSteps,
        avoid: const [
          'Rushing repetitions or losing your setup.',
          'Continuing through sharp pain or joint discomfort.',
        ],
        tempo: const [
          'Use a smooth, controlled lowering phase.',
          'Keep the lifting phase strong without bouncing.',
        ],
      );
    }
    final name = exercise.toLowerCase();

    // Exact names win over the fragment matching below. That chain reads an
    // upright row as a bent-over row, an incline curl as an incline press and
    // a walking lunge as a recovery walk, and everything it does not recognise
    // at all gets the shoulder-press guide at the end of it.
    final named = _techniqueByName[name];
    if (named != null) {
      return named;
    }

    if (name == 'pull-ups or lat pulldown') {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/Pull_up_%284506464%29.jpg/960px-Pull_up_%284506464%29.jpg',
        photoTitle: 'Pull-up setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Use a full grip just outside shoulder width. Start with long arms, set your shoulders down, and pull your chest toward the bar without swinging.',
        hold: [
          'Wrap your thumbs around the bar.',
          'Keep wrists neutral and shoulders away from your ears.',
          'Brace your ribs and keep your legs quiet.',
          'Use an assisted pull-up or lat pulldown if needed.',
        ],
        steps: [
          'Start from long arms with your shoulders controlled.',
          'Drive your elbows down toward your ribs.',
          'Lift until your chin reaches the bar without craning your neck.',
          'Lower under control to the starting position.',
        ],
        avoid: [
          'Kicking or swinging to start the rep.',
          'Shrugging your shoulders toward your ears.',
          'Dropping quickly into the bottom position.',
        ],
        tempo: [
          'Pull up smoothly.',
          'Pause briefly at the top.',
          'Lower for 2-3 seconds.',
        ],
      );
    }
    if (name == 'barbell rows') {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Reverse_grips_bent_over_barbell_rows_1.svg/500px-Reverse_grips_bent_over_barbell_rows_1.svg.png',
        photoTitle: 'Barbell row setup',
        photoCredit: 'Illustration source: Wikimedia Commons',
        setup:
            'Hinge at the hips, brace your torso, and hold the bar with a full grip before rowing it toward your lower ribs.',
        hold: [
          'Grip the bar around shoulder width.',
          'Keep wrists straight and shoulders away from your ears.',
          'Maintain a stable hip hinge and neutral spine.',
          'Keep the bar close to your legs.',
        ],
        steps: [
          'Brace before the first rep.',
          'Drive your elbows behind you and row toward your lower ribs.',
          'Squeeze your upper back without lifting your torso.',
          'Lower the bar until your arms are long.',
        ],
        avoid: [
          'Jerking the bar with your lower back.',
          'Standing more upright on every rep.',
          'Letting the bar drift far from your body.',
        ],
        tempo: [
          'Row in 1 second.',
          'Pause briefly at the top.',
          'Lower for 2 seconds.',
        ],
      );
    }
    if (name == 'seated cable rows') {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Seated_cable_rows_1.svg/960px-Seated_cable_rows_1.svg.png',
        photoTitle: 'Seated cable row setup',
        photoCredit: 'Illustration source: Wikimedia Commons',
        setup:
            'Sit tall with feet planted, hold the handle with straight wrists, and keep your torso stable as you row toward your ribs.',
        hold: [
          'Use a full grip with neutral wrists.',
          'Keep your chest tall and shoulders down.',
          'Plant both feet firmly.',
          'Start with arms long without rounding your lower back.',
        ],
        steps: [
          'Set your shoulders before pulling.',
          'Drive your elbows back toward your ribs.',
          'Pause when the handle reaches your torso.',
          'Return slowly until your arms are long.',
        ],
        avoid: [
          'Rocking your torso to move the weight.',
          'Shrugging at the end of the pull.',
          'Letting the weight stack slam down.',
        ],
        tempo: [
          'Pull in 1 second.',
          'Pause and squeeze.',
          'Return for 2 seconds.',
        ],
      );
    }
    if (name.contains('incline')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://www.champlain.edu/app/uploads/2023/08/campus_students_fitness-center-weights-2400x1350.jpg',
        photoTitle: 'Incline press setup',
        photoCredit: 'Photo source: Champlain College',
        setup:
            'Set the bench before lifting. Hold dumbbells with wrists stacked over elbows, palms facing forward or slightly neutral. Keep shoulder blades pulled back into the bench.',
        hold: [
          'Hold dumbbells directly above elbows; do not let wrists bend back.',
          'Start beside upper chest, not beside the neck.',
          'Elbows stay about 30-60 degrees from your torso.',
          'Shoulder blades stay back and down against the bench.',
        ],
        benchAngle: '30-45 degrees. Use 30 degrees for more chest, 45 degrees for more shoulder.',
        steps: [
          'Set bench to 30-45 degrees and plant feet flat.',
          'Start dumbbells beside upper chest, not near the neck.',
          'Keep wrists straight and elbows about 30-60 degrees from your body.',
          'Press up and slightly inward without smashing dumbbells together.',
        ],
        avoid: [
          'Setting the bench too high like a shoulder press.',
          'Letting wrists bend backward.',
          'Dropping elbows too far below shoulder comfort.',
        ],
        tempo: [
          'Lower for 2-3 seconds.',
          'Pause near upper chest.',
          'Press up smoothly.',
        ],
      );
    }
    if (name.contains('leg extension')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/LegExtensionMachineExercise.JPG/500px-LegExtensionMachineExercise.JPG',
        photoTitle: 'Leg extension setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Sit back into the pad, line knees with the machine hinge, and place the ankle pad just above your feet.',
        hold: [
          'Hold the side handles lightly.',
          'Keep hips and back against the seat.',
          'Ankle pad sits low on the shin, not on the toes.',
          'Knees point straight ahead.',
        ],
        steps: [
          'Brace and extend knees until legs are nearly straight.',
          'Squeeze quads at the top without snapping knees hard.',
          'Lower slowly until the stack almost touches.',
          'Keep your hips down for every rep.',
        ],
        avoid: [
          'Swinging the weight up.',
          'Letting hips lift off the seat.',
          'Locking knees aggressively.',
        ],
        tempo: [
          'Lift in 1 second.',
          'Pause and squeeze.',
          'Lower for 2-3 seconds.',
        ],
      );
    }
    if (name.contains('calf')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/DumbbellStandingCalfRaise.JPG/500px-DumbbellStandingCalfRaise.JPG',
        photoTitle: 'Standing calf raise setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Stand tall with the balls of your feet on a stable edge or floor. Hold support lightly if balance is needed.',
        hold: [
          'Hold dumbbells or machine handles without pulling.',
          'Keep knees mostly straight but not locked.',
          'Let heels lower under control.',
          'Press through the big toe and second toe.',
        ],
        steps: [
          'Lower heels until calves stretch.',
          'Rise onto the balls of your feet.',
          'Pause at the top without rolling ankles outward.',
          'Lower slowly and repeat.',
        ],
        avoid: [
          'Bouncing from the bottom.',
          'Letting ankles roll outward.',
          'Cutting the range short.',
        ],
        tempo: [
          'Lower for 2 seconds.',
          'Pause in the stretch.',
          'Raise and squeeze for 1 second.',
        ],
      );
    }
    if (name.contains('leg press')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Leg_press_%28cropped%2C_flipped%29.jpg/500px-Leg_press_%28cropped%2C_flipped%29.jpg',
        photoTitle: 'Leg press setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Set your back against the pad, feet on the platform about shoulder width, and unlock safety handles only after you are braced.',
        hold: [
          'Hold side handles lightly.',
          'Keep full back and hips against the pad.',
          'Place feet fully on the platform.',
          'Knees track in the same direction as toes.',
        ],
        steps: [
          'Brace and lower the sled until depth stays controlled.',
          'Keep knees tracking over toes.',
          'Press the platform away through mid-foot and heel.',
          'Stop before locking knees hard at the top.',
        ],
        avoid: [
          'Letting hips roll off the pad.',
          'Knees collapsing inward.',
          'Locking knees aggressively under load.',
        ],
        tempo: [
          'Lower for 2-3 seconds.',
          'Pause under control.',
          'Press up smoothly.',
        ],
      );
    }
    if (name.contains('squat')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Squats.svg/500px-Squats.svg.png',
        photoTitle: 'Squat / leg press setup',
        photoCredit: 'Movement image source: Wikimedia Commons',
        setup:
            'Place feet about shoulder width. Hold machine handles lightly if available, brace your core, and keep knees tracking over toes.',
        hold: [
          'Hold side handles only for stability; do not pull yourself down.',
          'Keep full foot on the platform or floor.',
          'Drive through mid-foot and heel.',
          'Knees track in the same direction as toes.',
        ],
        steps: [
          'Set feet about shoulder width and brace your core before moving.',
          'Sit down between your hips while keeping knees tracking over toes.',
          'Stop at a depth you can control without your back rounding.',
          'Drive the floor away and keep your chest stable on the way up.',
        ],
        avoid: [
          'Knees collapsing inward.',
          'Bouncing at the bottom.',
          'Losing your brace before the rep is finished.',
        ],
        tempo: [
          'Lower for 2-3 seconds.',
          'Pause briefly at the bottom.',
          'Stand up with control, not a bounce.',
        ],
      );
    }
    if (name.contains('hip thrust')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/A_U.S._Coast_Guard_recruit%2C_assigned_to_Company_Oscar_188%2C_performs_a_plank_during_incentive_training_at_Coast_Guard_Training_Center_Cape_May_in_Cape_May%2C_N.J.%2C_July_31%2C_2013_130731-G-WA946-943.jpg/500px-thumbnail.jpg',
        photoTitle: 'Hip thrust / bridge setup',
        photoCredit:
            'Related body-position photo source: Wikimedia Commons. Use the text cues for hip thrust setup.',
        setup:
            'Sit with upper back against a bench, feet flat, and bar or dumbbell across the hips with padding.',
        hold: [
          'Upper back rests on the bench edge.',
          'Feet stay flat, about hip width.',
          'Keep chin slightly tucked and ribs down.',
          'Hold the bar steady over your hips.',
        ],
        steps: [
          'Brace, drive through heels, and lift hips.',
          'Stop when shoulders, hips, and knees form a straight line.',
          'Squeeze glutes hard at the top.',
          'Lower hips with control without relaxing completely.',
        ],
        avoid: [
          'Overarching the lower back at the top.',
          'Letting knees cave inward.',
          'Pushing mostly through toes.',
        ],
        tempo: [
          'Lift smoothly.',
          'Pause and squeeze for 1 second.',
          'Lower for 2 seconds.',
        ],
      );
    }
    if (name.contains('deadlift') || name.contains('romanian')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Fit_young_man_doing_deadlift_exercise_in_gym.jpg/330px-Fit_young_man_doing_deadlift_exercise_in_gym.jpg',
        photoTitle: 'Deadlift / hinge setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Hold dumbbells or bar close to your legs. Grip firmly, pull shoulders down, brace, then push hips back while the weight stays near your body.',
        hold: [
          'Hold dumbbells at your sides or bar just in front of thighs.',
          'Keep weight close enough to almost brush your legs.',
          'Pull shoulders down away from ears before the rep starts.',
          'Use a firm full-hand grip.',
        ],
        steps: [
          'Start with ribs down, lats tight, and the weight close to your body.',
          'Push hips back like closing a door behind you.',
          'Keep spine neutral and feel tension in hamstrings.',
          'Drive hips forward to stand tall without leaning back.',
        ],
        avoid: [
          'Letting the weight drift away from the body.',
          'Rounding the lower back.',
          'Turning the movement into a squat.',
        ],
        tempo: [
          'Lower slowly until hamstrings are loaded.',
          'Pause without relaxing your brace.',
          'Stand by squeezing glutes.',
        ],
      );
    }
    if (name.contains('chest press')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Bench_press_1.jpg/500px-Bench_press_1.jpg',
        photoTitle: 'Chest press setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Set the seat so handles start around mid chest. Keep shoulder blades back and wrists stacked.',
        hold: [
          'Hold handles with wrists straight.',
          'Elbows stay slightly below shoulder height.',
          'Shoulder blades stay back against the pad.',
          'Feet stay planted.',
        ],
        steps: [
          'Brace and press handles forward.',
          'Stop before shoulders roll forward.',
          'Lower until chest stretches comfortably.',
          'Repeat with controlled range.',
        ],
        avoid: [
          'Shrugging shoulders.',
          'Letting wrists bend backward.',
          'Bouncing the handles at the bottom.',
        ],
        tempo: [
          'Press in 1 second.',
          'Pause briefly.',
          'Lower for 2 seconds.',
        ],
      );
    }
    if (name == 'bench press') {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Bench_press_1.jpg/500px-Bench_press_1.jpg',
        photoTitle: 'Bench press setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Lie on the bench with eyes under the bar, feet planted, shoulder blades pulled back, and wrists stacked over elbows.',
        hold: [
          'Hold the bar with a full grip, slightly wider than shoulder width.',
          'Wrists stay stacked over elbows; do not bend wrists back.',
          'Shoulder blades stay pulled back and down into the bench.',
          'Feet stay planted for balance and leg drive.',
        ],
        steps: [
          'Set your shoulder blades, brace, and unrack with control.',
          'Lower the bar toward mid to lower chest.',
          'Keep elbows about 45-75 degrees from your torso.',
          'Press up while keeping your upper back tight on the bench.',
        ],
        avoid: [
          'Bouncing the bar on your chest.',
          'Letting wrists fold backward.',
          'Pressing without safety pins or a spotter when heavy.',
        ],
        tempo: [
          'Lower for 2 seconds.',
          'Pause lightly near the chest.',
          'Press up with control.',
        ],
      );
    }
    if (name.contains('fly')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/DumbbellFlye.gif/500px-DumbbellFlye.gif',
        photoTitle: 'Chest fly setup',
        photoCredit: 'Image source: Wikimedia Commons',
        setup:
            'Use light weight. Start with arms above chest, soft elbows, and shoulder blades back.',
        hold: [
          'Hold handles or dumbbells with a soft elbow bend.',
          'Wrists stay neutral.',
          'Shoulder blades stay back and down.',
          'Stop the stretch before shoulder discomfort.',
        ],
        steps: [
          'Open arms in a wide arc.',
          'Feel the chest stretch without losing shoulder position.',
          'Bring hands together over chest.',
          'Keep the same elbow bend through the rep.',
        ],
        avoid: [
          'Going too heavy.',
          'Dropping elbows far below the bench.',
          'Turning the movement into a press.',
        ],
        tempo: [
          'Open for 2-3 seconds.',
          'Pause in the stretch.',
          'Close smoothly.',
        ],
      );
    }
    if (name.contains('face pull')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://www.kovofitness.com/x-media/api/exercise-illustrations/cablefacepull_m.png',
        photoTitle: 'Face pull setup',
        photoCredit: 'Exercise illustration source: Kovo Fitness',
        setup:
            'Set cable around face height. Hold rope ends with thumbs pointing back and stand tall.',
        hold: [
          'Hold rope ends with neutral wrists.',
          'Elbows stay high but shoulders stay down.',
          'Chest stays tall.',
          'Step back until cable has tension.',
        ],
        steps: [
          'Pull rope toward nose or forehead.',
          'Separate hands as elbows move back.',
          'Squeeze rear shoulders and upper back.',
          'Return slowly until arms are long.',
        ],
        avoid: [
          'Leaning back hard.',
          'Shrugging shoulders.',
          'Pulling low toward the chest.',
        ],
        tempo: [
          'Pull in 1 second.',
          'Hold the squeeze.',
          'Return for 2 seconds.',
        ],
      );
    }
    if (name.contains('row')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/DumbbellBentOverRow.JPG/500px-DumbbellBentOverRow.JPG',
        photoTitle: 'Row setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Keep chest stable, brace your torso, and pull elbows toward your ribs without swinging.',
        hold: [
          'Hold handles or bar with a full grip.',
          'Keep shoulders down away from ears.',
          'Chest stays supported or torso stays braced.',
          'Wrists stay straight.',
        ],
        steps: [
          'Start with arms long and shoulder blades controlled.',
          'Pull elbows back toward ribs.',
          'Squeeze your back at the end range.',
          'Return slowly without letting shoulders dump forward.',
        ],
        avoid: [
          'Jerking with the lower back.',
          'Shrugging at the top.',
          'Only moving your hands instead of elbows.',
        ],
        tempo: [
          'Pull in 1 second.',
          'Pause and squeeze.',
          'Return for 2 seconds.',
        ],
      );
    }
    if (name.contains('row') || name.contains('pull')) {
      final isPulldown = name.contains('pulldown') || name.contains('pull-up');
      return _ExerciseTechnique(
        photoUrl: isPulldown
            ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/PulldownMachineExercise.JPG/500px-PulldownMachineExercise.JPG'
            : 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/PulldownMachineExercise.JPG/500px-PulldownMachineExercise.JPG',
        photoTitle: isPulldown ? 'Lat pulldown setup' : 'Pull / row setup',
        photoCredit:
            'Media source: Wikimedia Commons',
        setup:
            'Hold the bar slightly wider than shoulders for pulldowns. Pull elbows down toward ribs, chest tall, and do not lean back hard.',
        hold: [
          'Hold the pulldown bar just outside shoulder width.',
          'Wrap thumbs around the bar unless your machine requires otherwise.',
          'Chest stays tall; shoulders stay down.',
          'Think elbows down, not hands down.',
        ],
        steps: [
          'Set your shoulder blades down before pulling.',
          'Pull with elbows, not hands.',
          'Squeeze your back at the end range.',
          'Return slowly until arms are long but shoulders stay controlled.',
        ],
        avoid: [
          'Shrugging every rep.',
          'Using body swing to move the weight.',
          'Cutting the range short.',
        ],
        tempo: [
          'Pull in 1 second.',
          'Hold the squeeze briefly.',
          'Lower for 2 seconds.',
        ],
      );
    }
    if (name.contains('walk') ||
        name.contains('stretch') ||
        name.contains('meal prep')) {
      final isMealPrep = name.contains('meal prep');
      return _ExerciseTechnique(
        photoUrl: isMealPrep
            ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Meal_Prep.jpg/500px-Meal_Prep.jpg'
            : 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Women_walking_in_Hyderabad_street.jpg/500px-Women_walking_in_Hyderabad_street.jpg',
        photoTitle: isMealPrep ? 'Meal prep' : 'Recovery movement',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup: isMealPrep
            ? 'Prepare simple meals for the next day so diet tracking is easier.'
            : 'Keep recovery easy. Move gently and stop before pain or fatigue builds.',
        hold: [
          if (isMealPrep)
            'Choose foods you can track easily: rice, eggs, chicken, vegetables, fruit.'
          else
            'Keep posture relaxed and breathing steady.',
          if (isMealPrep)
            'Use containers or plates with clear portions.'
          else
            'Use a comfortable walking pace or gentle stretch position.',
          if (isMealPrep)
            'Write the food name and quantity when you log it.'
          else
            'Do not force deep ranges on rest day.',
        ],
        steps: [
          if (isMealPrep)
            'Prepare one or two protein options first.'
          else
            'Start slowly for 3-5 minutes.',
          if (isMealPrep)
            'Add carbohydrate and vegetables.'
          else
            'Keep the effort easy enough to talk.',
          if (isMealPrep)
            'Store meals cleanly and log them when eaten.'
          else
            'Finish feeling better than when you started.',
        ],
        avoid: [
          if (isMealPrep)
            'Guessing portions when you can measure or count them.'
          else
            'Turning recovery into hard training.',
          if (isMealPrep)
            'Leaving cooked food out too long.'
          else
            'Stretching into sharp pain.',
        ],
        tempo: [
          if (isMealPrep)
            'Prep calmly once, then use it through the day.'
          else
            'Move smoothly and breathe normally.',
        ],
      );
    }
    if (name.contains('shoulder press') || name.contains('arnold press')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/ShoulderPressMachineExercise.JPG/500px-ShoulderPressMachineExercise.JPG',
        photoTitle: 'Shoulder press setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Start with handles or dumbbells near shoulder level. Brace ribs down and press without shrugging.',
        hold: [
          'Wrists stay stacked over elbows.',
          'Elbows stay slightly in front of the body.',
          'Ribs stay down.',
          'Feet stay planted.',
        ],
        steps: [
          'Brace before the first rep.',
          'Press upward without leaning back.',
          'Stop before shoulders shrug into ears.',
          'Lower under control to shoulder level.',
        ],
        avoid: [
          'Arching your back to finish reps.',
          'Letting elbows flare far behind you.',
          'Bouncing at the bottom.',
        ],
        tempo: [
          'Press smoothly.',
          'Pause briefly overhead.',
          'Lower for 2 seconds.',
        ],
      );
    }
    if (name.contains('lateral raise')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/DumbbellLateralRaise.JPG/500px-DumbbellLateralRaise.JPG',
        photoTitle: 'Lateral raise setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Use light dumbbells, soft elbows, and raise arms out to the side without swinging.',
        hold: [
          'Hold dumbbells at your sides.',
          'Keep elbows slightly bent.',
          'Thumbs stay level or slightly up.',
          'Shoulders stay down.',
        ],
        steps: [
          'Raise arms out to the side.',
          'Stop around shoulder height.',
          'Pause briefly.',
          'Lower slowly without dropping.',
        ],
        avoid: [
          'Using hip swing.',
          'Shrugging to lift the weight.',
          'Going far above shoulder height with heavy weight.',
        ],
        tempo: [
          'Raise in 1 second.',
          'Pause at shoulder height.',
          'Lower for 2-3 seconds.',
        ],
      );
    }
    if (name.contains('pushdown') || name.contains('pushdowns')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/CableMachinePushdown.JPG/500px-CableMachinePushdown.JPG',
        photoTitle: 'Triceps pushdown setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Stand close to the cable. Pin elbows near ribs and push the bar or rope down without moving upper arms.',
        hold: [
          'Hold bar or rope with wrists straight.',
          'Elbows stay close to your sides.',
          'Chest stays tall.',
          'Shoulders stay down.',
        ],
        steps: [
          'Start with forearms above parallel.',
          'Push down until elbows are straight.',
          'Squeeze triceps at the bottom.',
          'Return slowly without elbows drifting forward.',
        ],
        avoid: [
          'Leaning bodyweight onto the cable.',
          'Letting elbows flare out.',
          'Using shoulders to swing the weight.',
        ],
        tempo: [
          'Push down smoothly.',
          'Pause at lockout.',
          'Return for 2 seconds.',
        ],
      );
    }
    if (name.contains('triceps extension')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/DumbbellTricepsExtension.JPG/500px-DumbbellTricepsExtension.JPG',
        photoTitle: 'Triceps extension setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Keep upper arms steady while elbows bend and straighten. Use a range your elbows tolerate.',
        hold: [
          'Hold dumbbell, bar, or rope with wrists neutral.',
          'Keep elbows pointed mostly forward.',
          'Ribs stay down.',
          'Upper arms move as little as possible.',
        ],
        steps: [
          'Lower the weight by bending elbows.',
          'Stop when triceps stretch comfortably.',
          'Extend elbows until arms are straight.',
          'Keep shoulders stable.',
        ],
        avoid: [
          'Flaring elbows wide.',
          'Arching lower back.',
          'Dropping into a painful elbow range.',
        ],
        tempo: [
          'Lower for 2 seconds.',
          'Pause in control.',
          'Extend smoothly.',
        ],
      );
    }
    if (name.contains('hamstring curl')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/LyingLegCurlMachineExercise.JPG/500px-LyingLegCurlMachineExercise.JPG',
        photoTitle: 'Hamstring curl setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Set the pad just above your heels and keep hips pressed into the bench or seat.',
        hold: [
          'Hold machine handles lightly.',
          'Keep hips down.',
          'Pad rests low on the lower leg.',
          'Knees line up with the machine hinge.',
        ],
        steps: [
          'Curl heels toward glutes.',
          'Squeeze hamstrings at the top.',
          'Lower slowly until legs are nearly straight.',
          'Keep hips from lifting.',
        ],
        avoid: [
          'Jerking from the hips.',
          'Letting hips rise off the pad.',
          'Dropping the weight stack.',
        ],
        tempo: [
          'Curl in 1 second.',
          'Pause and squeeze.',
          'Lower for 2-3 seconds.',
        ],
      );
    }
    if (name.contains('curl')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/PreacherBenchBicepsCurl.gif/500px-PreacherBenchBicepsCurl.gif',
        photoTitle: 'Curl grip setup',
        photoCredit: 'Image source: Wikimedia Commons',
        setup:
            'Hold dumbbells with palms forward or neutral for hammer curls. Keep elbows pinned near ribs and wrists straight.',
        hold: [
          'Hold dumbbells with wrists straight.',
          'For hammer curls, palms face each other.',
          'Elbows stay close to ribs.',
          'Do not let shoulders roll forward.',
        ],
        steps: [
          'Stand tall and pin elbows near your ribs.',
          'Curl without moving your shoulders forward.',
          'Squeeze at the top.',
          'Lower slowly until elbows are straight but not relaxed.',
        ],
        avoid: [
          'Swinging the torso.',
          'Letting elbows drift forward.',
          'Dropping the weight fast.',
        ],
        tempo: [
          'Curl up smoothly.',
          'Pause at peak contraction.',
          'Lower for 2-3 seconds.',
        ],
      );
    }
    if (name.contains('lunge')) {
      return const _ExerciseTechnique(
        photoUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Airman_performing_lunge.jpg/500px-Airman_performing_lunge.jpg',
        photoTitle: 'Lunge setup',
        photoCredit: 'Photo source: Wikimedia Commons',
        setup:
            'Step long enough that your front foot stays flat and both knees can bend with balance.',
        hold: [
          'Hold dumbbells at your sides if loaded.',
          'Front foot stays flat.',
          'Torso stays tall or slightly forward.',
          'Front knee tracks with toes.',
        ],
        steps: [
          'Step forward or walk into the lunge.',
          'Lower until both knees bend comfortably.',
          'Drive through the front foot to stand.',
          'Repeat on the other side.',
        ],
        avoid: [
          'Front knee collapsing inward.',
          'Taking too short a step.',
          'Pushing off the back foot only.',
        ],
        tempo: [
          'Lower for 2 seconds.',
          'Pause briefly.',
          'Stand with control.',
        ],
      );
    }
    if (name.contains('plank') || name.contains('knee')) {
      final isKneeRaise = name.contains('knee');
      return _ExerciseTechnique(
        photoUrl: isKneeRaise
            ? 'https://upload.wikimedia.org/wikipedia/commons/3/39/SeatedLegRaise.gif'
            : 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/A_U.S._Coast_Guard_recruit%2C_assigned_to_Company_Oscar_188%2C_performs_a_plank_during_incentive_training_at_Coast_Guard_Training_Center_Cape_May_in_Cape_May%2C_N.J.%2C_July_31%2C_2013_130731-G-WA946-943.jpg/500px-thumbnail.jpg',
        photoTitle: 'Core setup',
        photoCredit: 'Image source: Wikimedia Commons',
        setup:
            'Brace ribs down, squeeze glutes, and keep neck neutral. For knee raises, hold the handles firmly and avoid swinging.',
        hold: [
          'For plank, elbows stay under shoulders.',
          'For hanging knee raises, use a full grip on handles or bar.',
          'Brace ribs down before the first rep.',
          'Keep neck neutral.',
        ],
        steps: [
          'Lock ribs down and squeeze glutes.',
          'Keep neck neutral and breathe steadily.',
          'Move only as far as you can without arching your back.',
          'Stop the set before your hips sag.',
        ],
        avoid: [
          'Holding breath.',
          'Letting lower back arch.',
          'Rushing reps.',
        ],
        tempo: [
          'Move slowly.',
          'Pause when tension is highest.',
          'Return with control.',
        ],
      );
    }
    return const _ExerciseTechnique(
      photoUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/ShoulderPressMachineExercise.JPG/500px-ShoulderPressMachineExercise.JPG',
      photoTitle: 'Press setup',
      photoCredit: 'Photo source: Wikimedia Commons',
      setup:
          'Hold handles or dumbbells with wrists stacked over elbows. Keep shoulders down, brace your ribs, and press without shrugging.',
      hold: [
        'Hold handles or dumbbells with wrist stacked over elbow.',
        'Start around shoulder level.',
        'Ribs stay down; do not lean back to finish reps.',
        'Press upward without shrugging.',
      ],
      steps: [
        'Set your base first: feet planted, core braced, shoulders stable.',
        'Lower the weight under control.',
        'Pause briefly where the target muscle is stretched.',
        'Press smoothly and keep wrists stacked over elbows.',
      ],
      avoid: [
        'Flaring elbows too hard.',
        'Losing shoulder position.',
        'Bouncing the weight.',
      ],
      tempo: [
        'Lower for 2 seconds.',
        'Pause briefly.',
        'Press up with control.',
      ],
    );
  }
}

/// Coaching notes for exercises the fragment matching in
/// [_ExerciseTechnique.forExercise] gets wrong, or does not recognise at all.
///
/// Keyed by the exercise name in lower case, exactly as it is seeded in
/// `gym_provider.dart` — rename an exercise there and its key moves with it.
/// Entries carry no photo, so the detail sheet drops the image block and the
/// row falls back to its icon tile.
const _techniqueByName = <String, _ExerciseTechnique>{
  // --- Push: chest ---------------------------------------------------------
  'dumbbell bench press': _ExerciseTechnique(
    photoTitle: 'Dumbbell bench press',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Sit with the dumbbells on your thighs, kick them back one at a time as you lie down, and set your shoulder blades down and together before the first rep.',
    hold: [
      'Wrists stacked over the elbows, knuckles to the ceiling.',
      'Shoulder blades pinched down into the bench.',
      'Feet flat, glutes down, ribs down.',
      'Dumbbells start just outside the chest, not out wide.',
    ],
    steps: [
      'Press both dumbbells to full arm length over the mid-chest.',
      'Lower under control until the elbows are level with your ribs.',
      'Keep the elbows about 45 degrees from the body, not flared to 90.',
      'Press back up and stop just short of clashing the dumbbells.',
    ],
    avoid: [
      'Flaring the elbows straight out to the sides.',
      'Letting the shoulder blades come loose and the shoulders roll forward.',
      'Dropping the dumbbells behind you at the end of a set.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'Pause briefly at chest level.',
      'Press up strongly without locking hard.',
    ],
  ),
  'chest dips': _ExerciseTechnique(
    photoTitle: 'Chest dips',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Press up to straight arms on the parallel bars, then lean the chest forward 20-30 degrees and keep that lean for the whole set.',
    hold: [
      'Full grip, wrists straight, elbows soft at the top.',
      'Shoulders pulled down away from the ears.',
      'Chest leaning forward, hips slightly behind the hands.',
      'Use the assisted dip machine or a band until 8 clean reps are easy.',
    ],
    steps: [
      'Start at the top with straight arms and the shoulders down.',
      'Lower until the upper arms are roughly parallel to the floor.',
      'Keep the forward lean so the chest takes the load, not the shoulder joint.',
      'Press back up without shrugging at the top.',
    ],
    avoid: [
      'Dropping below a comfortable shoulder range.',
      'Letting the shoulders shrug up at the bottom.',
      'Bouncing out of the bottom position.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'Pause where you feel a stretch, not a pinch.',
      'Press up with control.',
    ],
  ),
  'close-grip bench press': _ExerciseTechnique(
    photoTitle: 'Close-grip bench press',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Take a grip about shoulder width, not narrower. Tuck the elbows in and drive the bar over the lower chest.',
    hold: [
      'Hands roughly shoulder width, wrists stacked over the bar.',
      'Elbows tucked to about 30 degrees from the body.',
      'Shoulder blades down and together.',
      'Feet planted, glutes on the bench.',
    ],
    steps: [
      'Unrack and set the bar over the lower chest.',
      'Lower to the bottom of the sternum with the elbows tucked.',
      'Touch lightly and keep the wrists straight.',
      'Press back up and think about driving the elbows to lockout.',
    ],
    avoid: [
      'Gripping so narrow that the wrists bend back.',
      'Letting the elbows drift out wide.',
      'Bouncing the bar off the chest.',
    ],
    tempo: [
      'Lower for 2 seconds.',
      'Touch without resting on the chest.',
      'Press up strongly through the triceps.',
    ],
  ),
  'pec deck fly': _ExerciseTechnique(
    photoTitle: 'Pec deck fly',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Set the seat so the handles sit at mid-chest height and the elbows stay level with or just below the shoulders.',
    hold: [
      'Seat height so the handles line up with the middle of the chest.',
      'Soft elbow bend, fixed at that angle.',
      'Back and both shoulders stay on the pad.',
      'Feet flat, ribs down.',
    ],
    steps: [
      'Start with the arms open and a stretch across the chest.',
      'Squeeze the handles together with the chest, not the hands.',
      'Bring them until they nearly touch in front of the sternum.',
      'Open back out slowly to a comfortable stretch.',
    ],
    avoid: [
      'Opening so far back that the shoulders feel pinched.',
      'Bending and straightening the elbows to press it.',
      'Letting the back arch off the pad.',
    ],
    tempo: [
      'Open for 3 seconds.',
      'Squeeze for 1 second at the front.',
      'Keep the tension for the whole set.',
    ],
  ),
  'dumbbell pullover': _ExerciseTechnique(
    photoTitle: 'Dumbbell pullover',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Lie along a bench holding one dumbbell with both palms flat against the inside of the top plate, arms nearly straight over the chest.',
    hold: [
      'Both palms flat under the top plate, thumbs wrapped.',
      'Elbows slightly bent and locked at that angle.',
      'Ribs down, glutes tight, feet planted.',
      'Hips stay level through the whole rep.',
    ],
    steps: [
      'Start with the dumbbell over the chest.',
      'Lower it back over the head until the lats and ribs stretch.',
      'Stop where the shoulders still feel comfortable.',
      'Pull it back over the chest with the lats, elbow angle unchanged.',
    ],
    avoid: [
      'Arching the lower back to reach further.',
      'Bending the elbows and turning it into a triceps move.',
      'Going heavy before the shoulder range is comfortable.',
    ],
    tempo: [
      'Lower for 3 seconds.',
      'Pause in the stretch.',
      'Pull back over for 1-2 seconds.',
    ],
  ),

  'push-ups': _ExerciseTechnique(
    photoTitle: 'Push-ups',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Hands under the shoulders, body in one line from ears to heels. The plank position is the exercise; the arms only lower and raise it.',
    hold: [
      'Hands under the shoulders, fingers spread.',
      'Elbows travel back at about 45 degrees, not out to the sides.',
      'Glutes tight, ribs down, hips level.',
      'Put the hands on a bench to scale it down before dropping to the knees.',
    ],
    steps: [
      'Set the plank position and brace before the first rep.',
      'Lower until the chest is about a fist off the floor.',
      'Keep the elbows tucked at about 45 degrees.',
      'Press the floor away and stop just short of locking out.',
    ],
    avoid: [
      'Letting the hips sag, or piking them up to rest.',
      'Flaring the elbows straight out to the sides.',
      'Dropping the head forward to fake depth.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'Pause a moment at the bottom.',
      'Press up for 1 second.',
    ],
  ),

  // --- Push: shoulders -----------------------------------------------------
  'front raises': _ExerciseTechnique(
    photoTitle: 'Front raises',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand tall with the dumbbells in front of the thighs, palms facing you, ribs braced so the body stays still.',
    hold: [
      'Light dumbbells: this is a small muscle on a long lever.',
      'Soft elbows, wrists neutral.',
      'Ribs down, glutes lightly tight.',
      'Shoulders pulled down away from the ears.',
    ],
    steps: [
      'Raise one or both arms straight out in front of you.',
      'Stop at about shoulder height.',
      'Keep the thumb slightly higher than the little finger.',
      'Lower slowly to the front of the thighs.',
    ],
    avoid: [
      'Swinging the hips to start the rep.',
      'Raising far above shoulder height.',
      'Shrugging the traps to finish the lift.',
    ],
    tempo: [
      'Lift for 1-2 seconds.',
      'Pause at the top.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'upright row': _ExerciseTechnique(
    photoTitle: 'Upright row',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Hold the bar or dumbbells at shoulder width or a little wider. A wide grip is far kinder to the shoulder than a narrow one.',
    hold: [
      'Grip at shoulder width or wider, never narrow.',
      'Wrists straight, the bar travelling close to the body.',
      'Ribs down, knees soft.',
      'Shoulders start pulled down.',
    ],
    steps: [
      'Start with long arms and the bar against the thighs.',
      'Lead with the elbows and pull the bar up the front of the body.',
      'Stop when the elbows reach shoulder height, no higher.',
      'Lower under control to full arm length.',
    ],
    avoid: [
      'A narrow grip, which pinches the shoulder.',
      'Pulling the elbows above shoulder height.',
      'Leaning back and swinging the weight up.',
      'Working through a pinch: swap to a lateral raise or face pull.',
    ],
    tempo: [
      'Pull for 1-2 seconds.',
      'Pause at shoulder height.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'dumbbell shrugs': _ExerciseTechnique(
    photoTitle: 'Dumbbell shrugs',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand tall with a dumbbell in each hand at your sides, arms long. The only movement is the shoulders travelling straight up.',
    hold: [
      'Full grip, arms straight and relaxed.',
      'Ribs down, chin tucked slightly.',
      'Feet under the hips.',
      'Shoulders start all the way down.',
    ],
    steps: [
      'Lift the shoulders straight up toward the ears.',
      'Pause at the top and squeeze.',
      'Lower all the way down until the traps stretch.',
      'Keep the arms straight throughout.',
    ],
    avoid: [
      'Rolling the shoulders in circles.',
      'Bending the elbows to help.',
      'Jerking with the legs.',
    ],
    tempo: [
      'Shrug up for 1 second.',
      'Hold 1-2 seconds at the top.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'rear delt fly': _ExerciseTechnique(
    photoTitle: 'Rear delt fly',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Hinge at the hips with a flat back, or lie chest-down on an incline bench, and let the dumbbells hang under the shoulders.',
    hold: [
      'Light dumbbells, palms facing each other.',
      'Soft elbow bend, fixed at that angle.',
      'Flat back, chest supported on a bench if possible.',
      'Neck neutral: look at the floor.',
    ],
    steps: [
      'Start with the arms hanging straight down.',
      'Open the arms out to the sides, leading with the elbows.',
      'Stop level with the shoulders.',
      'Lower slowly back under the shoulders.',
    ],
    avoid: [
      'Shrugging the traps to lift the weight.',
      'Swinging the torso up to move heavier dumbbells.',
      'Squeezing the shoulder blades instead of moving the arms.',
    ],
    tempo: [
      'Open for 2 seconds.',
      'Pause at the top.',
      'Lower for 3 seconds.',
    ],
  ),

  // --- Push: triceps -------------------------------------------------------
  'skull crushers': _ExerciseTechnique(
    photoTitle: 'Skull crushers',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Lie on a bench with an EZ bar or dumbbells over the chest, elbows pointing at the ceiling and angled slightly toward your head.',
    hold: [
      'Grip just inside shoulder width on an EZ bar.',
      'Elbows fixed, pointing up, tucked to shoulder width.',
      'Shoulder blades down on the bench.',
      'Ribs down, feet flat.',
    ],
    steps: [
      'Start with straight arms, the weight slightly behind the head line.',
      'Bend only at the elbows and lower toward the forehead or just past it.',
      'Keep the upper arms still the whole way.',
      'Straighten the elbows without snapping into lockout.',
    ],
    avoid: [
      'Letting the elbows flare wide.',
      'Swinging the upper arms and turning it into a pullover.',
      'Loading it heavy enough that the elbows ache.',
    ],
    tempo: [
      'Lower for 3 seconds.',
      'Pause just short of the head.',
      'Extend for 1-2 seconds.',
    ],
  ),

  // --- Pull: back ----------------------------------------------------------
  'straight-arm pulldown': _ExerciseTechnique(
    photoTitle: 'Straight-arm pulldown',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand a step back from a high cable, hinge slightly at the hips, and hold the bar with nearly straight arms at head height.',
    hold: [
      'Grip at shoulder width, wrists neutral.',
      'Elbows slightly bent and locked at that angle.',
      'Hips hinged back a little, chest tall.',
      'Ribs down, core braced.',
    ],
    steps: [
      'Start with the bar high and a stretch through the lats.',
      'Pull the bar down in an arc to the thighs using the lats.',
      'Keep the same fixed arm angle throughout.',
      'Let the bar rise back to head height under control.',
    ],
    avoid: [
      'Bending the elbows and pressing it down with the triceps.',
      'Standing straight up and using body weight.',
      'Rounding the back at the bottom.',
    ],
    tempo: [
      'Pull down for 2 seconds.',
      'Squeeze the lats for 1 second.',
      'Return for 3 seconds.',
    ],
  ),
  'inverted row': _ExerciseTechnique(
    photoTitle: 'Inverted row',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Set a bar at hip height, hang underneath it with straight arms, and hold one line from ears to heels.',
    hold: [
      'Grip just outside shoulder width.',
      'Body straight: ribs down, glutes tight.',
      'Legs straight to make it harder, knees bent to make it easier.',
      'Shoulders pulled down away from the ears.',
    ],
    steps: [
      'Start hanging with long arms and the shoulder blades relaxed.',
      'Pull the chest to the bar, driving the elbows back past the ribs.',
      'Squeeze the shoulder blades together at the top.',
      'Lower until the arms are fully straight.',
    ],
    avoid: [
      'Letting the hips sag toward the floor.',
      'Shrugging the shoulders to the ears.',
      'Cutting the range short at the top.',
    ],
    tempo: [
      'Pull for 1-2 seconds.',
      'Hold at the chest for 1 second.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'one-arm dumbbell row': _ExerciseTechnique(
    photoTitle: 'One-arm dumbbell row',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Put one hand and one knee on a bench, back flat and roughly parallel to the floor, and let the dumbbell hang under the shoulder.',
    hold: [
      'Flat back, hips square to the floor.',
      'Supporting arm straight, that shoulder not collapsed.',
      'Neck neutral: look at the bench.',
      'The dumbbell hangs directly under the shoulder.',
    ],
    steps: [
      'Start with the arm long and the shoulder blade reaching forward.',
      'Pull the dumbbell to the side of the ribs, elbow close to the body.',
      'Keep the torso still: no twisting to lift it higher.',
      'Lower all the way back to a full stretch.',
    ],
    avoid: [
      'Rotating the torso to help the arm.',
      'Pulling the elbow out wide toward the shoulder.',
      'Rounding the lower back.',
    ],
    tempo: [
      'Pull for 1-2 seconds.',
      'Pause at the ribs.',
      'Lower for 3 seconds.',
    ],
  ),

  'farmer carry': _ExerciseTechnique(
    photoTitle: 'Farmer carry',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Pick up a heavy dumbbell in each hand, stand tall, and walk. The load tries to pull you out of position, and holding position is the whole exercise.',
    hold: [
      'Full grip, arms hanging straight and relaxed.',
      'Shoulders pulled down and back, chest tall.',
      'Ribs down, core braced as if for a punch.',
      'Weights hang clear of the thighs rather than resting on them.',
    ],
    steps: [
      'Hinge down and pick both weights up with a flat back.',
      'Stand tall and set the shoulders before the first step.',
      'Walk short controlled steps for 20-40 metres or 30-45 seconds.',
      'Set the weights down with a hinge, not a drop.',
    ],
    avoid: [
      'Leaning to one side under an uneven load.',
      'Shrugging the shoulders up toward the ears.',
      'Rounding the back picking the weights up or putting them down.',
    ],
    tempo: [
      'Steady, even steps.',
      'Breathe shallow, but never hold your breath.',
      'End the set when the posture breaks or the grip is genuinely going.',
    ],
  ),

  // --- Pull: biceps --------------------------------------------------------
  'incline dumbbell curls': _ExerciseTechnique(
    photoTitle: 'Incline dumbbell curls',
    photoCredit: 'RoutineSync coaching notes',
    benchAngle:
        '45-60 degrees. The lower the bench, the bigger the stretch and the harder the set.',
    setup:
        'Set a bench to about 45-60 degrees, sit back against it, and let the dumbbells hang behind the line of the body.',
    hold: [
      'Back flat on the pad, shoulders down.',
      'Arms hanging straight down, palms forward.',
      'Upper arms stay behind the torso: that is the point of the incline.',
      'Go lighter than a standing curl.',
    ],
    steps: [
      'Start with the arms fully long and the biceps stretched.',
      'Curl without letting the elbows travel forward.',
      'Stop when the forearm is just past vertical.',
      'Lower all the way back to a full stretch.',
    ],
    avoid: [
      'Letting the elbows swing forward to finish the rep.',
      'Shrugging the shoulders off the pad.',
      'Cutting the bottom of the range short.',
    ],
    tempo: [
      'Curl for 1-2 seconds.',
      'Squeeze at the top.',
      'Lower for 3 seconds to a full stretch.',
    ],
  ),
  'hammer curls': _ExerciseTechnique(
    photoTitle: 'Hammer curls',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand with the dumbbells at your sides, palms facing in toward the thighs. That neutral wrist stays for the whole rep.',
    hold: [
      'Palms face each other the whole set.',
      'Elbows pinned at your sides.',
      'Ribs down, knees soft.',
      'Shoulders relaxed and down.',
    ],
    steps: [
      'Curl the dumbbell straight up toward the shoulder.',
      'Keep the thumb on top the whole way.',
      'Stop before the elbow drifts forward.',
      'Lower under control to a straight arm.',
    ],
    avoid: [
      'Swinging the body to start the rep.',
      'Rotating the wrist, which turns it into a normal curl.',
      'Bouncing at the bottom.',
    ],
    tempo: [
      'Curl for 1-2 seconds.',
      'Pause at the top.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'preacher curls': _ExerciseTechnique(
    photoTitle: 'Preacher curls',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Set the pad so its top edge sits under the armpits. The upper arms stay flat on the pad for the whole set.',
    hold: [
      'Chest against the top of the pad.',
      'Upper arms flat, armpits at the top edge.',
      'Wrists straight, full grip on the bar.',
      'Feet planted for a stable base.',
    ],
    steps: [
      'Start with the arms almost straight, never locked hard.',
      'Curl until the forearms are just past vertical.',
      'Keep the upper arms glued to the pad.',
      'Lower slowly and stop just short of a locked elbow.',
    ],
    avoid: [
      'Dropping fast into a locked elbow: that is where this lift strains.',
      'Lifting the elbows off the pad.',
      'Letting the wrists bend back under a heavy bar.',
    ],
    tempo: [
      'Curl for 1-2 seconds.',
      'Squeeze at the top.',
      'Lower for 3 seconds.',
    ],
  ),

  // --- Legs ----------------------------------------------------------------
  'front squat': _ExerciseTechnique(
    photoTitle: 'Front squat',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Rack the bar across the front of the shoulders, not in the hands. The elbows stay high so the bar cannot roll forward.',
    hold: [
      'Bar resting on the front delts, fingers only guiding it.',
      'Elbows high and pointing forward all set.',
      'Feet shoulder width, toes turned slightly out.',
      'Ribs down and braced before you unrack.',
    ],
    steps: [
      'Unrack, take two steps back, set the stance.',
      'Sit straight down with the torso as upright as you can hold.',
      'Go to the depth where the back still stays flat.',
      'Drive up while keeping the elbows high.',
    ],
    avoid: [
      'Dropping the elbows, which tips the bar forward.',
      'Letting the chest fall out of the bottom.',
      'Chasing depth your ankles and hips do not have yet.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'No bounce at the bottom.',
      'Stand up strongly.',
    ],
  ),
  'bulgarian split squat': _ExerciseTechnique(
    photoTitle: 'Bulgarian split squat',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand about one long stride in front of a bench, rest the top of the back foot on it, and keep the weight through the front heel.',
    hold: [
      'Front foot far enough forward that the knee stays over the mid-foot.',
      'Back foot resting on the bench, not pushing.',
      'Chest tall, ribs down, a slight forward lean from the hips.',
      'Dumbbells at your sides until the balance is solid.',
    ],
    steps: [
      'Lower straight down by bending the front knee and hip.',
      'Stop when the front thigh is about parallel, or the back knee is just off the floor.',
      'Keep the front heel flat on the floor the whole time.',
      'Drive up through the front foot without pushing off the back leg.',
    ],
    avoid: [
      'Standing too close to the bench, which crushes the front knee.',
      'Letting the front heel lift.',
      'Rushing: the balance fails before the muscle does.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'Pause just above the floor.',
      'Drive up for 1-2 seconds.',
    ],
  ),
  'walking lunges': _ExerciseTechnique(
    photoTitle: 'Walking lunges',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Take a long step forward, drop straight down, then step through into the next lunge. The torso stays tall throughout.',
    hold: [
      'Steps long enough that the front knee stays over the mid-foot.',
      'Chest tall, ribs down, eyes forward.',
      'Feet on two separate lines, not on a tightrope.',
      'Dumbbells at your sides or hands on the hips.',
    ],
    steps: [
      'Step forward and lower straight down.',
      'Stop when the back knee is just above the floor.',
      'Drive through the front heel to stand.',
      'Step straight through into the next rep.',
    ],
    avoid: [
      'Short steps that push the front knee far past the toes.',
      'Letting the front knee collapse inward.',
      'Leaning the torso over the front leg.',
    ],
    tempo: [
      'Lower for 2 seconds.',
      'Touch lightly at the bottom.',
      'Drive up for 1-2 seconds.',
    ],
  ),
  'dumbbell step-ups': _ExerciseTechnique(
    photoTitle: 'Dumbbell step-ups',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Use a box that puts the thigh roughly parallel to the floor. Place the whole foot on it and drive up through that heel.',
    hold: [
      'Whole foot on the box, not just the toes.',
      'Dumbbells at your sides, arms relaxed.',
      'Chest tall, ribs down.',
      'A box low enough to keep control of every rep.',
    ],
    steps: [
      'Place one foot fully on the box.',
      'Drive through that heel and stand up tall.',
      'Do not push off the floor with the trailing foot.',
      'Lower slowly with the same leg and touch the floor lightly.',
    ],
    avoid: [
      'Bouncing off the trailing foot.',
      'Pushing through the toes of the working leg.',
      'Dropping down instead of lowering.',
    ],
    tempo: [
      'Step up for 1-2 seconds.',
      'Stand tall for a second.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'single-leg romanian deadlift': _ExerciseTechnique(
    photoTitle: 'Single-leg Romanian deadlift',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand on one leg with a soft knee, dumbbell in the opposite hand, and hinge at the hip while the free leg travels back as a counterweight.',
    hold: [
      'Standing knee soft, never locked.',
      'Hips square to the floor: do not let the free hip open up.',
      'Back flat, shoulders pulled down.',
      'Hold a rack or wall with one hand while learning.',
    ],
    steps: [
      'Hinge at the hip and push the free leg straight back.',
      'Let the dumbbell travel close to the standing leg.',
      'Stop around hip height, before the back would round.',
      'Squeeze the standing glute to stand back tall.',
    ],
    avoid: [
      'Rotating the hips open at the bottom.',
      'Rounding the back to reach the floor.',
      'Going heavy before the balance is there.',
    ],
    tempo: [
      'Lower for 3 seconds.',
      'Pause at the bottom.',
      'Stand for 1-2 seconds.',
    ],
  ),
  'glute bridge': _ExerciseTechnique(
    photoTitle: 'Glute bridge',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Lie on your back with the knees bent and the heels about a hand-length from the hips, then push through the heels and lift the hips.',
    hold: [
      'Heels close enough that you feel the glutes, not the hamstrings.',
      'Ribs down and lower back flat before you lift.',
      'Chin tucked slightly, arms at your sides.',
      'Weight through the heels.',
    ],
    steps: [
      'Squeeze the glutes first, then lift the hips.',
      'Rise until the hips are level between the knees and shoulders.',
      'Hold and squeeze for a second at the top.',
      'Lower under control without dropping onto the floor.',
    ],
    avoid: [
      'Arching the lower back to go higher.',
      'Pushing through the toes.',
      'Letting the knees fall in or out.',
    ],
    tempo: [
      'Lift for 1-2 seconds.',
      'Hold 1-2 seconds at the top.',
      'Lower for 2-3 seconds.',
    ],
  ),
  'good mornings': _ExerciseTechnique(
    photoTitle: 'Good mornings',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Light bar high on the back, feet hip width, knees softly bent. This is a hip hinge, not a squat, and it stays light.',
    hold: [
      'Bar settled on the upper back, never on the neck.',
      'Knees soft and fixed at that angle.',
      'Ribs down, lats tight, back flat.',
      'Start far lighter than your squat.',
    ],
    steps: [
      'Push the hips straight back and let the chest travel forward.',
      'Stop at a strong hamstring stretch, before the back rounds.',
      'Keep the shins close to vertical.',
      'Drive the hips forward to stand tall and squeeze the glutes.',
    ],
    avoid: [
      'Rounding the lower back to go lower.',
      'Bending the knees and turning it into a squat.',
      'Adding weight instead of adding control.',
    ],
    tempo: [
      'Lower for 3 seconds.',
      'Pause in the stretch.',
      'Stand up for 1-2 seconds.',
    ],
  ),

  'goblet squat': _ExerciseTechnique(
    photoTitle: 'Goblet squat',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Hold one dumbbell or kettlebell vertically against the chest with the elbows tucked under it. The weight at the front is what keeps the chest up.',
    hold: [
      'Weight held high against the chest, elbows underneath it.',
      'Feet shoulder width, toes turned slightly out.',
      'Ribs down and braced before the first rep.',
      'Whole foot flat on the floor.',
    ],
    steps: [
      'Sit straight down between the hips.',
      'Let the elbows travel inside the knees at the bottom.',
      'Go to the depth where the back stays flat and the heels stay down.',
      'Drive up through the mid-foot and squeeze the glutes at the top.',
    ],
    avoid: [
      'Letting the weight drift away from the chest.',
      'Heels lifting off the floor.',
      'Knees collapsing inward on the way up.',
    ],
    tempo: [
      'Lower for 2-3 seconds.',
      'Pause a beat at the bottom.',
      'Stand up for 1-2 seconds.',
    ],
  ),
  'cable pull-through': _ExerciseTechnique(
    photoTitle: 'Cable pull-through',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Face away from a low cable with the rope between your legs. This is a hip hinge: the arms only hold the rope, they never pull it.',
    hold: [
      'Rope held in both hands, arms straight and relaxed.',
      'Feet a little wider than the hips, knees soft.',
      'Far enough from the stack that there is tension at the top.',
      'Back flat, ribs down.',
    ],
    steps: [
      'Push the hips straight back and let the rope travel between the legs.',
      'Stop when you feel a strong hamstring stretch.',
      'Keep the shins near vertical and the back flat.',
      'Drive the hips forward and finish standing tall, glutes squeezed.',
    ],
    avoid: [
      'Pulling the rope with the arms.',
      'Bending the knees and turning it into a squat.',
      'Leaning back at the top and arching the lower back.',
    ],
    tempo: [
      'Hinge back for 2-3 seconds.',
      'Pause in the stretch.',
      'Drive the hips forward for 1 second and squeeze.',
    ],
  ),

  // --- Core ----------------------------------------------------------------
  'plank': _ExerciseTechnique(
    photoTitle: 'Plank',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Elbows under the shoulders, body in one line from ears to heels. Squeeze the glutes and pull the ribs down before the clock starts.',
    hold: [
      'Elbows directly under the shoulders.',
      'Forearms flat, hands relaxed.',
      'Glutes tight, ribs down, hips level with the shoulders.',
      'Neck neutral: look at the floor just past your hands.',
    ],
    steps: [
      'Set the position and brace before you start timing.',
      'Push the floor away so the upper back does not sag.',
      'Breathe normally through the hold.',
      'End the set when the hips start to drop, not at a number.',
    ],
    avoid: [
      'Letting the hips sag toward the floor.',
      'Piking the hips up to rest.',
      'Holding your breath.',
    ],
    tempo: [
      'Hold 20-60 seconds per set.',
      'Stop when the position breaks.',
      'Rest a full minute between holds.',
    ],
  ),
  'hanging knee raises': _ExerciseTechnique(
    photoTitle: 'Hanging knee raises',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Hang from the bar with straight arms and the shoulders pulled down. Curl the pelvis up rather than only lifting the knees.',
    hold: [
      'Full grip, or use straps or elbow supports.',
      'Shoulders pulled down away from the ears.',
      'Legs together, ribs down.',
      'Stop any swing before the first rep.',
    ],
    steps: [
      'Start hanging still with the legs long.',
      'Lift the knees toward the chest.',
      'At the top, curl the pelvis up so the lower back rounds slightly.',
      'Lower slowly until the body is still again.',
    ],
    avoid: [
      'Swinging and using momentum.',
      'Lifting only the knees with no pelvic tilt.',
      'Dropping fast and jerking the shoulders.',
    ],
    tempo: [
      'Lift for 1-2 seconds.',
      'Pause at the top.',
      'Lower for 3 seconds.',
    ],
  ),
  'cable crunches': _ExerciseTechnique(
    photoTitle: 'Cable crunches',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Kneel below a high cable, hold the rope beside your head, and crunch by rounding the spine. The hips stay still.',
    hold: [
      'Rope held at the sides of the head or on the forehead.',
      'Hips fixed at the same angle the whole set.',
      'Elbows stay in the same place relative to the head.',
      'Knees far enough back that the cable pulls you forward.',
    ],
    steps: [
      'Start tall with tension already on the cable.',
      'Crunch down by pulling the ribs toward the pelvis.',
      'Round the back on purpose: this is a spinal flexion exercise.',
      'Return under control until the abs stretch.',
    ],
    avoid: [
      'Hinging at the hips instead of crunching the ribs down.',
      'Pulling with the arms.',
      'Yanking on the neck.',
    ],
    tempo: [
      'Crunch for 1-2 seconds.',
      'Squeeze hard at the bottom.',
      'Return for 3 seconds.',
    ],
  ),
  'russian twists': _ExerciseTechnique(
    photoTitle: 'Russian twists',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Sit with the knees bent and the heels light on the floor, lean back to about 45 degrees, and rotate the ribs rather than only the arms.',
    hold: [
      'Lean back only as far as the back stays flat.',
      'Chest up, ribs down.',
      'A light plate or dumbbell held at chest height.',
      'Feet down while learning, lifted once it is easy.',
    ],
    steps: [
      'Brace the core in the lean-back position.',
      'Rotate the shoulders and ribs to one side.',
      'Touch the weight down near the hip.',
      'Rotate to the other side while the hips and knees stay forward.',
    ],
    avoid: [
      'Rounding the lower back as you lean.',
      'Swinging the arms while the torso stays still.',
      'Going fast enough to lose the brace.',
    ],
    tempo: [
      'About 1 second to each side.',
      'Pause briefly at each side.',
      'Keep breathing throughout.',
    ],
  ),
  'dead bug': _ExerciseTechnique(
    photoTitle: 'Dead bug',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Lie on your back with the arms straight up and the knees over the hips at 90 degrees. Flatten the lower back into the floor and keep it there.',
    hold: [
      'Lower back pressed flat to the floor: that is the whole exercise.',
      'Ribs down, not flared.',
      'Knees stacked over the hips.',
      'Breathe out slowly as you extend.',
    ],
    steps: [
      'Extend the opposite arm and leg away from each other.',
      'Reach only as far as the lower back stays flat.',
      'Return to the start under control.',
      'Swap sides and repeat.',
    ],
    avoid: [
      'Letting the lower back arch off the floor.',
      'Holding your breath.',
      'Moving quickly: slow reps are what make this work.',
    ],
    tempo: [
      'Extend for 2-3 seconds.',
      'Pause at full reach.',
      'Return for 2-3 seconds.',
    ],
  ),

  // --- Cardio --------------------------------------------------------------
  'incline treadmill walk': _ExerciseTechnique(
    photoTitle: 'Incline treadmill walk',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Pick a walking speed you can hold for the whole session, then raise the incline until it is hard but you can still talk.',
    hold: [
      'Hands off the rails, light fingertips only for balance.',
      'Stand tall, do not lean back away from the belt.',
      'Full foot strike, heel through to toe.',
      'Around 4.5-6 km/h at 8-15 percent incline is a starting range.',
    ],
    steps: [
      'Warm up 3 minutes flat and easy.',
      'Raise the incline to your working level.',
      'Hold one steady pace for 20-40 minutes.',
      'Drop the incline for the last 3 minutes to cool down.',
    ],
    avoid: [
      'Gripping the rails, which removes most of the work.',
      'Running when the session calls for a walk.',
      'An incline so steep that the posture collapses.',
    ],
    tempo: [
      'Keep the effort conversational.',
      'One steady pace, no surges.',
      'Breathe through the nose where you can.',
    ],
  ),
  'rowing machine intervals': _ExerciseTechnique(
    photoTitle: 'Rowing machine intervals',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Strap the feet so the strap crosses the ball of the foot. Every stroke is legs, then body, then arms, and the exact reverse coming back.',
    hold: [
      'Damper around 4-6 for most people.',
      'Shins vertical at the catch, shoulders in front of the hips.',
      'Light grip on the handle, wrists flat.',
      'Back flat and chest up through the whole stroke.',
    ],
    steps: [
      'Drive with the legs first while the arms stay straight.',
      'Once the legs are nearly down, swing the torso back slightly.',
      'Finish by pulling the handle to the bottom of the ribs.',
      'Come forward in reverse: arms, then body, then legs.',
    ],
    avoid: [
      'Pulling with the arms before the legs have driven.',
      'Rounding the back at the catch.',
      'Rushing the recovery, which should be slower than the drive.',
    ],
    tempo: [
      'Drive fast, recover slow, about one to two.',
      'Intervals of 30-60 seconds hard and 60-90 seconds easy.',
      'End the set when the stroke gets sloppy.',
    ],
  ),
  'cycling intervals': _ExerciseTechnique(
    photoTitle: 'Cycling intervals',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Set the saddle so the knee stays slightly bent at the bottom of the stroke. Make the intervals hard with resistance, not only speed.',
    hold: [
      'Saddle height: a slight knee bend at the bottom.',
      'Relaxed grip, soft elbows, shoulders down.',
      'Knees tracking straight over the feet.',
      'Smooth pressure all the way around the circle.',
    ],
    steps: [
      'Spin easy for 5 minutes to warm up.',
      'Raise the resistance and work hard for 30-60 seconds.',
      'Drop back to easy spinning for 60-120 seconds.',
      'Repeat 6-10 rounds, then spin easy for 5 minutes.',
    ],
    avoid: [
      'A saddle so low that the knees ache.',
      'Bouncing in the seat at high cadence.',
      'Making every interval a maximum effort.',
    ],
    tempo: [
      'Hard efforts stay strong but controlled.',
      'Recoveries stay genuinely easy.',
      'Keep the cadence smooth, around 80-100 rpm.',
    ],
  ),
  'stair climber': _ExerciseTechnique(
    photoTitle: 'Stair climber',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Stand tall, take full steps, and let go of the rails. Fingertip contact only, and only if you need the balance.',
    hold: [
      'Upright posture, ribs stacked over the hips.',
      'Whole foot on each step, not just the toes.',
      'Fingertips on the rail at most.',
      'A pace you can hold for the whole session.',
    ],
    steps: [
      'Start at an easy level for 3 minutes.',
      'Raise the level until talking is difficult but possible.',
      'Take full steps and drive through the heel.',
      'Ease back down for the last 3 minutes.',
    ],
    avoid: [
      'Leaning your body weight on the handrails.',
      'Taking tiny half steps.',
      'Letting the hips sag back and the back round.',
    ],
    tempo: [
      'Keep an even step rate.',
      'Drive through the heel each step.',
      'Breathe in rhythm with the steps.',
    ],
  ),

  // --- Recovery ------------------------------------------------------------
  'foam rolling': _ExerciseTechnique(
    photoTitle: 'Foam rolling',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'Roll slowly over muscle, never over a joint or the lower back. On a tender spot, stop and breathe until it eases.',
    hold: [
      'Support your weight with the hands and the free leg.',
      'Muscle only: quads, hamstrings, calves, glutes, upper back.',
      'Keep the breathing slow and steady.',
      'Pressure should be uncomfortable, never sharp.',
    ],
    steps: [
      'Pick one muscle and roll slowly along its length.',
      'Spend 30-60 seconds on each area.',
      'Stop on a tender point and breathe for 20-30 seconds.',
      'Gently move the nearby joint while holding that spot.',
    ],
    avoid: [
      'Rolling directly over the lower back or any joint.',
      'Rolling fast back and forth.',
      'Pushing into sharp or nerve-like pain.',
    ],
    tempo: [
      'Move about one inch per second.',
      'Pause on the tender spots.',
      'Keep the breathing slow.',
    ],
  ),
  'hip and shoulder mobility flow': _ExerciseTechnique(
    photoTitle: 'Hip and shoulder mobility flow',
    photoCredit: 'RoutineSync coaching notes',
    setup:
        'A short easy sequence for the two joints that limit most lifts. Work the range you already own and repeat it rather than forcing it.',
    hold: [
      'Warm first: walk or cycle for a few minutes.',
      'Move slowly into each position.',
      'Stop at the first firm resistance, not at pain.',
      'Keep breathing in every position.',
    ],
    steps: [
      'Hips: 5 slow 90/90 rotations each side, then 5 deep squat holds.',
      'Hips: 8 half-kneeling lunge stretches each side, squeezing the back glute.',
      'Shoulders: 10 slow arm circles, then 10 wall slides.',
      'Shoulders: 8 thread-the-needle rotations each side.',
    ],
    avoid: [
      'Bouncing into a stretch.',
      'Holding your breath.',
      'Chasing range on a cold joint.',
    ],
    tempo: [
      'Take 2-3 seconds into each position.',
      'Hold 2-3 breaths where it is tightest.',
      'Run the whole round through twice.',
    ],
  ),
};
