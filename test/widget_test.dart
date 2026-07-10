// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronostico_del_clima/main.dart'; // Reemplaza 'pronostico_del_clima' con el nombre exacto de tu paquete si es diferente

void main() {
  testWidgets('SkyCast login screen compilation and render test', (
    WidgetTester tester,
  ) async {
    // Construye la aplicación principal (MyApp) y dispara un frame.
    await tester.pumpWidget(const MyApp());

    // Verifica que la pantalla de inicio de sesión de SkyCast cargue correctamente
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Correo y Contraseña
  });
}
