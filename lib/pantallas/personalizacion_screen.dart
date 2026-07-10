import 'package:flutter/material.dart';
import 'package:pronostico_del_clima/modelos/perfil_usuario.dart';
import 'package:pronostico_del_clima/pantallas/buscador_screen.dart';

class PersonalizacionScreen extends StatefulWidget {
  const PersonalizacionScreen({super.key});

  @override
  State<PersonalizacionScreen> createState() => _PersonalizacionScreenState();
}

class _PersonalizacionScreenState extends State<PersonalizacionScreen> {
  String _tipoCuenta = 'personal'; // 'personal' o 'negocio'
  String _actividadSeleccionada = 'Estudiante';
  String _horario = 'Mañana';
  bool _mostrarRecomendaciones = true;

  final List<String> _actividadesPersonales = [
    'Estudiante',
    'Deportista',
    'Oficina',
    'Turismo',
    'Médico',
    'Otro',
  ];
  final List<String> _actividadesNegocio = [
    'Comida',
    'Deportes',
    'Trabajo',
    'Hospital',
    'Construcción',
    'Turismo',
    'Otro',
  ];

  void _guardarPerfil() {
    final perfil = PerfilUsuario(
      tipoCuenta: _tipoCuenta,
      actividad: _actividadSeleccionada,
      horario: _horario,
      mostrarRecomendaciones: _mostrarRecomendaciones,
    );

    // Navegamos a la pantalla de Buscador pasando el perfil configurado
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BuscadorScreen(perfil: perfil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> actividades = _tipoCuenta == 'personal'
        ? _actividadesPersonales
        : _actividadesNegocio;

    return Scaffold(
      backgroundColor: const Color(0xFF111E25),
      appBar: AppBar(
        title: const Text('Personaliza tu Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Cómo usarás SkyCast?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Personal')),
                        selected: _tipoCuenta == 'personal',
                        onSelected: (val) {
                          setState(() {
                            _tipoCuenta = 'personal';
                            _actividadSeleccionada = 'Estudiante';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Negocio')),
                        selected: _tipoCuenta == 'negocio',
                        onSelected: (val) {
                          setState(() {
                            _tipoCuenta = 'negocio';
                            _actividadSeleccionada = 'Comida';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  _tipoCuenta == 'personal'
                      ? 'Tu Actividad Principal:'
                      : 'Categoría de tu Negocio:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: actividades.map((act) {
                    final isSelected = _actividadSeleccionada == act;
                    return ChoiceChip(
                      label: Text(act),
                      selected: isSelected,
                      selectedColor: Colors.lightBlueAccent,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.lightBlueAccent
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _actividadSeleccionada = act);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Horario de Preferencia:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _horario,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  items: ['Mañana', 'Tarde', 'Noche'].map((h) {
                    return DropdownMenuItem(value: h, child: Text(h));
                  }).toList(),
                  onChanged: (val) => setState(() => _horario = val!),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text(
                    'Mostrar Recomendaciones Inteligentes',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Sugerencias basadas en el clima y tu actividad',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  value: _mostrarRecomendaciones,
                  activeThumbColor: Colors.lightBlueAccent,
                  onChanged: (val) =>
                      setState(() => _mostrarRecomendaciones = val),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Guardar y Continuar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
