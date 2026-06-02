import 'package:flutter/material.dart';
import 'package:petshopapp/services/firestore_service.dart';

class EmojiSelector extends StatelessWidget {
  final Function(String) onSelect;

  const EmojiSelector({
    super.key,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final emojis = [
      '🐱',
      '😺',
      '😸',
      '😻',
      '🐶',
      '🐕',
      '🦴',
      '🐾',
      '😹',
      '🙀',
      '🐈',
      '🐕‍🦺',
    ];
     return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: emojis.map((e) {
        return GestureDetector(
          onTap: () => onSelect(e),
          child: CircleAvatar(
            radius: 28,
            child: Text(
              e,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      }).toList(),
    );
  }
}