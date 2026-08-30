import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/exam_session.dart';
import '../widgets/topic_feedback_item.dart';
import 'review_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.resultado,
    required this.sesion,
    required this.onRestart,
  });

  final ExamResult resultado;
  final ExamSession sesion;
  final VoidCallback onRestart;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.resultado.aprobado) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  String _formatearTiempo(Duration duracion) {
    final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos min';
  }

  @override
  Widget build(BuildContext context) {
    final resultado = widget.resultado;
    final sesion = widget.sesion;
    final onRestart = widget.onRestart;
    final aprobado = resultado.aprobado;
    final colorResultado = aprobado ? AppColors.success : AppColors.error;
    final iconoResultado = aprobado ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final puntoDebil = resultado.puntoDebil;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Resultado del Simulacro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cerrar y salir',
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Tarjeta Principal de Puntaje y Veredicto
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorResultado.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorResultado.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorResultado.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconoResultado,
                      color: colorResultado,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    aprobado
                        ? '¡Aprobaste el simulacro!'
                        : 'Te faltaron ${resultado.faltantes} ${resultado.faltantes == 1 ? "respuesta" : "respuestas"} para aprobar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorResultado,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría ${resultado.categoriaCodigo}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Métricas de aciertos, mínimo y tiempo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricTile(
                        titulo: 'Puntaje Obtenido',
                        valor: '${resultado.correctas}/${resultado.total}',
                        color: colorResultado,
                      ),
                      _MetricTile(
                        titulo: 'Mínimo Exigido',
                        valor: '${resultado.minimoAprobatorio}/${resultado.total}',
                        color: AppColors.textSecondary,
                      ),
                      _MetricTile(
                        titulo: 'Tiempo Usado',
                        valor: _formatearTiempo(resultado.tiempoUsado),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Punto Débil (si existe)
            if (puntoDebil != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Punto a Reforzar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tu desempeño más bajo estuvo en "${puntoDebil.topicoNombre}" con solo ${puntoDebil.correctas}/${puntoDebil.total} aciertos (${(puntoDebil.dominio * 100).toInt()}%). Te recomendamos repasar este tópico en el Balotario.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Desglose por Tópico (Feedback)
            const Text(
              'Feedback Detallado por Tópico',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'El examen real del MTC evalúa diferentes áreas. Acá podés ver exactamente dónde ganaste o perdiste puntos.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            ...resultado.prioridadDeRepaso.map(
              (tf) => TopicFeedbackItem(feedback: tf),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewScreen(
                      sesion: sesion,
                      resultado: resultado,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Revisar Respuestas del Examen'),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onRestart();
              },
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              label: const Text(
                'Nuevo Simulacro',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                'Volver al Menú Principal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
