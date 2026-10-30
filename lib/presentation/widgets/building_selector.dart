import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';

class BuildingSelector extends StatelessWidget {
  const BuildingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const buildings = ['FIE', 'Ciencias Básicas'];

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final building in buildings) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(building),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: value == building
                      ? AppColors.fieBlue
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value == building
                        ? AppColors.fieBlue
                        : AppColors.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      building == 'FIE' ? Icons.memory : Icons.science_outlined,
                      color: value == building
                          ? AppColors.gold
                          : AppColors.fieBlue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      building,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value == building
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (building != buildings.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
