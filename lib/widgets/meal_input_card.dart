import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/daily_log_model.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/number_format.dart';

class MealInputCard extends StatefulWidget {
  const MealInputCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;

  /// Passed in rather than guessed from [title]: the title is translated, so
  /// matching "breakfast" in it only ever worked in English.
  final IconData icon;
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.palette.border),
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
                  color: context.palette.coralSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  widget.icon,
                  color: context.palette.coral,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$mealTotal kcal',
                style: TextStyle(
                  color: context.palette.mutedText,
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
              // 5/3/2: field width should telegraph the expected input. Qty
              // holds "1", kcal holds "1200" — they were the same width.
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.strings.food,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
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
                  decoration: InputDecoration(
                    labelText: context.strings.qty,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: context.strings.addFood,
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
                      decoration: BoxDecoration(
                        color: context.palette.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.items[i].name,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.items[i].quantity}x · '
                      '${formatCount(widget.items[i].totalCalories)} kcal',
                      style: TextStyle(
                        color: context.palette.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: context.strings.removeFood,
                      onPressed: () => widget.onRemove(i),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.palette.mutedText,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_calorieController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;

    // Say why nothing happened. A silent return on a tapped button reads as a
    // broken app.
    if (name.isEmpty) {
      _showProblem(context.strings.enterFoodNameFirst);
      return;
    }
    if (calories == null || calories <= 0) {
      _showProblem(context.strings.enterCaloriesNumber);
      return;
    }
    if (quantity <= 0) {
      _showProblem(context.strings.quantityAtLeastOne);
      return;
    }

    widget.onAdd(
      MealItem(name: name, calories: calories, quantity: quantity),
    );
    _nameController.clear();
    _calorieController.clear();
    _quantityController.text = '1';
  }

  void _showProblem(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
