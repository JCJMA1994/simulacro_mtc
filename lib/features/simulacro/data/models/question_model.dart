import '../../domain/entities/question.dart';

final class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.numero,
    required super.categoriaCodigo,
    required super.topicoCodigo,
    required super.enunciado,
    required super.opciones,
    required super.indiceCorrecto,
    super.explicacion,
    super.imagenAsset,
  });

  static const Map<int, String> _senalesAI = {
    4: '0004_0.png',
    9: '0009_0.png',
    18: '0018_0.png',
    28: '0028_1.png',
    32: '0032_0.png',
    33: '0033_1.png',
    35: '0035_2.png',
    50: '0050_0.png',
    67: '0067_0.png',
    93: '0093_0.png',
    99: '0099_0.png',
    100: '0100_1.png',
    101: '0101_2.png',
    102: '0102_3.png',
    103: '0103_4.png',
    104: '0104_5.png',
    105: '0105_6.png',
    106: '0106_7.png',
    107: '0107_0.png',
    108: '0108_1.png',
    109: '0109_2.png',
    110: '0110_3.png',
    111: '0111_4.png',
    112: '0112_5.png',
    113: '0113_6.png',
    114: '0114_7.png',
    115: '0115_0.png',
    116: '0116_1.png',
    117: '0117_2.png',
    118: '0118_3.png',
    119: '0119_4.png',
    120: '0120_5.png',
    121: '0121_6.png',
    122: '0122_7.png',
    123: '0123_0.png',
    124: '0124_1.png',
    125: '0125_2.png',
    126: '0126_3.png',
    127: '0127_4.png',
    128: '0128_5.png',
    129: '0129_6.png',
    130: '0130_7.png',
    131: '0131_0.png',
    132: '0132_1.png',
    133: '0133_2.png',
    134: '0134_3.png',
    135: '0135_4.png',
    136: '0136_5.png',
    137: '0137_6.png',
    138: '0138_7.png',
    139: '0139_0.png',
    140: '0140_1.png',
    141: '0141_2.png',
    142: '0142_3.png',
    143: '0143_4.png',
    144: '0144_5.png',
    145: '0145_6.png',
    146: '0146_7.png',
    147: '0147_0.png',
    148: '0148_1.png',
    151: '0151_2.png',
    181: '0181_0.png',
    182: '0182_1.png',
    187: '0187_2.png',
    197: '0197_0.png',
    199: '0199_1.png',
    200: '0200_0.png',
  };

  /// Mapea el JSON producido por tools/scrape_balotarios_mtc.py
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final numero = json['numero'] as int;
    final cat = json['categoria'] as String;
    String? imagen = json['imagen'] as String?;

    if (imagen == null && cat.startsWith('A-') && _senalesAI.containsKey(numero)) {
      imagen = 'assets/senales/A-I/${_senalesAI[numero]}';
    }

    return QuestionModel(
      id: json['id'] as String,
      numero: numero,
      categoriaCodigo: cat,
      topicoCodigo: json['topico'] as String,
      enunciado: json['enunciado'] as String,
      opciones: List<String>.from(json['opciones'] as List<dynamic>),
      indiceCorrecto: json['respuesta_correcta'] as int,
      explicacion: json['explicacion'] as String?,
      imagenAsset: imagen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'categoria': categoriaCodigo,
        'topico': topicoCodigo,
        'enunciado': enunciado,
        'opciones': opciones,
        'respuesta_correcta': indiceCorrecto,
        'explicacion': explicacion,
        'imagen': imagenAsset,
      };
}
