# 🌤️ ClimaApp
Aplicación móvil inteligente multiplataforma desarrollada bajo la metodología Vibe Coding. 
El sistema combina el procesamiento de lenguaje natural de modelos fundacionales para ofrecer recomendaciones contextuales de negocio basadas en el clima, gestionando la persistencia de datos de forma híbrida.
## 🔗 Demo en Vivo    
* 🎥 Demostración en Video: https://drive.google.com/file/d/1H-xkIfDBZLKbA4Iuh8wi_SM20o0Bguq_/view?usp=sharing 
## 🛠️ Stack Tecnológico & Arquitectura
* Framework & Lenguaje: Flutter (Dart)   
* Generative AI: Google AI Studio API (Gemini Models)
* Autenticación & Usuarios: Firebase Auth (Email & Google Sign-In)
* Base de Datos Local: SQLite (sqflite) para caché de favoritos.
* Geolocalización: geolocator para posicionamiento GPS en tiempo real.
## ⚙️ Funcionalidades Clave
* Onboarding Segmentado: Sistema de login híbrido que clasifica perfiles de usuario (Personal vs. Negocio), capturando categorías operacionales, actividades y ventanas horarias.
* Motor de Recomendaciones con IA: Integración con Google AI Studio para generar sugerencias inteligentes y dinámicas basadas en las condiciones meteorológicas y el giro del negocio.
* Módulo de Búsqueda y Geolocalización: Consumo asíncrono de APIs del clima con soporte para coordenadas GPS y carrusel de pronóstico horario extendido (7-8 horas).
* Persistencia y Privacidad: Base de datos SQLite local para la gestión eficiente de ciudades favoritas offline y funciones estrictas de borrado de cuenta (Cumplimiento GDPR/Privacidad).
