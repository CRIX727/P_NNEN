class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.contenido,
    required this.leida,
    required this.creadaEn,
  });

  final int id;
  final String tipo;
  final String titulo;
  final String contenido;
  final bool leida;
  final String creadaEn;
}
