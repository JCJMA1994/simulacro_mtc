import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exam_answer.dart';
import '../../domain/entities/question.dart';

class QuestionCardWidget extends StatelessWidget {
  const QuestionCardWidget({
    super.key,
    required this.pregunta,
    required this.numeroPregunta,
    required this.totalPreguntas,
    required this.respuesta,
    required this.onSelectOption,
  });

  final Question pregunta;
  final int numeroPregunta;
  final int totalPreguntas;
  final ExamAnswer? respuesta;
  final ValueChanged<int> onSelectOption;

  static const List<String> _letrasOpciones = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la pregunta: Número y Tópico
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pregunta $numeroPregunta de $totalPreguntas',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  pregunta.topicoCodigo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Enunciado
          Text(
            pregunta.enunciado,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Imagen de señal / diagrama si existe
          if (pregunta.imagenAsset != null) ...[
            Center(
              child: GestureDetector(
                onTap: () => _mostrarImagenGrande(context, pregunta.imagenAsset!),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180, maxWidth: 280),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      pregunta.imagenAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Opciones de respuesta (A, B, C, D)
          ...List.generate(pregunta.opciones.length, (index) {
            final letra = index < _letrasOpciones.length ? _letrasOpciones[index] : '$index';
            final textoOpcion = pregunta.opciones[index];
            final esSeleccionada = respuesta?.indiceElegido == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectOption(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: esSeleccionada
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: esSeleccionada ? AppColors.primary : AppColors.border,
                      width: esSeleccionada ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: esSeleccionada ? AppColors.primary : AppColors.background,
                          border: Border.all(
                            color: esSeleccionada ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            letra,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: esSeleccionada ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          textoOpcion,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: esSeleccionada ? FontWeight.w600 : FontWeight.w400,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _mostrarImagenGrande(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InteractiveViewer(
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
