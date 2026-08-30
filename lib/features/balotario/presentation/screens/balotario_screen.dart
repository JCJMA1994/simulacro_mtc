import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../simulacro/domain/entities/license_category.dart';
import '../../../simulacro/domain/entities/question.dart';
import '../../../simulacro/domain/usecases/obtener_balotario.dart';
import '../../../simulacro/domain/usecases/obtener_categorias.dart';
import '../widgets/study_question_card.dart';

class BalotarioScreen extends StatefulWidget {
  const BalotarioScreen({super.key});

  @override
  State<BalotarioScreen> createState() => _BalotarioScreenState();
}

class _BalotarioScreenState extends State<BalotarioScreen> {
  List<LicenseCategory> _categorias = [];
  String _categoriaSeleccionada = 'A-I';
  List<Question> _preguntas = [];
  bool _cargando = true;
  String _topicoFiltro = 'TODOS';
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    final obtenerCategorias = sl<ObtenerCategorias>();
    final resultado = await obtenerCategorias(const NoParams());

    resultado.fold(
      (_) {},
      (lista) {
        if (mounted) {
          setState(() {
            _categorias = lista;
            if (lista.isNotEmpty) {
              _categoriaSeleccionada = lista.first.codigo;
            }
          });
          _cargarBalotario(_categoriaSeleccionada);
        }
      },
    );
  }

  Future<void> _cargarBalotario(String codigo) async {
    setState(() {
      _cargando = true;
    });

    final obtenerBalotario = sl<ObtenerBalotario>();
    final res = await obtenerBalotario(ObtenerBalotarioParams(categoriaCodigo: codigo));

    if (mounted) {
      res.fold(
        (_) => setState(() {
          _preguntas = [];
          _cargando = false;
        }),
        (lista) => setState(() {
          _preguntas = lista;
          _cargando = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener lista de tópicos únicos
    final Set<String> topicosSet = {'TODOS'};
    for (final p in _preguntas) {
      topicosSet.add(p.topicoCodigo);
    }
    final topicos = topicosSet.toList();

    // Filtrar preguntas por tópico y búsqueda
    final preguntasFiltradas = _preguntas.where((p) {
      final coincideTopico = _topicoFiltro == 'TODOS' || p.topicoCodigo == _topicoFiltro;
      final coincideBusqueda = _busqueda.isEmpty ||
          p.enunciado.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.opciones.any((op) => op.toLowerCase().contains(_busqueda.toLowerCase())) ||
          '${p.numero}'.contains(_busqueda);
      return coincideTopico && coincideBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header integrado sin AppBar redundante
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Balotario de Estudio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${preguntasFiltradas.length} preguntas oficiales MTC',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Selector de categoría tipo Pill
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
                              setState(() {
                                _categoriaSeleccionada = nuevo;
                                _topicoFiltro = 'TODOS';
                              });
                              _cargarBalotario(nuevo);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Buscador estilizado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por palabra clave o número...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _busqueda = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _busqueda = val),
              ),
            ),

            // Chips de Tópicos con colores vivos
            if (topicos.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: topicos.map((topico) {
                    final esSeleccionado = _topicoFiltro == topico;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _topicoFiltro = topico),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: esSeleccionado ? AppColors.primaryGradient : null,
                            color: esSeleccionado ? null : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: esSeleccionado ? AppColors.primary : AppColors.border,
                            ),
                            boxShadow: esSeleccionado
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            topico == 'TODOS' ? 'Todos los tópicos' : topico,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: esSeleccionado ? FontWeight.w800 : FontWeight.w600,
                              color: esSeleccionado ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 1, color: AppColors.divider),

            // Lista de preguntas
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : preguntasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              const Text(
                                'No se encontraron preguntas coincidentes.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_busqueda.isNotEmpty || _topicoFiltro != 'TODOS') ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _busqueda = '';
                                      _topicoFiltro = 'TODOS';
                                    });
                                  },
                                  child: const Text('Limpiar filtros'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: preguntasFiltradas.length,
                          itemBuilder: (context, index) {
                            return StudyQuestionCard(
                              key: ValueKey(preguntasFiltradas[index].id),
                              pregunta: preguntasFiltradas[index],
                              indiceLista: index + 1,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
