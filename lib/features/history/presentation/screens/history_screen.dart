import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../simulacro/domain/entities/exam_result.dart';
import '../../../simulacro/domain/entities/license_category.dart';
import '../../../simulacro/domain/usecases/obtener_categorias.dart';
import '../../../simulacro/domain/usecases/obtener_historial.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<LicenseCategory> _categorias = [];
  String _categoriaSeleccionada = 'A-I';
  List<ExamResult> _intentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final obtenerCategorias = sl<ObtenerCategorias>();
    final res = await obtenerCategorias(const NoParams());

    res.fold(
      (_) {},
      (lista) {
        if (mounted) {
          setState(() {
            _categorias = lista;
            if (lista.isNotEmpty) {
              _categoriaSeleccionada = lista.first.codigo;
            }
          });
          _cargarHistorial(_categoriaSeleccionada);
        }
      },
    );
  }

  Future<void> _cargarHistorial(String categoria) async {
    setState(() => _cargando = true);
    final obtenerHistorial = sl<ObtenerHistorial>();
    final res = await obtenerHistorial(ObtenerHistorialParams(categoriaCodigo: categoria));

    if (mounted) {
      res.fold(
        (_) => setState(() {
          _intentos = [];
          _cargando = false;
        }),
        (lista) => setState(() {
          _intentos = lista;
          _cargando = false;
        }),
      );
    }
  }

  String _formatearTiempo(Duration duracion) {
    final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos min';
  }

  @override
  Widget build(BuildContext context) {
    final totalSimulacros = _intentos.length;
    final aprobados = _intentos.where((i) => i.aprobado).length;
    final tasaAprobacion = totalSimulacros == 0 ? 0 : ((aprobados / totalSimulacros) * 100).toInt();
    final promedioAciertos = totalSimulacros == 0
        ? 0.0
        : _intentos.map((i) => i.correctas).reduce((a, b) => a + b) / totalSimulacros;
    final mejorPuntaje = totalSimulacros == 0
        ? 0
        : _intentos.map((i) => i.correctas).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: () => _cargarHistorial(_categoriaSeleccionada),
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Header Integrado con Selector de Categoría
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Rendimiento',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Historial y métricas de simulacros',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Selector de Categoría Pill
                        if (_categorias.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F52BA), Color(0xFF1E88E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F52BA).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _categoriaSeleccionada,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                                dropdownColor: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                items: _categorias.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat.codigo,
                                    child: Text(
                                      'Cat. ${cat.codigo}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                selectedItemBuilder: (context) {
                                  return _categorias.map((cat) {
                                    return Center(
                                      child: Text(
                                        'Cat. ${cat.codigo}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          fontSize: 13,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                onChanged: (nuevo) {
                                  if (nuevo != null && nuevo != _categoriaSeleccionada) {
                                    setState(() => _categoriaSeleccionada = nuevo);
                                    _cargarHistorial(nuevo);
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Resumen Estadístico Premium
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rendimiento Acumulado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0EDFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Cat. $_categoriaSeleccionada',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Simulacros',
                                  valor: '$totalSimulacros',
                                  icon: Icons.quiz_outlined,
                                  color: const Color(0xFF0284C7),
                                  bgColor: const Color(0xFFE0EDFF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatBox(
                                  label: 'Aprobación',
                                  valor: '$tasaAprobacion%',
                                  icon: Icons.verified_outlined,
                                  color: tasaAprobacion >= 70
                                      ? const Color(0xFF16A34A)
                                      : (totalSimulacros == 0
                                          ? AppColors.textSecondary
                                          : const Color(0xFFD97706)),
                                  bgColor: tasaAprobacion >= 70
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Promedio Aciertos',
                                  valor: totalSimulacros == 0
                                      ? '-'
                                      : promedioAciertos.toStringAsFixed(1),
                                  icon: Icons.trending_up_rounded,
                                  color: const Color(0xFF6366F1),
                                  bgColor: const Color(0xFFEEF2FF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatBox(
                                  label: 'Mejor Puntaje',
                                  valor: totalSimulacros == 0 ? '-' : '$mejorPuntaje',
                                  icon: Icons.emoji_events_outlined,
                                  color: const Color(0xFF059669),
                                  bgColor: const Color(0xFFECFDF5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Historial de Intentos
                    const Text(
                      'Historial de Intentos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_intentos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no registrás simulacros completados para esta categoría.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: const Text('Iniciar mi primer simulacro'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_intentos.length, (index) {
                        final intento = _intentos[index];
                        final numeroIntento = _intentos.length - index;
                        final aprobado = intento.aprobado;
                        final colorEstado =
                            aprobado ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                        final bgEstado =
                            aprobado ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: bgEstado,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      aprobado
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: colorEstado,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Simulacro #$numeroIntento',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        aprobado
                                            ? 'Aprobado (${intento.correctas}/${intento.total} aciertos)'
                                            : 'Desaprobado (${intento.correctas}/${intento.total} aciertos)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: colorEstado,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tiempo: ${_formatearTiempo(intento.tiempoUsado)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bgEstado,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${intento.correctas}/${intento.total}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: colorEstado,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.valor,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String valor;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
