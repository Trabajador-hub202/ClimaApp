import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pronostico_del_clima/servicios/database_helper.dart';
import 'package:pronostico_del_clima/servicios/weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimaApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      home: const WeatherHomeScreen(),
    );
  }
}

enum AppScreen { login, questionnaire, search, weatherDetails }

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Campos de cuenta personal
  final TextEditingController _personalActivityController =
      TextEditingController(text: 'Estudiante');
  final TextEditingController _personalScheduleController =
      TextEditingController(text: 'Mañana (8:00 - 14:00)');
  bool _personalRecs = true;

  // Campos de cuenta de negocio
  final TextEditingController _businessScheduleController =
      TextEditingController(text: 'Lunes a Viernes (9:00 - 18:00)');
  String _businessCategory = 'Comida';
  bool _businessRecs = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  AppScreen _currentScreen = AppScreen.login;
  String _accountType = 'personal'; // 'personal' o 'negocio'
  String? _loginError;
  bool _isGoogleUser = false;
  bool _showBypassButton =
      false; // Permite omitir configuración de firmas SHA-1 en celular real

  List<String> _favorites = [];
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  bool _isLoadingGps = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Cargamos favoritos iniciales vacíos, se cargarán al iniciar sesión por correo
  }

  // Carga las ciudades de SQLite filtradas por correo
  Future<void> _loadFavoritesForUser(String email) async {
    final list = await _dbHelper.getFavorites(email);
    if (!mounted) return;
    setState(() {
      _favorites = list;
    });
  }

  // Conexión con Google Accounts en Flutter
  Future<void> _loginWithGoogle() async {
    setState(() {
      _loginError = null;
      _showBypassButton = false;
    });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        if (!mounted) return;
        setState(() {
          _emailController.text = account.email;
          _passwordController.text = 'google-oauth-session-token';
          _isGoogleUser = true;
          _currentScreen = AppScreen.questionnaire;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = "Error al conectar con Google: ${e.toString()}";
        _showBypassButton = true; // Activa botón de rescate/omitir
      });
    }
  }

  // Eliminar cuenta iniciada y sus datos SQLite de forma permanente
  Future<void> _deleteAccount() async {
    try {
      final email = _emailController.text.trim();

      // 1. Desconectar Google Sign In si está activo
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }

      // 2. Borrar favoritos del usuario actual en la base de datos local SQLite
      final db = await _dbHelper.database;
      await db.delete('favorites', where: 'email = ?', whereArgs: [email]);

      // 3. Eliminar SharedPreferences del perfil de este correo
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('skycast_${email}_has_profile');
      await prefs.remove('skycast_${email}_account_type');
      await prefs.remove('skycast_${email}_personal_activity');
      await prefs.remove('skycast_${email}_personal_schedule');
      await prefs.remove('skycast_${email}_personal_recs');
      await prefs.remove('skycast_${email}_business_schedule');
      await prefs.remove('skycast_${email}_business_category');
      await prefs.remove('skycast_${email}_business_recs');

      if (!mounted) return;

      // 4. Limpiar variables de estado de la sesión
      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _personalActivityController.text = 'Estudiante';
        _personalScheduleController.text = 'Mañana (8:00 - 14:00)';
        _businessScheduleController.text = 'Lunes a Viernes (9:00 - 18:00)';
        _favorites.clear();
        _weatherData = null;
        _isGoogleUser = false;
        _currentScreen = AppScreen.login;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta y datos locales eliminados permanentemente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar cuenta: $e')));
    }
  }

  // Buscar clima de ciudad
  Future<void> _searchWeather(String city) async {
    if (city.trim().isEmpty) {
      setState(() {
        _errorMessage = "Escribe el nombre de una ciudad";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
    });

    final data = await WeatherService.fetchWeatherByCity(city.trim());

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (data != null) {
        _weatherData = data;
        _currentScreen = AppScreen.weatherDetails; // Ir a la pantalla 4
        _cityController.clear(); // Limpia el buscador después de consultar
      } else {
        _errorMessage = "No se encontraron datos para '$city'";
      }
    });
  }

  // Usar GPS real del celular con Geolocator
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingGps = true;
      _errorMessage = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Permiso de ubicación denegado permanentemente";
          _isLoadingGps = false;
        });
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        if (!mounted) return;

        final data = await WeatherService.fetchWeatherByCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;
        setState(() {
          if (data != null) {
            _weatherData = data;
            _cityController.text = data['name'] ?? "";
            _currentScreen = AppScreen.weatherDetails; // Ir a la pantalla 4
          } else {
            _errorMessage = "Error al obtener clima para tu ubicación GPS";
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error obteniendo GPS: ${e.toString()}";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingGps = false;
      });
    }
  }

  // Agregar ciudad actual a favoritas (SQLite)
  Future<void> _addCityToFavorites() async {
    if (_weatherData == null) return;
    final cityName = _weatherData!['name'];
    final email = _emailController.text.trim();
    if (cityName != null && email.isNotEmpty) {
      await _dbHelper.insertFavorite(cityName, email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$cityName guardada en favoritas SQLite')),
      );
      _loadFavoritesForUser(email);
    }
  }

  // Eliminar favorita (SQLite)
  Future<void> _removeCityFromFavorites(String cityName) async {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      await _dbHelper.deleteFavorite(cityName, email);
      if (!mounted) return;
      _loadFavoritesForUser(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$cityName eliminada de favoritas')),
      );
    }
  }

  Widget _buildWeatherIcon(String? condition, double size) {
    IconData iconData = Icons.wb_sunny;
    Color color = Colors.amber;
    if (condition == 'Cloudy') {
      iconData = Icons.cloud;
      color = Colors.lightBlueAccent;
    } else if (condition == 'Rainy') {
      iconData = Icons.beach_access;
      color = Colors.blue;
    } else if (condition == 'Snowy') {
      iconData = Icons.ac_unit;
      color = Colors.lightBlue;
    } else if (condition == 'Hail') {
      iconData = Icons.cloudy_snowing;
      color = Colors.tealAccent;
    }
    return Icon(iconData, size: size, color: color);
  }

  // Completar inicio de sesión en Flutter
  Future<void> _submitLogin() async {
    setState(() {
      _loginError = null;
    });
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _loginError = "Por favor escribe tu correo y contraseña";
      });
      return;
    }
    if (!email.contains('@')) {
      setState(() {
        _loginError = "Por favor escribe un correo válido";
      });
      return;
    }

    // --- LÓGICA DE CUENTAS INDEPENDIENTES (SharedPreferences) ---
    final prefs = await SharedPreferences.getInstance();
    final alreadyExists =
        prefs.getBool('skycast_${email}_has_profile') ?? false;

    if (alreadyExists) {
      setState(() {
        _accountType =
            prefs.getString('skycast_${email}_account_type') ?? 'personal';
        _personalActivityController.text =
            prefs.getString('skycast_${email}_personal_activity') ??
            'Estudiante';
        _personalScheduleController.text =
            prefs.getString('skycast_${email}_personal_schedule') ??
            'Mañana (8:00 - 14:00)';
        _personalRecs = prefs.getBool('skycast_${email}_personal_recs') ?? true;
        _businessScheduleController.text =
            prefs.getString('skycast_${email}_business_schedule') ??
            'Lunes a Viernes (9:00 - 18:00)';
        _businessCategory =
            prefs.getString('skycast_${email}_business_category') ?? 'Comida';
        _businessRecs = prefs.getBool('skycast_${email}_business_recs') ?? true;

        _currentScreen = AppScreen.search; // Ingresa directo al panel
      });
      _loadFavoritesForUser(email);
    } else {
      // Nuevo usuario: debe personalizar
      setState(() {
        _currentScreen = AppScreen.questionnaire;
      });
    }
  }

  // Completar cuestionario de personalización en Flutter
  Future<void> _submitQuestionnaire() async {
    setState(() {
      _loginError = null;
    });
    final email = _emailController.text.trim();
    if (_accountType == 'personal') {
      if (_personalActivityController.text.trim().isEmpty ||
          _personalScheduleController.text.trim().isEmpty) {
        setState(() {
          _loginError =
              "Por favor completa todas las preguntas de tu cuenta Personal";
        });
        return;
      }
    } else {
      if (_businessScheduleController.text.trim().isEmpty) {
        setState(() {
          _loginError =
              "Por favor completa el horario de funcionamiento de tu negocio";
        });
        return;
      }
    }

    // --- GUARDAR PERSONALIZACIÓN PARA ESTA CUENTA ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skycast_${email}_has_profile', true);
    await prefs.setString('skycast_${email}_account_type', _accountType);
    if (_accountType == 'personal') {
      await prefs.setString(
        'skycast_${email}_personal_activity',
        _personalActivityController.text,
      );
      await prefs.setString(
        'skycast_${email}_personal_schedule',
        _personalScheduleController.text,
      );
      await prefs.setBool('skycast_${email}_personal_recs', _personalRecs);
    } else {
      await prefs.setString(
        'skycast_${email}_business_schedule',
        _businessScheduleController.text,
      );
      await prefs.setString(
        'skycast_${email}_business_category',
        _businessCategory,
      );
      await prefs.setBool('skycast_${email}_business_recs', _businessRecs);
    }

    _loadFavoritesForUser(email);
    setState(() {
      _currentScreen = AppScreen.search;
    });
  }

  Widget _buildLoginWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle,
            size: 64,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Personaliza tu cuenta de clima',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.email, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 14),
            Text(
              _loginError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (_showBypassButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _emailController.text = "test_google_bypass@skycast.com";
                    _passwordController.text = "google-oauth-bypass-active";
                    _isGoogleUser = true;
                    _loginError = null;
                    _currentScreen = AppScreen.questionnaire;
                  });
                },
                icon: const Icon(Icons.flash_on, color: Colors.amber),
                label: const Text(
                  'Omitir Error e Iniciar Modo Demo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Siguiente: Personalizar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'O',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
              Expanded(child: Divider(color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loginWithGoogle,
              icon: const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: Colors.white,
              ),
              label: const Text(
                'Conectar con Google',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _emailController.text = "invitado_rapido@skycast.com";
                _passwordController.text = "google-oauth-invitado-directo";
                _isGoogleUser = true;
                _currentScreen = AppScreen.questionnaire;
              });
            },
            child: const Text(
              '¿Problemas con Google? Iniciar Modo Demo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Personalización',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Tipo de cuenta?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _accountType = 'personal'),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Personal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accountType == 'personal'
                        ? Colors.blueAccent
                        : Colors.white12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _accountType = 'negocio'),
                  icon: const Icon(Icons.store, size: 16),
                  label: const Text('Negocio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accountType == 'negocio'
                        ? Colors.blueAccent
                        : Colors.white12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_accountType == 'personal') ...[
            DropdownButtonFormField<String>(
              value:
                  [
                    'Estudiante',
                    'Deportista',
                    'Oficina',
                    'Turismo',
                    'Médico',
                    'Otro',
                  ].contains(_personalActivityController.text)
                  ? _personalActivityController.text
                  : 'Estudiante',
              dropdownColor: Colors.blueGrey[950],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '¿A qué te dedicas?',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items:
                  [
                        'Estudiante',
                        'Deportista',
                        'Oficina',
                        'Turismo',
                        'Médico',
                        'Otro',
                      ]
                      .map(
                        (act) => DropdownMenuItem(
                          value: act,
                          child: Text(
                            act,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(
                () => _personalActivityController.text = val ?? 'Estudiante',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value:
                  [
                    'Mañana (8:00 - 14:00)',
                    'Tarde (14:00 - 20:00)',
                    'Noche (20:00 - 00:00)',
                    'Todo el día',
                  ].contains(_personalScheduleController.text)
                  ? _personalScheduleController.text
                  : 'Mañana (8:00 - 14:00)',
              dropdownColor: Colors.blueGrey[950],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '¿En qué horario realizas estas actividades?',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items:
                  [
                        'Mañana (8:00 - 14:00)',
                        'Tarde (14:00 - 20:00)',
                        'Noche (20:00 - 00:00)',
                        'Todo el día',
                      ]
                      .map(
                        (sch) => DropdownMenuItem(
                          value: sch,
                          child: Text(
                            sch,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(
                () => _personalScheduleController.text =
                    val ?? 'Mañana (8:00 - 14:00)',
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '¿Deseas recibir recomendaciones en tiempo real?',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              value: _personalRecs,
              onChanged: (val) => setState(() => _personalRecs = val),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              value:
                  [
                    'Lunes a Viernes (9:00 - 18:00)',
                    'Lunes a Sábado (8:00 - 20:00)',
                    'Fines de Semana',
                    '24 Horas',
                  ].contains(_businessScheduleController.text)
                  ? _businessScheduleController.text
                  : 'Lunes a Viernes (9:00 - 18:00)',
              dropdownColor: Colors.blueGrey[950],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '¿En qué horarios funciona el negocio?',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items:
                  [
                        'Lunes a Viernes (9:00 - 18:00)',
                        'Lunes a Sábado (8:00 - 20:00)',
                        'Fines de Semana',
                        '24 Horas',
                      ]
                      .map(
                        (sch) => DropdownMenuItem(
                          value: sch,
                          child: Text(
                            sch,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(
                () => _businessScheduleController.text =
                    val ?? 'Lunes a Viernes (9:00 - 18:00)',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _businessCategory,
              dropdownColor: Colors.blueGrey[950],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Categoría del negocio',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items:
                  [
                        'Comida',
                        'Deportes',
                        'Trabajo',
                        'Hospital',
                        'Construcción',
                        'Turismo',
                        'Otro',
                      ]
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) =>
                  setState(() => _businessCategory = val ?? 'Comida'),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '¿Desea recibir recomendaciones en tiempo real?',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              value: _businessRecs,
              onChanged: (val) => setState(() => _businessRecs = val),
            ),
          ],
          if (_loginError != null) ...[
            const SizedBox(height: 14),
            Text(
              _loginError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _currentScreen = AppScreen.login),
                  child: const Text(
                    'Atrás',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitQuestionnaire,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Completar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSuggestionWidget() {
    if (_weatherData == null) return const SizedBox.shrink();
    final String condition = _weatherData!['condition'] ?? 'Sunny';

    String advice = '';
    if (_accountType == 'personal' && _personalRecs) {
      final activity = _personalActivityController.text;
      final schedule = _personalScheduleController.text;
      if (condition == 'Sunny') {
        advice =
            '☀️ El clima es excelente. ¡Ideal para realizar tus actividades de $activity en tu horario de $schedule!';
      } else if (condition == 'Cloudy') {
        advice =
            '☁️ Cielo nublado y fresco. Clima perfecto para tus labores de $activity ($schedule) sin sofocarse.';
      } else if (condition == 'Rainy') {
        advice =
            '🌧️ Alerta de lluvia para tu horario de $schedule. Recuerda llevar paraguas para tus actividades de $activity.';
      } else if (condition == 'Snowy') {
        advice =
            '❄️ Frío extremo y nieve. Mantente abrigado al salir a tus actividades de $activity.';
      } else if (condition == 'Hail') {
        advice =
            '🌨️ Tormenta de granizo detectada. Por seguridad, permanece en interiores.';
      }
    } else if (_accountType == 'negocio' && _businessRecs) {
      final category = _businessCategory;
      final schedule = _businessScheduleController.text;
      if (condition == 'Sunny') {
        advice =
            '☀️ Día soleado. Gran afluencia de clientes en calle en tu horario de $schedule; impulsa promociones presenciales para tu negocio de $category.';
      } else if (condition == 'Cloudy') {
        advice =
            '☁️ Cielo cubierto. Temperatura ideal para visitas cómodas de clientes a tu negocio de $category.';
      } else if (condition == 'Rainy') {
        advice =
            '🌧️ Día de lluvias. Podrían bajar visitas físicas a tu local de $category; buen momento para incentivar delivery.';
      } else if (condition == 'Snowy') {
        advice =
            '❄️ Clima gélido. Enciende calefacción en tienda para tu categoría de $category y ofrece té caliente.';
      } else if (condition == 'Hail') {
        advice =
            '🌨️ Granizo severo. Asegura toldos, techos y resguarda mercancía exterior de tu negocio de $category.';
      }
    }

    if (advice.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                'Sugerencia ClimaApp (${_accountType == "personal" ? "Personal" : "Negocio"})',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            advice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastWidget() {
    final int startHour = DateTime.now().hour;
    final String condition = _weatherData!['condition'] ?? 'Sunny';
    final String cityName = _weatherData!['name'] ?? '';
    int cityHash = 0;
    for (int i = 0; i < cityName.length; i++) {
      cityHash += cityName.codeUnitAt(i);
    }

    final List<Map<String, dynamic>> hours = [];
    for (int i = 1; i <= 8; i++) {
      final int hr = (startHour + i) % 24;
      final String ampm = hr >= 12 ? 'PM' : 'AM';
      final int displayHour = hr == 0
          ? 12
          : hr > 12
          ? hr - 12
          : hr;
      final String timeString = "$displayHour:00 $ampm";

      String hrCondition = 'Sunny';
      int precipProb = 0;
      final int seedVal = (cityHash + hr * i * 7) % 100;

      if (condition == 'Sunny') {
        if (seedVal < 70) {
          hrCondition = 'Sunny';
          precipProb = (cityHash + hr) % 12;
        } else {
          hrCondition = 'Cloudy';
          precipProb = 10 + ((cityHash + hr) % 15);
        }
      } else if (condition == 'Cloudy') {
        if (seedVal < 60) {
          hrCondition = 'Cloudy';
          precipProb = 10 + ((cityHash + hr) % 25);
        } else if (seedVal < 85) {
          hrCondition = 'Sunny';
          precipProb = (cityHash + hr) % 10;
        } else {
          hrCondition = 'Rainy';
          precipProb = 40 + ((cityHash + hr) % 20);
        }
      } else {
        if (seedVal < 60) {
          hrCondition = condition;
          precipProb = 70 + ((cityHash + hr) % 25);
        } else {
          hrCondition = 'Cloudy';
          precipProb = 40 + ((cityHash + hr) % 25);
        }
      }

      hours.add({
        'time': timeString,
        'condition': hrCondition,
        'precip': "$precipProb%",
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximas Horas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: hours.length,
            itemBuilder: (context, index) {
              final h = hours[index];
              return Container(
                width: 85,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      h['time'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildWeatherIcon(h['condition'], 24),
                    const SizedBox(height: 6),
                    Text(
                      "🌧️ ${h['precip']}",
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeatherDetailsWidget() {
    if (_weatherData == null) return const SizedBox.shrink();
    final bool isFavorite = _favorites.contains(_weatherData!['name']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentScreen = AppScreen.search;
                });
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('ATRÁS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PANTALLA 4: Clima actual de la ciudad
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text(
                  _weatherData!['name'] ?? 'Ciudad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWeatherIcon(_weatherData!['condition'], 64),
                const SizedBox(height: 12),
                Text(
                  "${_weatherData!['temp']}°C",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weatherData!['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sugerencia de Clima Personalizada según la Cuenta
          _buildWeatherSuggestionWidget(),

          // Carrusel de Pronóstico por Horas (Requested in Request 1)
          _buildHourlyForecastWidget(),

          // Pronóstico de los próximos 3 días (3 Cartas)
          const Text(
            'Próximos 3 Días',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var f in (_weatherData!['forecast'] as List? ?? []).take(3))
                Expanded(
                  child: Card(
                    color: Colors.white.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        children: [
                          Text(
                            f['day'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildWeatherIcon(f['condition'], 24),
                          const SizedBox(height: 6),
                          Text(
                            "Min: ${f['minTemp']}°",
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "Max: ${f['maxTemp']}°",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón abajo para agregar a favorito
          ElevatedButton.icon(
            onPressed: () {
              if (isFavorite) {
                _removeCityFromFavorites(_weatherData!['name']);
              } else {
                _addCityToFavorites();
              }
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            label: Text(
              isFavorite
                  ? 'Eliminar de Favoritos SQLite'
                  : 'Agregar a Favoritos SQLite',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFavorite ? Colors.pink : Colors.white,
              foregroundColor: isFavorite ? Colors.white : Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchWidget() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ClimaApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    "Hola, ${_emailController.text.split('@')[0]}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _currentScreen = AppScreen.login;
                        _emailController.clear();
                        _passwordController.clear();
                        _weatherData = null;
                      });
                    },
                    tooltip: 'Cerrar sesión',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    onPressed: _deleteAccount,
                    tooltip: 'Eliminar cuenta de Google y SQLite',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Buscador de ciudades (Pantalla 3)
          TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar ciudad...',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.location_city,
                color: Colors.white70,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.25),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Botones de Buscar y GPS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _searchWeather(_cityController.text),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'Buscar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoadingGps ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoadingGps
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.gps_fixed),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mensaje de Error si hay
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // SECCIÓN DE FAVORITOS (SQLite)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Mis Favoritas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SQLite DB',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _favorites.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'Aún no tienes favoritas en SQLite',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final city = _favorites[index];
                          return Card(
                            color: Colors.white.withOpacity(0.08),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                city,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _removeCityFromFavorites(city),
                              ),
                              onTap: () {
                                _cityController.text = city;
                                _searchWeather(city);
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de fondo para pantalla de inicio (Requerido)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradiente oscuro superpuesto para mejorar legibilidad
          Container(color: Colors.black.withOpacity(0.5)),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _currentScreen == AppScreen.login
                ? Center(
                    child: SingleChildScrollView(child: _buildLoginWidget()),
                  )
                : _currentScreen == AppScreen.questionnaire
                ? Center(
                    child: SingleChildScrollView(
                      child: _buildQuestionnaireWidget(),
                    ),
                  )
                : _currentScreen == AppScreen.weatherDetails
                ? _buildWeatherDetailsWidget()
                : _buildSearchWidget(),
          ),
        ],
      ),
    );
  }
}
