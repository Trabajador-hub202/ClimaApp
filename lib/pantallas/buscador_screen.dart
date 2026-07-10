import 'package:flutter/material.dart';
import 'package:pronostico_del_clima/modelos/perfil_usuario.dart';
import 'package:pronostico_del_clima/pantallas/clima_detalle_screen.dart';

class BuscadorScreen extends StatefulWidget {
  final PerfilUsuario perfil;
  const BuscadorScreen({super.key, required this.perfil});

  @override
  State<BuscadorScreen> createState() => _BuscadorScreenState();
}

class _BuscadorScreenState extends State<BuscadorScreen> {
  final _searchController = TextEditingController();

  // Favoritos de prueba (puedes unirlos con tu SQLite real)
  final List<Map<String, dynamic>> _favoritos = [
    {'ciudad': 'London', 'temp': 14.5, 'condicion': 'Rainy'},
    {'ciudad': 'Miami', 'temp': 28.0, 'condicion': 'Sunny'},
    {'ciudad': 'Madrid', 'temp': 22.4, 'condicion': 'Cloudy'},
  ];

  void _verClima(String ciudad, double temp, String condicion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClimaDetalleScreen(
          ciudad: ciudad,
          temp: temp,
          condicion: condicion,
          perfil: widget.perfil,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111E25),
      appBar: AppBar(
        title: const Text(
          'Escriba una ciudad',
          style: TextStyle(color: Colors.black),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscador y GPS
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ej. Madrid, Bogotá...',
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          _verClima(text, 20.0, 'Sunny');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () {
                      // Simular geolocalización GPS
                      _verClima('Mi Ubicación (GPS)', 18.5, 'Cloudy');
                    },
                    icon: const Icon(Icons.my_location),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(50, 50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Tus Ciudades Favoritas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _favoritos.length,
                  itemBuilder: (context, index) {
                    final fav = _favoritos[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          fav['ciudad'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Estado: ${fav['condicion']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          '${fav['temp']}°C',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _verClima(
                          fav['ciudad'],
                          fav['temp'],
                          fav['condicion'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
