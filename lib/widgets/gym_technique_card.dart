import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';

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
    final session = ref.watch(gymSessionProvider);
    final sessionController = ref.read(gymSessionProvider.notifier);
    final isWorkoutDone =
        sessionController.isWorkoutComplete(widget.gymDay.exercises);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.gymDay.title} technique',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(
                isWorkoutDone
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: isWorkoutDone
                    ? const Color(0xFF166534)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.gymDay.focus,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          for (final exercise in widget.gymDay.exercises) ...[
            _TechniqueRow(
              exercise: exercise,
              session: session[exercise] ??
                  sessionController.sessionFor(exercise),
              onToggleSet: (setNumber) {
                ref
                    .read(gymSessionProvider.notifier)
                    .toggleSet(exercise, setNumber);
              },
              onSetTarget: (sets, reps) {
                ref.read(gymSessionProvider.notifier).setTarget(
                      exercise: exercise,
                      sets: sets,
                      reps: reps,
                    );
              },
              onMarkDone: () {
                ref.read(gymSessionProvider.notifier).markExerciseDone(
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

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({
    required this.exercise,
    required this.session,
    required this.onToggleSet,
    required this.onSetTarget,
    required this.onMarkDone,
  });

  final String exercise;
  final GymExerciseSession session;
  final ValueChanged<int> onToggleSet;
  final void Function(int sets, int reps) onSetTarget;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final isDone = session.completedSets.length >= session.targetSets;
    final technique = _ExerciseTechnique.forExercise(exercise);

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: technique.photoUrl == null
                  ? Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.fitness_center, size: 18),
                    )
                  : Image.network(
                      technique.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 18,
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
                InkWell(
                  onTap: () => _openTechniqueDetail(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _cueFor(exercise),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _openTargetDialog(context),
                      child: Row(
                        children: [
                          Text(
                            '${session.targetSets} x ${session.targetReps}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 15),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (var setNumber = 1;
                        setNumber <= session.targetSets;
                        setNumber++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => onToggleSet(setNumber),
                          child: Icon(
                            session.completedSets.contains(setNumber)
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 22,
                            color: session.completedSets.contains(setNumber)
                                ? const Color(0xFF166534)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: isDone ? null : onMarkDone,
                      child: const Text('All done'),
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
      builder: (context) => _TechniqueDetailSheet(exercise: exercise),
    );
  }

  Future<void> _openTargetDialog(BuildContext context) async {
    final setsController = TextEditingController(
      text: session.targetSets.toString(),
    );
    final repsController = TextEditingController(
      text: session.targetReps.toString(),
    );

    final result = await showDialog<({int sets, int reps})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set target'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
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
              onPressed: () {
                final sets = int.tryParse(setsController.text.trim());
                final reps = int.tryParse(repsController.text.trim());
                if (sets == null || reps == null) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop((sets: sets, reps: reps));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    setsController.dispose();
    repsController.dispose();

    if (result != null) {
      onSetTarget(result.sets, result.reps);
    }
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

class _TechniqueDetailSheet extends StatefulWidget {
  const _TechniqueDetailSheet({required this.exercise});

  final String exercise;

  @override
  State<_TechniqueDetailSheet> createState() => _TechniqueDetailSheetState();
}

class _TechniqueDetailSheetState extends State<_TechniqueDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final type = _ExerciseTechnique.forExercise(widget.exercise);

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. '),
                Expanded(child: Text(items[i])),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 6),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                technique.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            technique.photoTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(technique.setup),
          if (technique.benchAngle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.straighten, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bench angle: ${technique.benchAngle}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            technique.photoCredit,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
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
    return const Text(
      'Use a weight you can control for your chosen sets and reps. Stop if pain, dizziness, numbness, or joint pinching happens. For heavy bench, squat, or overhead work, use safety pins or a spotter.',
      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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

  factory _ExerciseTechnique.forExercise(String exercise) {
    final name = exercise.toLowerCase();
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
