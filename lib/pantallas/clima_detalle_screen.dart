import 'package:flutter/material.dart';
import 'package:pronostico_del_clima/modelos/perfil_usuario.dart';

class ClimaDetalleScreen extends StatelessWidget {
  final String ciudad;
  final double temp;
  final String condicion;
  final PerfilUsuario perfil;

  const ClimaDetalleScreen({
    super.key,
    required this.ciudad,
    required this.temp,
    required this.condicion,
    required this.perfil,
  });

  // Icono del clima
  IconData _getIcono(String cond) {
    switch (cond) {
      case 'Sunny':
        return Icons.wb_sunny_rounded;
      case 'Rainy':
        return Icons.umbrella_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  // Generador de recomendaciones dinámicas basadas en tu actividad
  Map<String, String> _obtenerRecomendacion() {
    final act = perfil.actividad.toLowerCase();
    if (act.contains('estud')) {
      return {
        'titulo': 'Estudio al Aire Libre 📖',
        'texto':
            'Las próximas horas se ven excelentes para estudiar en el campus o una cafetería cerca.',
      };
    } else if (act.contains('deport')) {
      return {
        'titulo': 'Rutina Deportiva 💪',
        'texto':
            'Clima ideal para realizar tus entrenamientos favoritos en tu horario de ${perfil.horario}.',
      };
    } else {
      return {
        'titulo': 'Planifica tu Actividad 🌤️',
        'texto':
            'Las condiciones climáticas son recomendadas para llevar a cabo tu actividad de "${perfil.actividad}" sin contratiempos.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final recomendacion = _obtenerRecomendacion();

    return Scaffold(
      backgroundColor: const Color(0xFF111E25),
      appBar: AppBar(
        title: const Text('Pronóstico del Clima'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.yellow),
            onPressed: () {
              // Lógica de SQLite para añadir a favoritos
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Tarjeta Clima Principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Text(
                      ciudad,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIcono(condicion),
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          condicion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // CARRUSEL VERTICAL/HORIZONTAL DE PRÓXIMAS HORAS (6 a 12 horas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.lightBlueAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PRÓXIMAS HORAS (6-12H)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Lista Horizontal (El Carrusel solicitado)
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8, // Genera 8 horas
                        itemBuilder: (context, index) {
                          final hora = index + 1;
                          final probLluvia = (index * 15) % 100;
                          return Container(
                            width: 75,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$hora:00 PM',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Icon(
                                  Icons.beach_access_rounded,
                                  color: Colors.lightBlueAccent,
                                  size: 20,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Rain: $probLluvia%',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SUGERENCIA DE PERSONALIZACIÓN
              if (perfil.mostrarRecomendaciones)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orangeAccent, Colors.deepPurpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SUGERENCIA PERSONALIZADA',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recomendacion['titulo']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recomendacion['texto']!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 25),

              // PRÓXIMOS 3 DÍAS
              const Text(
                'PRÓXIMOS 3 DÍAS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(3, (index) {
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.amber,
                    ),
                    title: Text(
                      'Día ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Text(
                      '24°C / 18°C',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
