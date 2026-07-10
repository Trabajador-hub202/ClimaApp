import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Usamos la API pública y gratuita de Open-Meteo (No requiere API Key/Token)
  // ¡Funciona inmediatamente sin registros ni configuraciones adicionales!
  static const String geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String weatherUrl = 'https://api.open-meteo.com/v1/forecast';

  // Función para obtener clima buscando por nombre de ciudad
  static Future<Map<String, dynamic>?> fetchWeatherByCity(String city) async {
    try {
      // 1. Obtener coordenadas (Latitud/Longitud) desde el nombre de la ciudad
      final geoUri = Uri.parse(
        '$geocodingUrl?name=${Uri.encodeComponent(city)}&count=1&language=es&format=json',
      );
      final geoResponse = await http.get(geoUri);

      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        if (geoData['results'] != null && geoData['results'].isNotEmpty) {
          final firstResult = geoData['results'][0];
          final String resolvedName = firstResult['name'];
          final double lat = firstResult['latitude'];
          final double lon = firstResult['longitude'];

          // 2. Obtener el clima usando las coordenadas resueltas
          return await fetchWeatherByCoordinates(
            lat,
            lon,
            cityName: resolvedName,
          );
        }
      }

      // Si la API falla, usamos el simulador local para que la App nunca se rompa
      print(
        "Geocodificación falló o ciudad no encontrada. Usando respaldo simulado local.",
      );
      return _generateFallbackWeather(city);
    } catch (e) {
      print("Excepción en fetchWeatherByCity: $e. Usando respaldo simulado.");
      return _generateFallbackWeather(city);
    }
  }

  // Función para obtener clima directo con coordenadas Latitud/Longitud (GPS)
  static Future<Map<String, dynamic>?> fetchWeatherByCoordinates(
    double lat,
    double lon, {
    String? cityName,
  }) async {
    final weatherUri = Uri.parse(
      '$weatherUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto',
    );

    try {
      final response = await http.get(weatherUri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'];

        if (current == null) return null;

        final double temp = (current['temperature_2m'] as num).toDouble();
        final int wmoCode = current['weather_code'] as int;
        final int humidity = (current['relative_humidity_2m'] as num).toInt();
        final double windSpeed = (current['wind_speed_10m'] as num).toDouble();

        // Traducimos el código WMO de Open-Meteo a los estados de SkyCast
        final String condition = _mapWmoCodeToCondition(wmoCode);
        final String description = _mapWmoCodeToDescription(wmoCode);
        final String resolvedCityName =
            cityName ??
            "Ubicación GPS (${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";

        // Generar pronóstico de 3 días mapeado
        final List<Map<String, dynamic>> forecast = [];
        final List<String> days = [
          'Sáb',
          'Dom',
          'Lun',
          'Mar',
          'Mié',
          'Jue',
          'Vie',
        ];
        int todayIndex = DateTime.now().weekday; // 1 = Lunes, 7 = Domingo

        for (int i = 0; i < 3; i++) {
          final int dayIndex = (todayIndex + i) % 7;
          final String dayLabel = days[dayIndex];

          final int fcWmo = (daily['weather_code'][i] as num).toInt();
          final double fcMin = (daily['temperature_2m_min'][i] as num)
              .toDouble();
          final double fcMax = (daily['temperature_2m_max'][i] as num)
              .toDouble();

          forecast.add({
            'day': dayLabel,
            'minTemp': fcMin.round(),
            'maxTemp': fcMax.round(),
            'condition': _mapWmoCodeToCondition(fcWmo),
          });
        }

        // Devolvemos el mapa de datos exactamente con la estructura que espera la UI (main.dart)
        return {
          'name': resolvedCityName,
          'temp': temp.round(),
          'condition': condition,
          'description': description,
          'humidity': humidity,
          'windSpeed': windSpeed.round(),
          'forecast': forecast,
        };
      }
      return _generateFallbackWeather(cityName ?? "GPS");
    } catch (e) {
      print("Excepción al conectar con clima de Open-Meteo: $e");
      return _generateFallbackWeather(cityName ?? "GPS");
    }
  }

  // Mapeo de códigos WMO (Organización Meteorológica Mundial) a estados SkyCast
  static String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Sunny';
    if (code >= 1 && code <= 3) return 'Cloudy';
    if (code >= 45 && code <= 48) return 'Cloudy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 80 && code <= 82) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 85 && code <= 86) return 'Snowy';
    if (code >= 95 && code <= 99) return 'Hail';
    return 'Sunny';
  }

  static String _mapWmoCodeToDescription(int code) {
    if (code == 0) return 'Cielo despejado y brillante';
    if (code == 1) return 'Cielo mayormente despejado';
    if (code == 2) return 'Nubes dispersas';
    if (code == 3) return 'Cielo cubierto de nubes';
    if (code == 45 || code == 48) return 'Niebla y visibilidad reducida';
    if (code >= 51 && code <= 55) return 'Llovizna ligera continua';
    if (code >= 61 && code <= 65) return 'Chubascos de lluvia moderada';
    if (code >= 80 && code <= 82) return 'Lluvia intermitente y chubascos';
    if (code >= 71 && code <= 77) return 'Nevada y acumulación en suelo';
    if (code >= 95 && code <= 99) {
      return 'Tormenta eléctrica severa con granizo';
    }
    return 'Clima estable';
  }

  // Generador de respaldo determinista (Mock) idéntico al simulador React de la web.
  // ¡Garantiza que el usuario siempre tenga datos aunque no haya internet!
  static Map<String, dynamic> _generateFallbackWeather(String cityName) {
    final cleanCityName = cityName.trim();
    int hash = 0;
    for (int i = 0; i < cleanCityName.length; i++) {
      hash = cleanCityName.codeUnitAt(i) + ((hash << 5) - hash);
    }
    hash = hash.abs();

    final List<String> conditions = [
      'Sunny',
      'Cloudy',
      'Rainy',
      'Snowy',
      'Hail',
    ];
    final String condition = conditions[hash % conditions.length];

    int temp = 15;
    String description = '';
    if (condition == 'Sunny') {
      temp = 20 + (hash % 15);
      description = 'Cielo soleado y despejado (Simulado)';
    } else if (condition == 'Cloudy') {
      temp = 12 + (hash % 12);
      description = 'Nubes dispersas (Simulado)';
    } else if (condition == 'Rainy') {
      temp = 8 + (hash % 12);
      description = 'Intervalos de chubascos (Simulado)';
    } else if (condition == 'Snowy') {
      temp = -5 + (hash % 10);
      description = 'Nieve débil acumulada (Simulado)';
    } else {
      temp = 5 + (hash % 8);
      description = 'Cielo muy frío con granizo ocasional (Simulado)';
    }

    final String capitalizedCity = cleanCityName.isNotEmpty
        ? cleanCityName[0].toUpperCase() + cleanCityName.substring(1)
        : 'Ciudad';

    return {
      'name': capitalizedCity,
      'temp': temp,
      'condition': condition,
      'description': description,
      'humidity': 40 + (hash % 50),
      'windSpeed': 5 + (hash % 30),
      'forecast': [
        {
          'day': 'Sáb',
          'minTemp': temp - 4,
          'maxTemp': temp + 3,
          'condition': conditions[(hash + 1) % conditions.length],
        },
        {
          'day': 'Dom',
          'minTemp': temp - 3,
          'maxTemp': temp + 4,
          'condition': conditions[(hash + 2) % conditions.length],
        },
        {
          'day': 'Lun',
          'minTemp': temp - 5,
          'maxTemp': temp + 2,
          'condition': conditions[(hash + 3) % conditions.length],
        },
      ],
    };
  }
}
