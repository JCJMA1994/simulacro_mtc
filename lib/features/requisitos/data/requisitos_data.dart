class RequisitoItem {
  const RequisitoItem({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.icono,
    required this.pasos,
    this.costo,
    this.duracion,
    this.codigoTributo,
    this.consejos = const [],
    this.documentos = const [],
  });

  final String id;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final String icono;
  final List<String> pasos;
  final String? costo;
  final String? duracion;
  final String? codigoTributo;
  final List<String> consejos;
  final List<String> documentos;
}

class CategoriaRequisitos {
  const CategoriaRequisitos({
    required this.codigo,
    required this.nombre,
    required this.clase,
    required this.edadMinima,
    required this.experienciaPrevia,
    required this.vigencia,
    required this.vehiculosPermitidos,
    required this.preguntasExamen,
    required this.minimoAprobatorio,
    this.cursoObligatorio,
  });

  final String codigo;
  final String nombre;
  final String clase;
  final int edadMinima;
  final String experienciaPrevia;
  final String vigencia;
  final String vehiculosPermitidos;
  final int preguntasExamen;
  final int minimoAprobatorio;
  final String? cursoObligatorio;
}

class SistemaPuntosInfo {
  const SistemaPuntosInfo({
    required this.tipoFalta,
    required this.rangoPuntos,
    required this.ejemplos,
    required this.colorHex,
  });

  final String tipoFalta;
  final String rangoPuntos;
  final List<String> ejemplos;
  final int colorHex;
}

class SedeEvaluacion {
  const SedeEvaluacion({
    required this.nombre,
    required this.ubicacion,
    required this.tipoEvaluacion,
    required this.horario,
    required this.telefonoOweb,
  });

  final String nombre;
  final String ubicacion;
  final String tipoEvaluacion;
  final String horario;
  final String telefonoOweb;
}

abstract final class RequisitosMtcData {
  // ------------------------------------------------------------- 1. TRÁMITES PRINCIPALES
  static const List<RequisitoItem> tramitesCompletos = [
    RequisitoItem(
      id: 'nueva_licencia',
      titulo: 'Obtención de Primer Brevete (Nueva Licencia)',
      subtitulo: 'Para postulantes por primera vez a clase A-I o clase B (Motos)',
      descripcion:
          'Proceso obligatorio para obtener tu primera licencia de conducir en Perú. Consta de 3 evaluaciones: Examen Médico, Examen de Reglas y Examen Práctico de Manejo.',
      icono: 'badge_rounded',
      costo: 'Examen Médico (~S/ 150 - S/ 300) + Derecho de Examen (~S/ 67.32) + Emisión (S/ 6.70)',
      duracion: '10 años de vigencia para el primer brevete A-I',
      codigoTributo: 'Código 02184 (Brevete Electrónico S/ 6.70) | Código 02124 (Físico S/ 14.80)',
      pasos: [
        '1. Rendir y aprobar el Examen Médico en un centro de salud autorizado por el MTC (vigencia 6 meses).',
        '2. Pagar el derecho de evaluación en el Banco de la Nación o Touring Automóvil Club del Perú.',
        '3. Agendar y aprobar el Examen de Conocimientos de Reglas de Tránsito (40 preguntas / 35 aciertos).',
        '4. Agendar y aprobar el Examen Práctico de Manejo en circuito cerrado oficial (Conchán o sede regional).',
        '5. Pagar la tasa de emisión en Págalo.pe y tramitar la descarga digital en la plataforma del MTC.',
      ],
      documentos: [
        'DNI original y vigente (o Carné de Extranjería / PTP con permanencia legal).',
        'Mayor de 18 años de edad.',
        'Certificado de estudios o declaración jurada de secundaria completa.',
        'No estar suspendido ni inhabilitado para conducir por el SUTRAN o resolución judicial.',
        'No registrar multas electorales pendientes ante el JNE ni papeletas graves impagas.',
      ],
      consejos: [
        'Practicá en nuestros simulacros con cronómetro real para asegurar tu aprobación en el primer intento.',
        'Tu pago de derecho de examen incluye hasta 2 oportunidades para reglas y 2 para manejo.',
        'El brevete electrónico tiene la misma validez legal que el físico y lo recibís en tu correo en minutos.',
      ],
    ),
    RequisitoItem(
      id: 'revalidacion',
      titulo: 'Revalidación / Renovación de Licencia',
      subtitulo: 'Para conductores con brevete próximo a vencer o vencido',
      descripcion:
          'Trámite para renovar la vigencia de tu licencia de conducir. ¡Beneficio MTC!: Si tienes récord de conductor impecable (sin faltas graves o muy graves en los últimos años), ¡estás EXONERADO de rendir el examen de reglas para la categoría A-I!',
      icono: 'autorenew_rounded',
      costo: 'Examen Médico (~S/ 150 - S/ 250) + Emisión (S/ 6.70 Electrónico)',
      duracion: 'Vigencia de 5 a 10 años según tu récord de infracciones',
      codigoTributo: 'Código 02184 (Electrónico S/ 6.70) | Código 02124 (Físico S/ 14.80)',
      pasos: [
        '1. Verificar en el Sistema Nacional de Conductores que tu récord no tenga papeletas graves impagas.',
        '2. Rendir el Examen Médico de revalidación en una clínica autorizada por el MTC.',
        '3. Si tu récord está limpio (sin sanciones G o MG), pasas directamente al trámite de emisión sin dar examen de reglas.',
        '4. Si registras sanciones graves o eres categoría profesional (A-II / A-III), debes rendir y aprobar el examen de conocimientos.',
        '5. Pagar el derecho de emisión en Págalo.pe y solicitar la nueva vigencia en licencias.mtc.gob.pe.',
      ],
      documentos: [
        'DNI vigente original.',
        'Licencia de conducir anterior (o denuncia policial por pérdida/robo).',
        'Certificado médico psicosomático aprobado para revalidación.',
        'Récord de conductor sin sanciones pendientes de cumplimiento.',
      ],
      consejos: [
        'Podés iniciar tu trámite de revalidación hasta 60 días antes de la fecha de vencimiento de tu brevete.',
        'Conducir con brevete vencido constituye infracción Muy Grave (M40) con multa de S/ 2,475 y retención del vehículo.',
      ],
    ),
    RequisitoItem(
      id: 'recategorizacion',
      titulo: 'Recategorización / Ascenso de Categoría',
      subtitulo: 'Para subir de nivel: A-I a A-IIa/b o A-IIIa/b/c (Profesionales)',
      descripcion:
          'Permite a conductores con experiencia ascender a categorías profesionales para transporte público, taxis, camiones de carga pesada y buses interprovinciales.',
      icono: 'trending_up_rounded',
      costo: 'Curso COFIPRO (~S/ 300 - S/ 800) + Médico + Exámenes + Emisión (S/ 6.70)',
      duracion: '3 a 5 años de vigencia profesional',
      codigoTributo: 'Código 02184 (Págalo.pe)',
      pasos: [
        '1. Cumplir con la antigüedad mínima requerida con la categoría inmediata inferior.',
        '2. Matricularse y aprobar el Curso de Capacitación de Conductores (COFIPRO) en una escuela autorizada por el MTC.',
        '3. Rendir el Examen Médico para categoría profesional.',
        '4. Aprobar el Examen de Conocimientos MTC para la categoría solicitada (40 preguntas con balotario profesional).',
        '5. Aprobar el Examen Práctico de Manejo con el vehículo correspondiente a la nueva categoría (taxi, minibús, camión o bus).',
        '6. Tramitar la emisión digital de la nueva licencia profesional.',
      ],
      documentos: [
        'DNI vigente y edad mínima requerida (21 años para A-II, 24 años para A-IIIa/b, 27 años para A-IIIc).',
        'Licencia de conducir anterior con la antigüedad reglamentaria.',
        'Certificado del Curso de Formación de Conductores (COFIPRO).',
        'Examen médico psicosomático y récord de conductor limpio.',
      ],
      consejos: [
        'Estudiá los tópicos de "Transporte de Personas" y "Transporte de Mercancías", ya que tienen alto peso en el balotario profesional.',
        'No podés recategorizar si tenés antecedentes penales por delitos de tránsito.',
      ],
    ),
    RequisitoItem(
      id: 'duplicado',
      titulo: 'Duplicado de Brevete (Pérdida o Robo)',
      subtitulo: '100% digital sin necesidad de rendir exámenes',
      descripcion:
          'Si perdiste tu licencia física o electrónica, te la robaron o se deterioró, podés solicitar un duplicado inmediato por internet manteniendo la misma fecha de vencimiento.',
      icono: 'file_copy_rounded',
      costo: 'Electrónico: S/ 6.70 | Físico: S/ 14.80',
      duracion: 'Mantiene la fecha de vigencia del brevete original',
      codigoTributo: 'Código 02184 (Electrónico) | Código 02124 (Físico)',
      pasos: [
        '1. En caso de robo o pérdida, realizar la denuncia digital en la Policía Nacional (opcional pero recomendado).',
        '2. Pagar la tasa de duplicado en Págalo.pe (S/ 6.70 para electrónico).',
        '3. Ingresar a licencias.mtc.gob.pe y seleccionar "Duplicado".',
        '4. Validar tu identidad con DNI y fecha de emisión.',
        '5. Descargar tu brevete electrónico en tu casilla electrónica del MTC o elegir sede de recojo si es físico.',
      ],
      documentos: [
        'DNI o Carné de Extranjería vigente.',
        'No estar inhabilitado ni suspendido para conducir.',
        'Comprobante de pago del Banco de la Nación / Págalo.pe.',
      ],
      consejos: [
        'Si solicitas el Brevete Electrónico, lo descargas en tu celular al instante en formato PDF oficial.',
      ],
    ),
    RequisitoItem(
      id: 'canje_extranjero',
      titulo: 'Canje de Licencia Extranjera o Militar / Policial',
      subtitulo: 'Para extranjeros residentes, diplomáticos y miembros de FFAA/PNP',
      descripcion:
          'Permite convalidar y canjear una licencia de conducir emitida en el extranjero (países con convenios como España, Corea, Chile, etc.) o licencias militares/policiales por una licencia civil MTC.',
      icono: 'public_rounded',
      costo: 'Examen Médico + Derecho de Canje + Emisión MTC',
      duracion: 'Según categoría civil equivalente',
      codigoTributo: 'Código 02184 (Págalo.pe)',
      pasos: [
        '1. Contar con la licencia extranjera original vigente y legalizada/apostillada.',
        '2. Certificado de equivalencia o constancia de autenticidad emitida por la embajada/consulado del país de origen.',
        '3. Rendir el Examen Médico en centro autorizado en Perú.',
        '4. Rendir el Examen de Conocimientos de Reglas de Tránsito del MTC.',
        '5. Solicitar el canje y emisión en la mesa de partes digital del MTC.',
      ],
      documentos: [
        'Carné de Extranjería, PTP o DNI en caso de peruanos nacionalizados.',
        'Licencia de conducir extranjera original y vigente con apostilla de La Haya.',
        'Certificado médico psicosomático emitido en Perú.',
      ],
      consejos: [
        'Los turistas pueden conducir en Perú con su licencia de origen hasta por 6 meses desde su ingreso al país.',
      ],
    ),
  ];

  // ------------------------------------------------------------- 2. CATEGORÍAS Y REGLAS
  static const List<CategoriaRequisitos> categoriasInfo = [
    CategoriaRequisitos(
      codigo: 'A-I',
      clase: 'Clase A',
      nombre: 'Particular (Autos, camionetas, SUVs)',
      edadMinima: 18,
      experienciaPrevia: 'Ninguna (Primera licencia)',
      vigencia: '10 años (primer brevete)',
      vehiculosPermitidos: 'M1, M2 y N1: Autos, camionetas, station wagon y furgonetas de hasta 8 pasajeros (uso particular sin fines comerciales)',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
    ),
    CategoriaRequisitos(
      codigo: 'A-IIa',
      clase: 'Clase A Profesional',
      nombre: 'Profesional Taxi, Colectivo y Escolar',
      edadMinima: 21,
      experienciaPrevia: 'Mínimo 2 años con licencia A-I',
      vigencia: '3 a 5 años según récord',
      vehiculosPermitidos: 'Taxis, transporte escolar, servicio turístico y transporte de personas M1/M2',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
      cursoObligatorio: 'Curso COFIPRO en Escuela de Conductores',
    ),
    CategoriaRequisitos(
      codigo: 'A-IIb',
      clase: 'Clase A Profesional',
      nombre: 'Profesional Minibús y Carga Liviana',
      edadMinima: 21,
      experienciaPrevia: 'Mínimo 3 años con A-I o 1 año con A-IIa',
      vigencia: '3 a 5 años según récord',
      vehiculosPermitidos: 'Microbuses de hasta 6 toneladas (M2, M3) y camiones de carga de hasta 12 toneladas (N2)',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
      cursoObligatorio: 'Curso COFIPRO en Escuela de Conductores',
    ),
    CategoriaRequisitos(
      codigo: 'A-IIIa',
      clase: 'Clase A Profesional',
      nombre: 'Profesional Ómnibus Interprovincial',
      edadMinima: 24,
      experienciaPrevia: 'Mínimo 2 años con A-IIb',
      vigencia: '3 a 5 años',
      vehiculosPermitidos: 'Buses interprovinciales de pasajeros de más de 6 toneladas (M3)',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
      cursoObligatorio: 'Curso de Especialización de Pasajeros',
    ),
    CategoriaRequisitos(
      codigo: 'A-IIIb',
      clase: 'Clase A Profesional',
      nombre: 'Profesional Remolques y Carga Pesada',
      edadMinima: 24,
      experienciaPrevia: 'Mínimo 2 años con A-IIb',
      vigencia: '3 a 5 años',
      vehiculosPermitidos: 'Camiones pesados con remolque, semirremolque, volquetes y trenes de carretera (N3)',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
      cursoObligatorio: 'Curso de Especialización de Carga',
    ),
    CategoriaRequisitos(
      codigo: 'A-IIIc',
      clase: 'Clase A Profesional',
      nombre: 'Profesional Máxima Categoría',
      edadMinima: 27,
      experienciaPrevia: 'Mínimo 1 año con A-IIIa o A-IIIb',
      vigencia: '3 a 5 años',
      vehiculosPermitidos: 'Todos los vehículos de la clase A, incluyendo materiales y residuos peligrosos (MATPEL)',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
      cursoObligatorio: 'Curso Especializado MATPEL y Transporte Pesado',
    ),
    CategoriaRequisitos(
      codigo: 'B-IIa',
      clase: 'Clase B Motos',
      nombre: 'Vehículos Menores de Carga (Furgones)',
      edadMinima: 18,
      experienciaPrevia: 'Ninguna',
      vigencia: '5 años',
      vehiculosPermitidos: 'Motos de tres ruedas para carga de mercancías (furgones motorizados)',
      preguntasExamen: 35,
      minimoAprobatorio: 30,
    ),
    CategoriaRequisitos(
      codigo: 'B-IIb',
      clase: 'Clase B Motos',
      nombre: 'Motocicletas Lineales',
      edadMinima: 18,
      experienciaPrevia: 'Ninguna',
      vigencia: '5 años',
      vehiculosPermitidos: 'Motos lineales de 2 ruedas o con sidecar para uso particular o delivery',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
    ),
    CategoriaRequisitos(
      codigo: 'B-IIc',
      clase: 'Clase B Motos',
      nombre: 'Mototaxis y Trimotos de Pasajeros',
      edadMinima: 18,
      experienciaPrevia: 'Ninguna',
      vigencia: '5 años',
      vehiculosPermitidos: 'Mototaxis de 3 ruedas autorizadas para transporte público de pasajeros y delivery',
      preguntasExamen: 40,
      minimoAprobatorio: 35,
    ),
  ];

  // ------------------------------------------------------------- 3. SISTEMA DE PUNTOS Y SANCIONES
  static const List<SistemaPuntosInfo> sistemaPuntos = [
    SistemaPuntosInfo(
      tipoFalta: 'Infracción Leve (L)',
      rangoPuntos: '1 a 20 puntos firmes',
      ejemplos: [
        'L01: Dejar mal estacionado el vehículo en zonas no prohibidas (5 pts).',
        'L04: Abrir la puerta del vehículo sin cerciorarse que no cause peligro (10 pts).',
        'L07: No usar las luces direccionales antes de voltear (10 pts).',
      ],
      colorHex: 0xFF1D7A4F,
    ),
    SistemaPuntosInfo(
      tipoFalta: 'Infracción Grave (G)',
      rangoPuntos: '20 a 50 puntos firmes',
      ejemplos: [
        'G01: No respetar las señales que rigen el tránsito o desobedecer al policía (20 pts).',
        'G28: Usar el teléfono celular mientras se conduce (30 pts).',
        'G47: Estacionar en zonas rígidas o sobre cruces peatonales (20 pts).',
        'G57: No usar el cinturón de seguridad (20 pts).',
      ],
      colorHex: 0xFFB87407,
    ),
    SistemaPuntosInfo(
      tipoFalta: 'Infracción Muy Grave (MG)',
      rangoPuntos: '50 a 100 puntos firmes',
      ejemplos: [
        'M01: Conducir bajo los efectos del alcohol (>0.5 g/l) causando accidente (Cancelación + Inhabilitación).',
        'M02: Conducir en estado de ebriedad sin causar accidente (100 pts + 3 años suspensión).',
        'M04: No respetar la luz roja del semáforo (50 pts).',
        'M20: Superar el límite de velocidad por más de 30 km/h (50 pts).',
      ],
      colorHex: 0xFFB3261E,
    ),
  ];

  // ------------------------------------------------------------- 4. COMPARATIVA BREVETE ELECTRÓNICO VS FÍSICO
  static const List<Map<String, String>> comparativaBrevete = [
    {
      'aspecto': 'Costo oficial',
      'electronico': 'S/ 6.70 (Código Págalo 02184)',
      'fisico': 'S/ 14.80 (Código Págalo 02124)',
    },
    {
      'aspecto': 'Tiempo de entrega',
      'electronico': '20 minutos (Descarga PDF inmediata)',
      'fisico': '2 a 5 días hábiles en sede/MAC',
    },
    {
      'aspecto': 'Pérdida o Robo',
      'electronico': 'No se pierde: guardado en la nube y correo',
      'fisico': 'Requiere pagar duplicado presencial',
    },
    {
      'aspecto': 'Validez Legal',
      'electronico': '100% legal en todo el Perú (QR y Firma)',
      'fisico': '100% legal (Formato PVC tradicional)',
    },
    {
      'aspecto': 'Requisito previo',
      'electronico': 'Crear Casilla Electrónica MTC gratis',
      'fisico': 'Cita para recojo presencial en ventanilla',
    },
  ];

  // ------------------------------------------------------------- 5. SEDES Y CENTROS DE EVALUACIÓN
  static const List<SedeEvaluacion> sedesOficiales = [
    SedeEvaluacion(
      nombre: 'Touring Automóvil Club del Perú (Sede Conchán)',
      ubicacion: 'Km 21.5 Panamericana Sur, Villa El Salvador (Lima)',
      tipoEvaluacion: 'Examen de Conocimientos y Circuito de Manejo',
      horario: 'Lunes a Sábado: 7:00 am a 4:30 pm',
      telefonoOweb: 'touring.pe | (01) 615-9315',
    ),
    SedeEvaluacion(
      nombre: 'Touring Sede Lince (Solo Reglas de Tránsito)',
      ubicacion: 'Av. César Vallejo 651, Lince (Lima)',
      tipoEvaluacion: 'Examen de Conocimientos / Reglas MTC',
      horario: 'Lunes a Sábado: 8:00 am a 5:00 pm',
      telefonoOweb: 'touring.pe | (01) 615-9315',
    ),
    SedeEvaluacion(
      nombre: 'MTC Sede Central Antenor Orrego',
      ubicacion: 'Jr. Antenor Orrego 1923, Chacra Ríos (Cercado de Lima)',
      tipoEvaluacion: 'Emisión, Canje, Duplicado y Mesa de Partes',
      horario: 'Lunes a Viernes: 8:30 am a 5:00 pm',
      telefonoOweb: 'licencias.mtc.gob.pe',
    ),
    SedeEvaluacion(
      nombre: 'Direcciones Regionales de Transportes (DRTC Provincias)',
      ubicacion: 'En cada capital de departamento del Perú',
      tipoEvaluacion: 'Examen médico, conocimientos, manejo y emisión',
      horario: 'Lunes a Viernes: 8:00 am a 4:00 pm',
      telefonoOweb: 'Gobiernos Regionales correspondientes',
    ),
  ];
}
