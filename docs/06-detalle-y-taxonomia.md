# 6. Detalle de Detección y Visor Fullscreen

La **Pantalla de Detalle de Detección** ofrece una vista exhaustiva e interactiva de cada espécimen analizado por el sistema.

---

## 🖼️ Inspección de la Fotografía y Cajas Delimitadoras

En la sección superior se muestra la imagen con las cajas de detección (*bounding boxes*) renderizadas sobre cada artrópodo localizado:

* **Borde Verde Neón Adaptativo:** El grosor de la línea se adapta matemáticamente a la resolución de tu pantalla (~2.5 px visuales) para verse siempre nítido y definido.
* **Insignias con Clase y Confianza:** Cada caja cuenta con una etiqueta oscura redondeada con texto de alto contraste que indica el orden predicho y la certidumbre (ej. `Lepidoptera 95%`).
* **Filtro de Cajas Visibles:** Si la fotografía contiene múltiples artrópodos (ej. 3 abejas), encontrarás botones tipo chip para encender o apagar la visualización de cajas individuales.

---

## 🔍 Visor en Pantalla Completa con Zoom

Al tocar la fotografía en cualquier parte, se abrirá el **Visor de Pantalla Completa**:

* **Fondo Negro Inmersivo:** Diseñado para apreciar detalles morfológicos finos del espécimen.
* **Gesto de Pellizco (*Pinch-to-zoom*):** Haz zoom con dos dedos de forma fluida hasta **6x** para examinar alas, antenas o patas.
* **Doble Toque (*Double-tap zoom*):** Da dos toques rápidos sobre cualquier área del insecto para hacer un zoom automático de **2.5x** centrado en ese punto exacto; haz doble toque nuevamente para restaurar la vista completa.
* **Contador Flotante:** Una píldora superior te indica cuántos artrópodos están visibles en pantalla.
* **Botón Regresar:** Toca la flecha superior izquierda para volver al reporte de detalle.

---

## 📋 Ficha Taxonómica y Datos de Campo

Debajo de la imagen se despliega la ficha biológica estructurada:

### 1. Metadatos de la Observación
* **Autor:** Nombre de usuario (`@username`) e institución.
* **Fecha y Hora:** Formato local legible (`DD/MM/AAAA - HH:MM`).
* **Coordenadas Satelitales:** Latitud y longitud con botón para situar la captura en el mapa.

### 2. Clasificación Jerárquica
Por cada artrópodo detectado se desglosa su árbol taxonómico:
* **Reino:** *Animalia*
* **Filo:** *Arthropoda*
* **Clase:** *Insecta* (para insectos de 6 patas) o *Arachnida* (para arañas de 8 patas).
* **Orden:** Nombre científico y nombre común en español.
* **Barra de Certeza:** Gráfico proporcional que ilustra la probabilidad calculada por la red MobileNetV3.

---

## 🗑️ Eliminación de Registros

En la barra superior encontrarás un botón de papelera roja para **eliminar el avistamiento**:
* **Usuarios Observadores:** Pueden eliminar únicamente sus propias capturas.
* **Usuarios Administradores:** Pueden eliminar cualquier captura de la plataforma para moderar contenido no válido.
* Al confirmar la eliminación, el registro y la imagen se borran permanentemente de MongoDB y del disco del servidor.
