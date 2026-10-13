import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/daily_log_model.dart';
import '../providers/food_dictionary_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';

class FoodManagerModal extends ConsumerStatefulWidget {
  const FoodManagerModal({
    super.key,
    required this.mealSlot,
    required this.onAddToMeal,
  });

  final MealSlot mealSlot;
  final ValueChanged<MealItem> onAddToMeal;

  @override
  ConsumerState<FoodManagerModal> createState() => _FoodManagerModalState();
}

class _FoodManagerModalState extends ConsumerState<FoodManagerModal> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  MealItem? _editingFood;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _calorieController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodDictionaryProvider);
    final filteredFoods = foods
        .where((food) => food.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

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
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.strings.slotFood(widget.mealSlot),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: context.strings.searchExistingFood,
                ),
              ),
              const SizedBox(height: 14),
              _FoodEditor(
                editingFood: _editingFood,
                foods: foods,
                nameController: _nameController,
                calorieController: _calorieController,
                onCancel: _clearEditor,
                onSave: _saveFood,
              ),
              const SizedBox(height: 16),
              Text(
                context.strings.existingFoods,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (filteredFoods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(context.strings.noFoodsFound),
                )
              else
                for (final food in filteredFoods) _FoodRow(
                  food: food,
                  onAdd: () => _showQuantityDialog(food),
                  onEdit: () => _startEdit(food),
                  onDelete: () => _deleteFood(food),
                ),
            ],
          );
        },
      ),
    );
  }

  void _startEdit(MealItem food) {
    setState(() {
      _editingFood = food;
      _nameController.text = food.name;
      _calorieController.text = food.calories.toString();
    });
  }

  void _saveFood() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_calorieController.text.trim());

    // Explain the rejection rather than ignoring the tap.
    if (name.isEmpty) {
      _showProblem(context.strings.enterFoodNameFirst);
      return;
    }
    if (calories == null || calories <= 0) {
      _showProblem(context.strings.enterCaloriesNumber);
      return;
    }

    ref.read(foodDictionaryProvider.notifier).upsert(
          MealItem(name: name, calories: calories),
          previousName: _editingFood?.name,
        );
    _clearEditor();
  }

  void _showProblem(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showQuantityDialog(MealItem food) async {
    _quantityController.text = '1';
    final strings = context.strings;
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.addNamed(food.name)),
          content: TextField(
            controller: _quantityController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.quantity,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  int.tryParse(_quantityController.text.trim()),
                );
              },
              child: Text(strings.add),
            ),
          ],
        );
      },
    );

    if (quantity != null && quantity > 0) {
      widget.onAddToMeal(food.copyWith(quantity: quantity));
    }
  }

  /// Confirmed, like the routine and technique managers. This was the only
  /// delete in the app that removed data on a single tap with no undo.
  Future<void> _deleteFood(MealItem food) async {
    final strings = context.strings;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteFoodTitle),
        content: Text(strings.deleteFoodBody(food.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.delete,
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    ref.read(foodDictionaryProvider.notifier).delete(food.name);
    if (_editingFood?.name == food.name) {
      _clearEditor();
    }
  }

  void _clearEditor() {
    setState(() {
      _editingFood = null;
      _nameController.clear();
      _calorieController.clear();
    });
  }
}

class _FoodEditor extends StatelessWidget {
  const _FoodEditor({
    required this.editingFood,
    required this.foods,
    required this.nameController,
    required this.calorieController,
    required this.onCancel,
    required this.onSave,
  });

  final MealItem? editingFood;
  final List<MealItem> foods;
  final TextEditingController nameController;
  final TextEditingController calorieController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editingFood == null
                ? context.strings.createFood
                : context.strings.editFood,
            style: TextStyle(
              color: palette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  onChanged: _fillCaloriesFromSavedFood,
                  decoration: InputDecoration(
                    labelText: context.strings.food,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: calorieController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'kcal',
                    helperText: context.strings.autoFilled,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (editingFood != null)
                TextButton(
                  onPressed: onCancel,
                  child: Text(context.strings.cancel),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSave,
                icon: Icon(editingFood == null ? Icons.add : Icons.save),
                label: Text(
                  editingFood == null
                      ? context.strings.saveFood
                      : context.strings.save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _fillCaloriesFromSavedFood(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      return;
    }

    MealItem? match;
    for (final food in foods) {
      final foodName = food.name.toLowerCase();
      if (foodName == query || foodName.contains(query)) {
        match = food;
        break;
      }
    }

    if (match != null) {
      calorieController.text = match.calories.toString();
    }
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final MealItem food;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(food.name),
      subtitle: Text('${food.calories} kcal'),
      leading: IconButton.filled(
        tooltip: context.strings.addToMeal,
        onPressed: onAdd,
        icon: const Icon(Icons.add),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.strings.editFood,
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
          // Edit and Delete sat flush against each other; 8px keeps the two
          // 48px targets from reading as one control.
          const SizedBox(width: 8),
          IconButton(
            tooltip: context.strings.deleteFood,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: context.palette.danger,
            ),
          ),
        ],
      ),
    );
  }
}
