part of 'exam_bloc.dart';

enum ExamStatus { inicial, cargando, enCurso, calificando, terminado, error }

final class ExamState extends Equatable {
  const ExamState({
    this.status = ExamStatus.inicial,
    this.sesion,
    this.resultado,
    this.mensajeError,
  });

  final ExamStatus status;
  final ExamSession? sesion;
  final ExamResult? resultado;
  final String? mensajeError;

  bool get enCurso => status == ExamStatus.enCurso && sesion != null;

  ExamState copyWith({
    ExamStatus? status,
    ExamSession? sesion,
    ExamResult? resultado,
    String? mensajeError,
  }) =>
      ExamState(
        status: status ?? this.status,
        sesion: sesion ?? this.sesion,
        resultado: resultado ?? this.resultado,
        mensajeError: mensajeError,
      );

  @override
  List<Object?> get props => [status, sesion, resultado, mensajeError];
}
