class Alimento {
  const Alimento({
    required this.id,
    required this.nombre,
    required this.porcion,
    required this.calorias,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    this.fibra = 0,
    this.sodio = 0,
    this.azucar = 0,
    this.micronutrientes = '',
    this.sustituciones = '',
    this.condiciones = '',
    this.favorito = false,
    this.restringido = false,
  });

  final int id;
  final String nombre;
  final String porcion;
  final double calorias;
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final double fibra;
  final double sodio;
  final double azucar;
  final String micronutrientes;
  final String sustituciones;
  final String condiciones;
  final bool favorito;
  final bool restringido;
}
