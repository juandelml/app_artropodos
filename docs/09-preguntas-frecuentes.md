# 9. Preguntas Frecuentes y Solución de Problemas

Encuentra aquí respuestas a las dudas más habituales sobre el funcionamiento de la aplicación.

---

## ❓ Preguntas Frecuentes (FAQ)

### 1. ¿Por qué la app dice "No se detectaron artrópodos" en mi foto?
Para garantizar la calidad de la base de datos de la investigación, el modelo YOLOv8 aplica un umbral de confianza mínimo. Si la fotografía está desenfocada, muy lejana, con sombras densas o el artrópodo se camufla excesivamente con el entorno, el sistema descartará la foto para no guardar datos erróneos.
* **Solución:** Acércate con la cámara (alrededor de 15 a 30 cm con macro o enfoque selectivo) y asegúrate de tener iluminación adecuada.

### 2. ¿Por qué mi captura no aparece en el mapa?
Los avistamientos se sitúan en el mapa únicamente si el interruptor **"Incluir ubicación GPS"** estaba encendido al momento de analizar la fotografía y si concediste el permiso de ubicación al teléfono.
* Si tomaste la foto en un sótano o lugar sin señal de satélites GPS, es posible que el teléfono no haya alcanzado a obtener coordenadas antes del tiempo límite de 15 segundos.

### 3. ¿Por qué en mi Historial solo veo mis capturas pero en el Mapa veo las de todos?
Este comportamiento es intencional por diseño:
* Tu **Historial** funciona como tu libreta de campo personal de observador, para que lleves control estricto de tu colección sin mezclarte con otros usuarios.
* El **Mapa**, en cambio, es una herramienta de ciencia ciudadana y biodiversidad comunitaria para que todos puedan saber qué artrópodos habitan en cada región.
*(Los usuarios con rol de Administrador sí pueden consultar el historial global de todos los usuarios mediante sus filtros de moderación).*

### 4. ¿Se guardan las fotos que no contienen artrópodos?
No. Si el sistema no detecta ningún artrópodo en la imagen, la foto **es descartada inmediatamente** y no ocupa espacio en tu historial ni en los servidores de MongoDB.

---

## 🛠️ Solución de Problemas Comunes

| Síntoma / Problema | Causa Probable | Solución Recomendada |
| :--- | :--- | :--- |
| **"Error de conexión con el servidor"** | El teléfono no tiene internet o el servidor Django está apagado/inaccesible en la red local. | Verifica tu conexión Wi-Fi/móvil y asegúrate de que la dirección IP del servidor esté configurada correctamente en los ajustes de la app. |
| **"Timeout: El servidor tardó más de 120s"** | La imagen es extremadamente pesada en píxeles o la conexión es muy lenta. | Intenta tomar la foto con una resolución estándar o reintenta con una red más estable. |
| **"Permiso de cámara o ubicación denegado permanentemente"** | Se seleccionó "No volver a preguntar" en el diálogo del sistema operativo. | Ve a Ajustes del teléfono ➔ Aplicaciones ➔ *Clasificador de Artrópodos* ➔ Permisos ➔ Activa Cámara y Ubicación. |
