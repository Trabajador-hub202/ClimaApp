import 'package:flutter/material.dart';

class HourlyForecastWidget extends StatelessWidget {
  final String condition;
  final double currentTemp;
  final String city;
  final String accountType; // 'personal' o 'negocio'
  final String
  activity; // Ej: 'Estudiante', 'Deportista', 'Oficina', 'Turismo', 'Médico', 'Otro'
  final String schedule; // Horario de preferencia
  final bool showRecommendations;

  const HourlyForecastWidget({
    super.key,
    required this.condition,
    required this.currentTemp,
    required this.city,
    required this.accountType,
    required this.activity,
    required this.schedule,
    required this.showRecommendations,
  });

  // Iconos del clima según la condición de cada hora
  Widget _getWeatherIcon(String cond, double size) {
    switch (cond) {
      case 'Sunny':
        return Icon(Icons.wb_sunny, color: Colors.amber[300], size: size);
      case 'Cloudy':
        return Icon(Icons.cloud_queue, color: Colors.blue[100], size: size);
      case 'Rainy':
        return Icon(Icons.umbrella, color: Colors.blue[300], size: size);
      case 'Snowy':
        return Icon(Icons.ac_unit, color: Colors.lightBlue[100], size: size);
      case 'Hail':
        return Icon(Icons.grain, color: Colors.teal[200], size: size);
      default:
        return Icon(Icons.wb_sunny, color: Colors.amber[300], size: size);
    }
  }

  // Generar datos deterministas para las próximas 8 horas
  List<Map<String, dynamic>> _generateHourlyData() {
    final startHour = DateTime.now().hour;
    final List<Map<String, dynamic>> list = [];
    int hash = city.length * 7;

    for (int i = 1; i <= 8; i++) {
      final hourVal = (startHour + i) % 24;
      final ampm = hourVal >= 12 ? 'PM' : 'AM';
      final displayHour = hourVal == 0
          ? 12
          : hourVal > 12
          ? hourVal - 12
          : hourVal;
      final timeStr = "$displayHour:00 $ampm";

      String hourCond = 'Sunny';
      int rainProb = 0;
      final seed = (hash + hourVal * i * 3) % 100;

      if (condition == 'Sunny') {
        hourCond = seed < 70 ? 'Sunny' : 'Cloudy';
        rainProb = seed % 12;
      } else if (condition == 'Cloudy') {
        hourCond = seed < 65 ? 'Cloudy' : (seed < 85 ? 'Sunny' : 'Rainy');
        rainProb = 15 + (seed % 25);
      } else if (condition == 'Rainy') {
        hourCond = seed < 80 ? 'Rainy' : 'Cloudy';
        rainProb = 60 + (seed % 35);
      } else if (condition == 'Snowy') {
        hourCond = seed < 80 ? 'Snowy' : 'Cloudy';
        rainProb = 40 + (seed % 40);
      } else {
        hourCond = seed < 75 ? 'Hail' : 'Rainy';
        rainProb = 55 + (seed % 30);
      }

      final tempVar =
          (seed % 5) - 2; // Variación pequeña de temperatura (-2 a +2)

      list.add({
        'time': timeStr,
        'condition': hourCond,
        'temp': (currentTemp + tempVar).toStringAsFixed(1),
        'precip': rainProb,
      });
    }
    return list;
  }

  // Generar recomendación inteligente según la personalización
  Map<String, String> _getSmartRecommendation(String trend) {
    final actLower = activity.toLowerCase();

    if (accountType == 'personal') {
      if (actLower.contains('estud') || actLower == 'estudiante') {
        if (trend == 'sunny') {
          return {
            'title': 'Estudio al Aire Libre 📖',
            'text':
                'Próximas horas súper despejadas. Excelente para leer en áreas verdes o caminar hacia la biblioteca en tu horario de $schedule. ¡Aprovecha el día!',
          };
        } else if (trend == 'rainy') {
          return {
            'title': 'Estudio en Interiores ☕',
            'text':
                'Chubascos pronosticados. Te sugerimos quedarte en casa, estudiar en una cafetería techada y llevar paraguas obligatorio para tus clases de hoy.',
          };
        } else {
          return {
            'title': 'Clima de Concentración ✏️',
            'text':
                'Condiciones confortables y estables en las siguientes horas. Ideal para avanzar con tus proyectos académicos de forma productiva.',
          };
        }
      } else if (actLower.contains('deport') || actLower == 'deportista') {
        if (trend == 'sunny') {
          return {
            'title': 'Entrenamiento Exterior 🏃‍♂️',
            'text':
                '¡Día inmejorable para entrenar! Soleado y fresco. No olvides tu bloqueador solar e hidratación constante para tu sesión de $schedule.',
          };
        } else if (trend == 'rainy') {
          return {
            'title': 'Entrenamiento Indoor 🏋️',
            'text':
                'Alta probabilidad de lluvia. Te sugerimos mover tu rutina a interiores (gimnasio o casa) para prevenir resfriados y optimizar tu rendimiento.',
          };
        } else {
          return {
            'title': 'Clima Templado Óptimo 🚴',
            'text':
                'Sin temperaturas extremas ni riesgos de lluvia severa. Excelente clima para rodar o correr en tu horario favorito.',
          };
        }
      } else {
        // Genérico u "Otro"
        return {
          'title': 'Planifica tu Actividad 🌤️',
          'text':
              'Las condiciones meteorológicas son estables para realizar tu actividad de "$activity" en tus momentos de $schedule.',
        };
      }
    } else {
      // Negocio
      if (actLower.contains('comid') || actLower.contains('restaur')) {
        if (trend == 'sunny') {
          return {
            'title': 'Mesas al Aire Libre 🍔',
            'text':
                '¡Día soleado espectacular! Prepara tu terraza y destaca bebidas frías o menús ligeros en tus horas de $schedule para captar más comensales.',
          };
        } else if (trend == 'rainy') {
          return {
            'title': 'Promueve tu Delivery Delivery 🛵',
            'text':
                'Habrá lluvia intermitente; se espera menor tránsito peatonal físico. Lanza descuentos de envío a domicilio durante tu jornada de $schedule.',
          };
        } else {
          return {
            'title': 'Operación Regular Agradable 🍽️',
            'text':
                'Temperatura templada en camino. Asegura un espacio cálido y un buen servicio para los clientes que visiten hoy tu local.',
          };
        }
      } else {
        return {
          'title': 'Logística Comercial Activa 📈',
          'text':
              'Excelente día para promociones y operaciones de tu negocio de "$activity". Saca provecho del clima estable en tu horario de $schedule.',
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hourlyData = _generateHourlyData();

    // Determinar la tendencia del clima de hoy
    final rainCount = hourlyData
        .where((h) => h['condition'] == 'Rainy' || h['condition'] == 'Hail')
        .length;
    final sunnyCount = hourlyData
        .where((h) => h['condition'] == 'Sunny')
        .length;
    final trend = rainCount >= 3
        ? 'rainy'
        : (sunnyCount >= 4 ? 'sunny' : 'cloudy');

    final rec = _getSmartRecommendation(trend);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del widget
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.lightBlueAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRÓXIMAS HORAS (6-12H)',
                    style: TextStyle(
                      color: Colors.blue[50],
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Text(
                  'HOY',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LISTA HORIZONTAL (CARRUSEL)
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyData.length,
              itemBuilder: (context, index) {
                final hour = hourlyData[index];
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hour['time'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _getWeatherIcon(hour['condition'], 22),
                      const SizedBox(height: 4),
                      Text(
                        "${hour['temp']}°",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Probabilidad de precipitación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 7,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              "R: ${hour['precip']}%",
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // SECCIÓN DE RECOMENDACIONES DENTRO DEL MISMO WIDGET
          if (showRecommendations) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_incandescent,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SUGERENCIA DE PRÓXIMAS HORAS',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rec['text']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
