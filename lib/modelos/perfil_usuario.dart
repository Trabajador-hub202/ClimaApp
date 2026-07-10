class PerfilUsuario {
  String tipoCuenta; // 'personal' o 'negocio'
  String actividad; // 'Estudiante', 'Deportista', 'Oficina', etc.
  String horario; // 'Mañana', 'Tarde', 'Noche'
  bool mostrarRecomendaciones;

  PerfilUsuario({
    required this.tipoCuenta,
    required this.actividad,
    required this.horario,
    required this.mostrarRecomendaciones,
  });
}
