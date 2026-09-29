import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.active({String label = 'Active'}) {
    return StatusBadge(
      label: label,
      textColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFFECFDF5),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  factory StatusBadge.blocked({String label = 'Blocked'}) {
    return StatusBadge(
      label: label,
      textColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFFFEF2F2),
      icon: Icons.block_rounded,
    );
  }

  factory StatusBadge.pending({String label = 'Pending'}) {
    return StatusBadge(
      label: label,
      textColor: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFFFFFBEB),
      icon: Icons.schedule_rounded,
    );
  }

  factory StatusBadge.resolved({String label = 'Resolved'}) {
    return StatusBadge(
      label: label,
      textColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFEFF6FF),
      icon: Icons.done_all_rounded,
    );
  }

  factory StatusBadge.custom({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return StatusBadge(
      label: label,
      textColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
