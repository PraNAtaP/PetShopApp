import 'package:flutter/material.dart';
import 'package:petshopapp/services/firestore_service.dart';

class GradientSelector extends StatelessWidget {
  final Function(List<Color>) onSelect;

  const GradientSelector({
    super.key,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [Colors.blue.shade800, Colors.blue.shade400],
      [Colors.green.shade700, Colors.green.shade300],
      [Colors.purple.shade700, Colors.purple.shade300],
      [Colors.orange.shade700, Colors.orange.shade300],
      [Colors.teal.shade700, Colors.teal.shade300],
       ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: gradients.map((gradient) {
        return GestureDetector(
          onTap: () => onSelect(gradient),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradient,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}