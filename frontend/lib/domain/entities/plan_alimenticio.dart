class PlanAlimenticio {
  const PlanAlimenticio({
    required this.id,
    required this.pacienteId,
    required this.titulo,
    required this.descripcion,
    required this.objetivo,
    required this.condicion,
    required this.plantillaNombre,
    required this.fechaInicio,
    required this.fechaFin,
    this.comidas = '',
    this.sustituciones = '',
    this.calorias = 0,
    this.proteinas = 0,
    this.carbohidratos = 0,
    this.grasasMacros = 0,
    this.periodo = 'Diario',
    this.recordatorio24h = '',
    this.listaCompras = '',
    this.recetas = '',
    this.distribucionCalorias = '',
    this.aguaRecomendada = 0,
  });

  final int id;
  final int pacienteId;
  final String titulo;
  final String descripcion;
  final String objetivo;
  final String condicion;
  final String plantillaNombre;
  final String fechaInicio;
  final String fechaFin;
  final String comidas;
  final String sustituciones;
  final double calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasasMacros;
  final String periodo;
  final String recordatorio24h;
  final String listaCompras;
  final String recetas;
  final String distribucionCalorias;
  final double aguaRecomendada;
}
