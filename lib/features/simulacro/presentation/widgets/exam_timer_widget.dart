import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExamTimerWidget extends StatelessWidget {
  const ExamTimerWidget({
    super.key,
    required this.restante,
  });

  final Duration restante;

  String _formatearTiempo(Duration duracion) {
    if (duracion <= Duration.zero) return '00:00';
    final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    // Alerta ámbar en los últimos 5 minutos (300 segundos) sin parpadeos
    final esCritico = restante.inSeconds <= 300 && restante > Duration.zero;
    final colorTexto = esCritico ? AppColors.warning : AppColors.primary;
    final colorFondo = esCritico
        ? AppColors.warning.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esCritico
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: colorTexto,
          ),
          const SizedBox(width: 6),
          Text(
            _formatearTiempo(restante),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorTexto,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
