import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../providers/food_dictionary_provider.dart';

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
                      '${_slotLabel(widget.mealSlot)} food',
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
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search existing food',
                  border: OutlineInputBorder(),
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
                'Existing foods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (filteredFoods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No foods found. Create one above.'),
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
    if (name.isEmpty || calories == null || calories <= 0) {
      return;
    }

    ref.read(foodDictionaryProvider.notifier).upsert(
          MealItem(name: name, calories: calories),
          previousName: _editingFood?.name,
        );
    _clearEditor();
  }

  Future<void> _showQuantityDialog(MealItem food) async {
    _quantityController.text = '1';
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${food.name}'),
          content: TextField(
            controller: _quantityController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  int.tryParse(_quantityController.text.trim()),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (quantity != null && quantity > 0) {
      widget.onAddToMeal(food.copyWith(quantity: quantity));
    }
  }

  void _deleteFood(MealItem food) {
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

  String _slotLabel(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.dinner:
        return 'Dinner';
    }
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editingFood == null ? 'Create food' : 'Edit food',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  onChanged: _fillCaloriesFromSavedFood,
                  decoration: const InputDecoration(
                    labelText: 'Food',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'kcal auto-filled',
                    border: OutlineInputBorder(),
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
                  child: const Text('Cancel'),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSave,
                icon: Icon(editingFood == null ? Icons.add : Icons.save),
                label: Text(editingFood == null ? 'Save food' : 'Save'),
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
        tooltip: 'Add to meal',
        onPressed: onAdd,
        icon: const Icon(Icons.add),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit food',
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete food',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
