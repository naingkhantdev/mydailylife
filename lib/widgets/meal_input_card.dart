import 'package:flutter/material.dart';

import '../models/daily_log_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class MealInputCard extends StatefulWidget {
  const MealInputCard({
    super.key,
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<MealItem> items;
  final ValueChanged<MealItem> onAdd;
  final ValueChanged<int> onRemove;

  @override
  State<MealInputCard> createState() => _MealInputCardState();
}

class _MealInputCardState extends State<MealInputCard> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealTotal = widget.items.fold<int>(
      0,
      (total, item) => total + item.totalCalories,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  _iconForMeal(widget.title),
                  color: AppColors.coral,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$mealTotal kcal',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _calorieController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'kcal',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add food',
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (widget.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (var i = 0; i < widget.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.items[i].name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.items[i].quantity}x · ${widget.items[i].totalCalories} kcal',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove food',
                      onPressed: () => widget.onRemove(i),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mutedText,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _iconForMeal(String title) {
    final name = title.toLowerCase();
    if (name.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (name.contains('lunch')) return Icons.lunch_dining_rounded;
    if (name.contains('dinner')) return Icons.dinner_dining_rounded;
    return Icons.restaurant_rounded;
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_calorieController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    if (name.isEmpty || calories == null || calories <= 0 || quantity <= 0) {
      return;
    }

    widget.onAdd(
      MealItem(name: name, calories: calories, quantity: quantity),
    );
    _nameController.clear();
    _calorieController.clear();
    _quantityController.text = '1';
  }
}
