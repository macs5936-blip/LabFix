import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';
import '../../data/report_model.dart';
import 'urgency_badge.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, this.onTap});

  final IncidentReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Colores según estado: Pendiente (Amarillo/Naranja), En revisión (Azul), Resuelto (Verde)
    final statusColor = report.statusColor;
    final hasImages = report.hasEvidence || report.imageUrls.isNotEmpty;
    final hasNotes = report.resolutionNotes != null && report.resolutionNotes!.isNotEmpty;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.line.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.fieBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.building,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.fieBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.laboratory,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  UrgencyBadge(urgency: report.urgency),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    'Equipo ${report.machine}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Text(' · ', style: TextStyle(color: AppColors.muted)),
                  Text(
                    formatReportDate(report.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (hasImages) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.photo_camera_outlined,
                      size: 13,
                      color: AppColors.muted,
                    ),
                  ],
                  if (hasNotes) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.task_alt_outlined,
                      size: 13,
                      color: AppColors.green,
                    ),
                  ],
                ],
              ),
              if (report.category != null) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    report.category!,
                    style: const TextStyle(
                      color: AppColors.fieBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          report.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report.id,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
