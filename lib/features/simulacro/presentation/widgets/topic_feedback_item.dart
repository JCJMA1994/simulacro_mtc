import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/topic_feedback.dart';

class TopicFeedbackItem extends StatelessWidget {
  const TopicFeedbackItem({
    super.key,
    required this.feedback,
  });

  final TopicFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final (Color color, String nivelTexto, IconData icon) = switch (feedback.nivel) {
      NivelDominio.solido => (
          AppColors.success,
          'Sólido',
          Icons.check_circle_rounded,
        ),
      NivelDominio.enRiesgo => (
          AppColors.warning,
          'En riesgo',
          Icons.warning_amber_rounded,
        ),
      NivelDominio.critico => (
          AppColors.error,
          'Crítico',
          Icons.error_outline_rounded,
        ),
    };

    final porcentaje = (feedback.dominio * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feedback.topicoNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        nivelTexto,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de progreso del tópico
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: feedback.dominio,
                minHeight: 8,
                backgroundColor: AppColors.border.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${feedback.correctas}/${feedback.total} aciertos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$porcentaje%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
