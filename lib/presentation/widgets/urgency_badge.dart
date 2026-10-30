import 'package:flutter/material.dart';

import '../../data/report_model.dart';

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.urgency});

  final Urgency urgency;

  @override
  Widget build(BuildContext context) {
    final color = switch (urgency) {
      Urgency.baja => const Color(0xFF25815B),
      Urgency.media => const Color(0xFFB7790A),
      Urgency.alta => const Color(0xFFC63F43),
    };
    final label = switch (urgency) {
      Urgency.baja => 'Baja',
      Urgency.media => 'Media',
      Urgency.alta => 'Alta',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
