import 'package:equatable/equatable.dart';

/// Tema del balotario del MTC. Es la unidad sobre la que se construye el
/// feedback: el resultado no dice solo "32/40", dice donde fallaste.
final class Topico extends Equatable {
  const Topico({required this.codigo, required this.nombre});

  final String codigo;
  final String nombre;

  @override
  List<Object?> get props => [codigo];
}
