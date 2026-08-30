import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/exam_session.dart';

enum _FiltroRevision { todas, incorrectas, correctas, marcadas }

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.sesion,
    required this.resultado,
  });

  final ExamSession sesion;
  final ExamResult resultado;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  _FiltroRevision _filtro = _FiltroRevision.todas;

  static const List<String> _letrasOpciones = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final preguntasFiltradas = widget.sesion.preguntas.where((p) {
      final respuesta = widget.sesion.respuestas[p.id];
      final esCorrecta = respuesta?.esCorrecta ?? false;
      final esMarcada = respuesta?.marcada ?? false;

      return switch (_filtro) {
        _FiltroRevision.todas => true,
        _FiltroRevision.incorrectas => !esCorrecta,
        _FiltroRevision.correctas => esCorrecta,
        _FiltroRevision.marcadas => esMarcada,
      };
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Revisión de Examen'),
      ),
      body: Column(
        children: [
          // Barra de Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas (${widget.sesion.preguntas.length})',
                  selected: _filtro == _FiltroRevision.todas,
                  onTap: () => setState(() => _filtro = _FiltroRevision.todas),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Incorrectas (${widget.resultado.preguntasFalladasIds.length})',
                  selected: _filtro == _FiltroRevision.incorrectas,
                  color: AppColors.error,
                  onTap: () => setState(() => _filtro = _FiltroRevision.incorrectas),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Correctas (${widget.resultado.correctas})',
                  selected: _filtro == _FiltroRevision.correctas,
                  color: AppColors.success,
                  onTap: () => setState(() => _filtro = _FiltroRevision.correctas),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Marcadas',
                  selected: _filtro == _FiltroRevision.marcadas,
                  color: AppColors.warning,
                  onTap: () => setState(() => _filtro = _FiltroRevision.marcadas),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Lista de preguntas revisadas
          Expanded(
            child: preguntasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay preguntas para este filtro.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: preguntasFiltradas.length,
                    itemBuilder: (context, index) {
                      final pregunta = preguntasFiltradas[index];
                      final numeroReal = widget.sesion.preguntas.indexOf(pregunta) + 1;
                      final respuesta = widget.sesion.respuestas[pregunta.id];
                      final indiceElegido = respuesta?.indiceElegido;
                      final esCorrecta = respuesta?.esCorrecta ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header de la tarjeta
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: esCorrecta
                                          ? AppColors.success.withValues(alpha: 0.1)
                                          : AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          esCorrecta
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          size: 14,
                                          color: esCorrecta
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pregunta $numeroReal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: esCorrecta
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      pregunta.topicoCodigo,
                                      style: const TextStyle(
                                        fontSize: 10,
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

                              // Imagen si tiene
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
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Opciones
                              ...List.generate(pregunta.opciones.length, (opIndex) {
                                final letra = opIndex < _letrasOpciones.length
                                    ? _letrasOpciones[opIndex]
                                    : '$opIndex';
                                final textoOpcion = pregunta.opciones[opIndex];
                                final esLaCorrecta =
                                    opIndex == pregunta.indiceCorrecto;
                                final esLaElegida = opIndex == indiceElegido;

                                Color? bgColor;
                                Color borderColor = AppColors.border;
                                Widget? estadoIcon;

                                if (esLaCorrecta) {
                                  bgColor = AppColors.success.withValues(alpha: 0.1);
                                  borderColor = AppColors.success;
                                  estadoIcon = const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  );
                                } else if (esLaElegida && !esCorrecta) {
                                  bgColor = AppColors.error.withValues(alpha: 0.1);
                                  borderColor = AppColors.error;
                                  estadoIcon = const Icon(
                                    Icons.cancel_rounded,
                                    color: AppColors.error,
                                    size: 18,
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: bgColor ?? AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: esLaCorrecta
                                              ? AppColors.success
                                              : (esLaElegida
                                                  ? AppColors.error
                                                  : AppColors.surface),
                                          border: Border.all(
                                            color: esLaCorrecta
                                                ? AppColors.success
                                                : (esLaElegida
                                                    ? AppColors.error
                                                    : AppColors.border),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            letra,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: (esLaCorrecta || esLaElegida)
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
                                            fontWeight: (esLaCorrecta || esLaElegida)
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (estadoIcon != null) ...[
                                        const SizedBox(width: 8),
                                        estadoIcon,
                                      ],
                                    ],
                                  ),
                                );
                              }),

                              // Explicación o Base Legal si existe
                              if (pregunta.explicacion != null &&
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
                                      const Icon(
                                        Icons.gavel_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Base legal / Explicación: ${pregunta.explicacion}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
