# 1. Introducción al Proyecto

Este proyecto surge como parte del trabajo de tesis en el **Centro de Investigación en Matemáticas (CIMAT)** con la finalidad de democratizar el reconocimiento de artrópodos mediante visión por computadora aplicada en dispositivos móviles.

---

## Arquitectura del Sistema

El ecosistema se compone de dos componentes principales interconectados:

```
┌─────────────────────────────────┐           HTTP REST API (Token Auth)          ┌───────────────────────────────────┐
│     Aplicación Móvil Flutter    │ <===========================================> │          Backend en Django        │
│   (Android, iOS, Multiplataforma)│                                               │         (Django REST Framework)   │
└─────────────────────────────────┘                                               └───────────────────────────────────┘
                                                                                                    │
                                                                       ┌────────────────────────────┼────────────────────────────┐
                                                                       │                                                         │
                                                                       ▼                                                         ▼
                                                        ┌─────────────────────────────┐                           ┌─────────────────────────────┐
                                                        │      Modelos de IA (PyTorch) │                           │     Bases de Datos          │
                                                        │  1. YOLOv8s (Detección)     │                           │  - Relacional (Usuarios)    │
                                                        │  2. MobileNetV3 (Clasific.) │                           │  - MongoDB (Avistamientos)  │
                                                        └─────────────────────────────┘                           └─────────────────────────────┘
```

---

## Modelos de Inteligencia Artificial Empleados

Para lograr una identificación rápida y precisa, el servidor ejecuta una tubería (*pipeline*) híbrida de dos etapas:

### 1. Detección de Objetos (YOLOv8s)
* **Función:** Escanea la imagen completa en busca de artrópodos y genera las coordenadas rectangulares de cada ejemplar localizado ($x_1, y_1, x_2, y_2$).
* **Capacidad:** Puede detectar múltiples insectos o arácnidos en una sola toma.
* **Control de Calidad:** Si la imagen no contiene artrópodos o el fondo no muestra ningún espécimen válido, el sistema descarta la fotografía para evitar almacenar imágenes vacías en la base de datos.

### 2. Clasificación Taxonómica (MobileNetV3 Large)
* **Función:** Toma cada recorte de artrópodo detectado por YOLOv8 y lo procesa a través de una red neuronal convolucional profunda optimizada para dispositivos ligeros.
* **Órdenes clasificados:**
  1. **Araneae:** Arañas.
  2. **Coleoptera:** Escarabajos, catarinas y gorgojos.
  3. **Diptera:** Moscas, mosquitos y tábanos.
  4. **Hemiptera:** Chinches, pulgones y cigarras.
  5. **Hymenoptera:** Abejas, avispas y hormigas.
  6. **Lepidoptera:** Mariposas y polillas.
  7. **Odonata:** Libélulas y caballitos del diablo.

---

## Seguridad y Almacenamiento

* **Contraseñas Seguras:** Las credenciales de usuario se protegen mediante algoritmos de derivación de claves basados en PBKDF2 con sal y 1,000,000 de iteraciones.
* **Comunicación Segura:** Todas las peticiones autenticadas utilizan cabeceras `Authorization: Token <token>`.
* **Persistencia Georreferenciada:** Los avistamientos se almacenan en MongoDB con metadatos del usuario observador, fecha, coordenadas y recortes de imagen con el fin de enriquecer futuras investigaciones de biodiversidad.
