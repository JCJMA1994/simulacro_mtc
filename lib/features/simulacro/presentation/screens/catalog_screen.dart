import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/exam_session.dart';
import '../../domain/entities/license_category.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/obtener_categorias.dart';
import 'exam_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    this.onOpenRequirements,
    this.onOpenBalotario,
  });

  final VoidCallback? onOpenRequirements;
  final ValueChanged<String>? onOpenBalotario;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<LicenseCategory> _categorias = [];
  bool _cargando = true;
  String? _error;
  ExamSession? _sesionEnCurso;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final obtenerCategorias = sl<ObtenerCategorias>();
    final sessionRepo = sl<SessionRepository>();

    final resultadoCategorias = await obtenerCategorias(const NoParams());
    final resultadoSesion = await sessionRepo.recuperarEnCurso();

    if (mounted) {
      resultadoCategorias.fold(
        (falla) => setState(() {
          _error = falla.mensaje;
          _cargando = false;
        }),
        (lista) => setState(() {
          _categorias = lista;
          _cargando = false;
        }),
      );

      resultadoSesion.fold(
        (_) {},
        (sesion) => setState(() {
          _sesionEnCurso = sesion;
        }),
      );
    }
  }

  void _iniciarExamen(LicenseCategory categoria) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamScreen(categoriaCodigo: categoria.codigo),
      ),
    ).then((_) => _cargarDatos());
  }

  void _reanudarExamen(ExamSession sesion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamScreen(
          categoriaCodigo: sesion.categoria.codigo,
          sesionPrevia: sesion,
        ),
      ),
    ).then((_) => _cargarDatos());
  }

  Future<void> _descartarSesion() async {
    final sessionRepo = sl<SessionRepository>();
    await sessionRepo.descartarEnCurso();
    setState(() {
      _sesionEnCurso = null;
    });
  }

  Future<void> _mostrarDetalleCategoria(LicenseCategory categoria) async {
    final attemptRepo = sl<AttemptRepository>();
    final falladasRes = await attemptRepo.preguntasFalladas(categoria.codigo);
    final totalFalladas = falladasRes.fold((_) => 0, (list) => list.length);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryDetailSheet(
        categoria: categoria,
        totalFalladas: totalFalladas,
        onStartExam: () {
          Navigator.of(context).pop();
          _iniciarExamen(categoria);
        },
        onStartReviewErrors: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExamScreen(
                categoriaCodigo: categoria.codigo,
                soloFalladas: true,
              ),
            ),
          ).then((_) => _cargarDatos());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarDatos,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Banner de sesión en curso (si existe)
                        if (_sesionEnCurso != null) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Simulacro en curso: Cat. ${_sesionEnCurso!.categoria.codigo}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Pregunta ${_sesionEnCurso!.indiceActual + 1} de ${_sesionEnCurso!.preguntas.length} • ${_sesionEnCurso!.respondidas} respondidas',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Descartar intento previo',
                                      icon: const Icon(Icons.delete_outline_rounded,
                                          color: Colors.white),
                                      onPressed: _descartarSesion,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFB45309),
                                    minimumSize: const Size.fromHeight(42),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _reanudarExamen(_sesionEnCurso!),
                                  child: const Text(
                                    'Reanudar Simulacro',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Hero Header Card con estilo vibrante
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A3D78), Color(0xFF1565C0), Color(0xFF1E88E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/icons/app_icon.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          child: const Icon(
                                            Icons.directions_car_rounded,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Simulador Oficial MTC 2026',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Examen de Conocimientos Perú',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cronómetro de 40 min, calificación oficial y feedback.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Seleccioná tu Categoría',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        ..._categorias.map(
                          (cat) => _CategoryCard(
                            categoria: cat,
                            onTap: () => _mostrarDetalleCategoria(cat),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categoria,
    required this.onTap,
  });

  final LicenseCategory categoria;
  final VoidCallback onTap;

  (List<Color>, String, Color) _obtenerEstiloCategoria(String codigo) {
    if (codigo == 'A-I') {
      return (
        [const Color(0xFF0F52BA), const Color(0xFF1E88E5)],
        'Particular',
        const Color(0xFF0F52BA),
      );
    } else if (codigo.startsWith('A-II')) {
      return (
        [const Color(0xFF6366F1), const Color(0xFF818CF8)],
        'Profesional',
        const Color(0xFF6366F1),
      );
    } else if (codigo.startsWith('A-III')) {
      return (
        [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        'Carga Pesada',
        const Color(0xFF0D9488),
      );
    } else {
      return (
        [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        'Motos y Trimotos',
        const Color(0xFFD97706),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradientColors, tipoTexto, badgeColor) = _obtenerEstiloCategoria(categoria.codigo);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      categoria.codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          tipoTexto,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                categoria.vehiculos,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Chips con colores vibrantes
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _ColorfulRuleChip(
                    icon: Icons.quiz_outlined,
                    label: '${categoria.preguntasPorExamen} preguntas',
                    bgColor: const Color(0xFFE0EDFF),
                    borderColor: const Color(0xFFBAD6FF),
                    textColor: const Color(0xFF0369A1),
                    iconColor: const Color(0xFF0284C7),
                  ),
                  _ColorfulRuleChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Mín. ${categoria.minimoAprobatorio} aciertos',
                    bgColor: const Color(0xFFDCFCE7),
                    borderColor: const Color(0xFFBBF7D0),
                    textColor: const Color(0xFF15803D),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  _ColorfulRuleChip(
                    icon: Icons.access_time_rounded,
                    label: '${categoria.duracion.inMinutes} min',
                    bgColor: const Color(0xFFFEF3C7),
                    borderColor: const Color(0xFFFDE68A),
                    textColor: const Color(0xFFB45309),
                    iconColor: const Color(0xFFD97706),
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

class _ColorfulRuleChip extends StatelessWidget {
  const _ColorfulRuleChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDetailSheet extends StatelessWidget {
  const _CategoryDetailSheet({
    required this.categoria,
    required this.onStartExam,
    required this.onStartReviewErrors,
    this.totalFalladas = 0,
  });

  final LicenseCategory categoria;
  final VoidCallback onStartExam;
  final VoidCallback onStartReviewErrors;
  final int totalFalladas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    categoria.codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Reglas de Examen MTC Oficial',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),

            // Vehículos
            const Text(
              'Vehículos Autorizados:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              categoria.vehiculos,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Tarjetas de Parámetros del Examen
            Row(
              children: [
                Expanded(
                  child: _RuleBox(
                    icon: Icons.quiz_outlined,
                    titulo: 'Preguntas',
                    valor: '${categoria.preguntasPorExamen}',
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0EDFF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RuleBox(
                    icon: Icons.verified_outlined,
                    titulo: 'Mínimo',
                    valor: '${categoria.minimoAprobatorio}',
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RuleBox(
                    icon: Icons.timer_outlined,
                    titulo: 'Duración',
                    valor: '${categoria.duracion.inMinutes} min',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onStartExam,
              child: const Text('Iniciar Simulacro Oficial'),
            ),

            if (totalFalladas > 0) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onStartReviewErrors,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text('Practicar $totalFalladas preguntas falladas'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleBox extends StatelessWidget {
  const _RuleBox({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final String titulo;
  final String valor;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
