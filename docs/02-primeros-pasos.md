# 2. Primeros Pasos y Requisitos

En esta sección se describen los requerimientos mínimos del dispositivo y las configuraciones iniciales para comenzar a utilizar la aplicación móvil.

---

## 📱 Requisitos del Dispositivo

* **Sistema Operativo:**
  * Android 7.0 (API nivel 24) o superior.
  * iOS 12.0 o superior.
* **Conectividad:**
  * Conexión activa a Internet (Wi-Fi o datos móviles) para comunicarse con el servidor de inferencia Django.
* **Hardware recomendado:**
  * Cámara con enfoque automático y resolución mínima de 8 megapíxeles.
  * Sensor de posicionamiento satelital (GPS) integrado.

---

## 🔑 Permisos del Sistema

Al abrir la aplicación por primera vez o al usar funciones específicas, el sistema operativo solicitará los siguientes permisos:

| Permiso | Justificación | ¿Es obligatorio? |
| :--- | :--- | :--- |
| **Cámara** | Permite capturar fotografías directas de insectos o arácnidos en campo. | Sí (para toma en vivo) |
| **Galería / Fotos** | Permite seleccionar fotografías tomadas previamente en el dispositivo. | Opcional |
| **Ubicación (GPS)** | Obtiene las coordenadas geográficas (latitud y longitud) del avistamiento para situarlo en el mapa. | Opcional (se puede desactivar con un switch) |

> [!TIP]
> Si deniegas accidentalmente algún permiso, puedes habilitarlo en cualquier momento desde los **Ajustes / Configuración de Aplicaciones** de tu teléfono móvil.

---

## 🚀 Flujo de Inicio de la Aplicación

Al abrir la aplicación:

1. **Verificación de Sesión:** El sistema comprueba automáticamente si ya habías iniciado sesión previamente.
2. **Redirección Automática:**
   * **Si es la primera vez:** Serás recibido por la pantalla de **Inicio de Sesión** (`PantallaLogin`).
   * **Si ya iniciaste sesión:** Accederás directamente a la **Pantalla Principal** con tu sesión activa conservada.
