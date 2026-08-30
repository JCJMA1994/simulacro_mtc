import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/exam_session.dart';
import '../bloc/exam/exam_bloc.dart';
import '../widgets/exam_timer_widget.dart';
import '../widgets/question_card_widget.dart';
import '../widgets/question_navigator_sheet.dart';
import 'result_screen.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({
    super.key,
    required this.categoriaCodigo,
    this.sesionPrevia,
  });

  final String categoriaCodigo;
  final ExamSession? sesionPrevia;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamBloc>(
      create: (context) {
        final bloc = sl<ExamBloc>();
        if (sesionPrevia != null) {
          bloc.add(const SimulacroReanudado());
        } else {
          bloc.add(SimulacroIniciado(categoriaCodigo));
        }
        return bloc;
      },
      child: const _ExamScreenView(),
    );
  }
}

class _ExamScreenView extends StatelessWidget {
  const _ExamScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExamBloc, ExamState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ExamStatus.terminado && state.resultado != null && state.sesion != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                resultado: state.resultado!,
                sesion: state.sesion!,
                onRestart: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ExamScreen(
                        categoriaCodigo: state.resultado!.categoriaCodigo,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ExamStatus.cargando || state.status == ExamStatus.inicial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Preparando preguntas del simulacro...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status == ExamStatus.error || state.sesion == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Error en Simulacro')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 54, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      state.mensajeError ?? 'Ocurrió un problema al cargar el simulacro.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver al Menú'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sesion = state.sesion!;
        final preguntaActual = sesion.preguntaActual;
        final respuestaActual = sesion.respuestas[preguntaActual.id];
        final estaMarcada = respuestaActual?.marcada ?? false;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _confirmarSalida(context);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Salir del examen',
                onPressed: () => _confirmarSalida(context),
              ),
              title: ExamTimerWidget(restante: sesion.restante),
              centerTitle: true,
              actions: [
                // Botón Marcar para revisión (Bookmark)
                IconButton(
                  tooltip: estaMarcada ? 'Desmarcar pregunta' : 'Marcar para revisión',
                  icon: Icon(
                    estaMarcada ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: estaMarcada ? AppColors.warning : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    context.read<ExamBloc>().add(const PreguntaMarcada());
                  },
                ),
                // Botón Navegador de Preguntas (Sheet)
                IconButton(
                  tooltip: 'Ver todas las preguntas',
                  icon: const Icon(Icons.grid_view_rounded),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => QuestionNavigatorSheet(
                        sesion: sesion,
                        onSelectQuestion: (index) {
                          context.read<ExamBloc>().add(SaltoAPregunta(index));
                        },
                        onFinishExam: () => _confirmarFinalizacion(context, sesion),
                      ),
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: sesion.progreso,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: QuestionCardWidget(
                        pregunta: preguntaActual,
                        numeroPregunta: sesion.indiceActual + 1,
                        totalPreguntas: sesion.preguntas.length,
                        respuesta: respuestaActual,
                        onSelectOption: (indice) {
                          context.read<ExamBloc>().add(OpcionSeleccionada(indice));
                        },
                      ),
                    ),

                    // Barra inferior de navegación
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Botón Anterior
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: sesion.indiceActual == 0
                                        ? AppColors.border
                                        : AppColors.primary,
                                  ),
                                ),
                                onPressed: sesion.indiceActual == 0
                                    ? null
                                    : () {
                                        context
                                            .read<ExamBloc>()
                                            .add(const RetrocedioPregunta());
                                      },
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('Anterior'),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Botón Siguiente / Finalizar
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: () {
                                  if (sesion.esUltima) {
                                    _confirmarFinalizacion(context, sesion);
                                  } else {
                                    context
                                        .read<ExamBloc>()
                                        .add(const AvanzoPregunta());
                                  }
                                },
                                icon: Icon(
                                  sesion.esUltima
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  sesion.esUltima ? 'Finalizar' : 'Siguiente',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Overlay de calificación
                if (state.status == ExamStatus.calificando)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 16),
                              Text(
                                'Calificando examen...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Calculando feedback por tópico',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarSalida(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Pausar o salir del examen?'),
        content: const Text(
          'Tu progreso se encuentra autoguardado. Podrás reanudar el simulacro más tarde desde el menú principal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continuar Examen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Guardar y Salir'),
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizacion(BuildContext context, ExamSession sesion) {
    final faltantes = sesion.preguntas.length - sesion.respondidas;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Finalizar simulacro?'),
        content: Text(
          faltantes > 0
              ? 'Tenés $faltantes preguntas sin responder. ¿Deseas calificar el examen ahora?'
              : '¿Deseas enviar tus respuestas y ver tu calificación detallada por tópico?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Volver al Examen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ExamBloc>().add(const ExamenFinalizado());
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}
