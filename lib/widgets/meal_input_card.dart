import 'package:flutter/material.dart';

import '../models/daily_log_model.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('$mealTotal kcal'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
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
                  controller: _calorieController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'kcal',
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add food',
                onPressed: _addItem,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (widget.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < widget.items.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(widget.items[i].name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.items[i].quantity}x ${widget.items[i].totalCalories} kcal',
                    ),
                    IconButton(
                      tooltip: 'Remove food',
                      onPressed: () => widget.onRemove(i),
                      icon: const Icon(Icons.close),
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
