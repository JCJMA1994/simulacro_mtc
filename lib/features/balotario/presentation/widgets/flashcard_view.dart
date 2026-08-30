import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../simulacro/domain/entities/question.dart';

class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.preguntas,
  });

  final List<Question> preguntas;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _revelada = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _revelarRespuesta() {
    HapticFeedback.lightImpact();
    setState(() {
      _revelada = !_revelada;
    });
  }

  void _siguiente() {
    if (_currentIndex < widget.preguntas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _anterior() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preguntas.isEmpty) {
      return const Center(
        child: Text(
          'No hay preguntas disponibles con los filtros actuales.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final total = widget.preguntas.length;

    return Column(
      children: [
        // Barra de progreso y contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarjeta ${_currentIndex + 1} de $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${((_currentIndex + 1) / total * 100).toInt()}% completado',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: AppColors.surfaceSubtle,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Área de tarjeta interactiva
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _revelada = false;
              });
            },
            itemBuilder: (context, index) {
              final p = widget.preguntas[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: GestureDetector(
                  onTap: _revelarRespuesta,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _revelada ? AppColors.primaryLight : AppColors.border,
                        width: _revelada ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_revelada ? AppColors.primary : Colors.black)
                              .withValues(alpha: _revelada ? 0.12 : 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header de la tarjeta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0EDFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Pregunta #${p.numero}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  p.topicoCodigo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Enunciado
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.enunciado,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (p.imagenAsset != null) ...[
                                    const SizedBox(height: 14),
                                    Center(
                                      child: Container(
                                        constraints: const BoxConstraints(maxHeight: 120),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Image.asset(
                                          p.imagenAsset!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),

                                  // Respuesta revelada o botón de tocar para ver
                                  if (!_revelada)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.border, style: BorderStyle.solid),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.touch_app_rounded,
                                              size: 18, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tocá la tarjeta para ver la respuesta oficial',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    const Text(
                                      'Respuesta Correcta:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_circle_rounded,
                                              color: Color(0xFF16A34A), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              p.opciones[p.indiceCorrecto],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF166534),
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (p.explicacion.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Base legal / Explicación: ${p.explicacion}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Botones de navegación inferior
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _currentIndex > 0 ? _anterior : null,
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  label: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _currentIndex < total - 1 ? _siguiente : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  label: const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
