import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../simulacro/domain/entities/question.dart';

class StudyQuestionCard extends StatefulWidget {
  const StudyQuestionCard({
    super.key,
    required this.pregunta,
    required this.indiceLista,
  });

  final Question pregunta;
  final int indiceLista;

  @override
  State<StudyQuestionCard> createState() => _StudyQuestionCardState();
}

class _StudyQuestionCardState extends State<StudyQuestionCard> {
  int? _opcionSeleccionada;
  bool _mostrarRespuesta = false;

  static const List<String> _letrasOpciones = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final pregunta = widget.pregunta;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pregunta #${pregunta.numero}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
            const SizedBox(height: 12),

            // Enunciado
            Text(
              pregunta.enunciado,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Imagen si existe
            if (pregunta.imagenAsset != null) ...[
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    pregunta.imagenAsset!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Opciones de estudio
            ...List.generate(pregunta.opciones.length, (opIndex) {
              final letra = opIndex < _letrasOpciones.length
                  ? _letrasOpciones[opIndex]
                  : '$opIndex';
              final textoOpcion = pregunta.opciones[opIndex];
              final esLaCorrecta = opIndex == pregunta.indiceCorrecto;
              final fueSeleccionada = _opcionSeleccionada == opIndex;

              Color? bgColor;
              Color borderColor = AppColors.border;
              Widget? iconState;

              if (_mostrarRespuesta || _opcionSeleccionada != null) {
                if (esLaCorrecta) {
                  bgColor = AppColors.success.withValues(alpha: 0.12);
                  borderColor = AppColors.success;
                  iconState = const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  );
                } else if (fueSeleccionada) {
                  bgColor = AppColors.error.withValues(alpha: 0.1);
                  borderColor = AppColors.error;
                  iconState = const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.error,
                    size: 18,
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _opcionSeleccionada = opIndex;
                      _mostrarRespuesta = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor ?? AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_mostrarRespuesta && esLaCorrecta)
                                ? AppColors.success
                                : (_opcionSeleccionada == opIndex
                                    ? AppColors.error
                                    : AppColors.surface),
                            border: Border.all(
                              color: (_mostrarRespuesta && esLaCorrecta)
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letra,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (_mostrarRespuesta &&
                                        (esLaCorrecta || fueSeleccionada))
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            textoOpcion,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (_mostrarRespuesta && esLaCorrecta)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (iconState != null) ...[
                          const SizedBox(width: 6),
                          iconState,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Explicación / Base Legal
            if ((_mostrarRespuesta || _opcionSeleccionada != null) &&
                pregunta.explicacion != null &&
                pregunta.explicacion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pregunta.explicacion!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón para revelar respuesta directa
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _mostrarRespuesta = !_mostrarRespuesta;
                  });
                },
                icon: Icon(
                  _mostrarRespuesta
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  _mostrarRespuesta ? 'Ocultar solución' : 'Ver solución oficial',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
