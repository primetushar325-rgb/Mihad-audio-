import 'package:flutter/material.dart';

import '../app/theme.dart';

const List<int> kMihadColorPalette = [
  0xFF00E5A8,
  0xFF6C5CE7,
  0xFFFF6B6B,
  0xFFFFD166,
  0xFF4D96FF,
  0xFFFF4FD8,
  0xFF00D2FF,
  0xFFFFFFFF,
  0xFFB8FF00,
  0xFFFF8A00,
  0xFF8E44AD,
  0xFF1ABC9C,
];

/// Opens a bottom sheet with a curated color palette and returns the
/// chosen ARGB color value, or null if dismissed.
Future<int?> showMihadColorPicker(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: MihadColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: kMihadColorPalette.map((value) {
                final selected = value == current;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(value),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}
