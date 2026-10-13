# 6. Detalle de Detección y Visor Fullscreen

La **Pantalla de Detalle de Detección** ofrece una vista exhaustiva e interactiva de cada espécimen analizado por el sistema.

---

## Inspección de la Fotografía y Cajas Delimitadoras

En la sección superior se muestra la imagen con las cajas de detección (*bounding boxes*) renderizadas sobre cada artrópodo localizado:

* **Borde Verde Neón Adaptativo:** El grosor de la línea se adapta matemáticamente a la resolución de tu pantalla (~2.5 px visuales) para verse siempre nítido y definido.
* **Insignias con Clase y Confianza:** Cada caja cuenta con una etiqueta oscura redondeada con texto de alto contraste que indica el orden predicho y la certidumbre (ej. `Lepidoptera 95%`).
* **Filtro de Cajas Visibles:** Si la fotografía contiene múltiples artrópodos (ej. 3 abejas), encontrarás botones tipo chip para encender o apagar la visualización de cajas individuales.

---

## Visor en Pantalla Completa con Zoom

Al tocar la fotografía en cualquier parte, se abrirá el **Visor de Pantalla Completa**:

* **Fondo Negro Inmersivo:** Diseñado para apreciar detalles morfológicos finos del espécimen.
* **Gesto de Pellizco (*Pinch-to-zoom*):** Haz zoom con dos dedos de forma fluida hasta **6x** para examinar alas, antenas o patas.
* **Doble Toque (*Double-tap zoom*):** Da dos toques rápidos sobre cualquier área del insecto para hacer un zoom automático de **2.5x** centrado en ese punto exacto; haz doble toque nuevamente para restaurar la vista completa.
* **Contador Flotante:** Una píldora superior te indica cuántos artrópodos están visibles en pantalla.
* **Botón Regresar:** Toca la flecha superior izquierda para volver al reporte de detalle.

---

## Información de la Captura y Artrópodos Detectados

Debajo de la imagen se despliegan los datos de la observación y el desglose de cada espécimen encontrado:

### 1. Metadatos de la Observación
* **Registrado por:** Nombre de usuario (`@username`) e institución a la que pertenece.
* **Fecha y Hora:** Fecha y hora en la que se tomó o subió la imagen (`DD/MM/AAAA - HH:MM`).
* **Ubicación:** Coordenadas de latitud y longitud satelitales (si se incluyó GPS al capturar), acompañadas del botón **"Ver en Mapa"** para ubicar el avistamiento geográficamente.

### 2. Tarjetas de Detección por Espécimen
Por cada artrópodo individual detectado en la fotografía, se muestra una tarjeta con:
* **Orden Identificado:** El orden biológico al que pertenece el ejemplar (por ejemplo, *Coleoptera*, *Lepidoptera*, *Araneae*, *Hymenoptera*, *Diptera*, *Hemiptera* u *Odonata*).
* **Insignia de Certeza:** Porcentaje numérico de confianza que indica la certidumbre calculada por el modelo MobileNetV3 (por ejemplo, `95.4%`).
* **Posición en Imagen:** Coordenadas de la caja delimitadora $(x_1, y_1) - (x_2, y_2)$ que indican la ubicación exacta del espécimen dentro de la fotografía.

---

## Eliminación de Registros

En la barra superior encontrarás un botón de papelera roja para **eliminar el avistamiento**:
* **Usuarios Observadores:** Pueden eliminar únicamente sus propias capturas.
* **Usuarios Administradores:** Pueden eliminar cualquier captura de la plataforma para moderar contenido no válido.
* Al confirmar la eliminación, el registro y la imagen se borran permanentemente de MongoDB y del disco del servidor.
