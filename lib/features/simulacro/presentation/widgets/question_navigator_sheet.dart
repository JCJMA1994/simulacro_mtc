import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exam_session.dart';

class QuestionNavigatorSheet extends StatelessWidget {
  const QuestionNavigatorSheet({
    super.key,
    required this.sesion,
    required this.onSelectQuestion,
    required this.onFinishExam,
  });

  final ExamSession sesion;
  final ValueChanged<int> onSelectQuestion;
  final VoidCallback onFinishExam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Navegación de Preguntas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Resumen de estado (Leyenda)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: AppColors.primary,
                  label: 'Respondidas (${sesion.respondidas})',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _LegendItem(
                  color: AppColors.warning,
                  label: 'Marcadas (${sesion.respuestas.values.where((r) => r.marcada).length})',
                  icon: Icons.bookmark_rounded,
                ),
                _LegendItem(
                  color: AppColors.textSecondary,
                  label: 'Pendientes (${sesion.preguntas.length - sesion.respondidas})',
                  icon: Icons.radio_button_unchecked_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),

            // Grilla de preguntas
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: List.generate(sesion.preguntas.length, (index) {
                    final pregunta = sesion.preguntas[index];
                    final respuesta = sesion.respuestas[pregunta.id];
                    final estaRespondida = respuesta?.respondida ?? false;
                    final estaMarcada = respuesta?.marcada ?? false;
                    final esActual = sesion.indiceActual == index;

                    Color backgroundColor = AppColors.background;
                    Color textColor = AppColors.textPrimary;
                    BorderSide borderSide = const BorderSide(color: AppColors.border);

                    if (esActual) {
                      borderSide = const BorderSide(color: AppColors.primary, width: 2);
                    }

                    if (estaRespondida) {
                      backgroundColor = AppColors.primary;
                      textColor = Colors.white;
                    }

                    return SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Material(
                              color: backgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: borderSide,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onSelectQuestion(index);
                                },
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (estaMarcada)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bookmark_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onFinishExam();
              },
              child: const Text('Finalizar y Calificar Examen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
