# 5. Captura y Clasificación Automática

La pestaña **Capturar** es el núcleo de visión computacional de la aplicación. Permite procesar fotografías tomadas en el momento o seleccionadas de la memoria del teléfono.

---

## 📸 Flujo Paso a Paso para una Detección

```
1. Seleccionar Fuente ────► 2. Vista Previa ────► 3. Ubicación GPS ────► 4. Analizar Ahora ────► 5. Redirección al Detalle
   (Cámara o Galería)          (Lienzo)            (Opcional)            (YOLO + MobileNet)       (Automática)
```

### Paso 1: Tomar o Cargar Fotografía
Elige entre las dos opciones disponibles:
* **Botón "Cámara":** Abre la cámara nativa del teléfono para tomar una foto en vivo.
* **Botón "Galería":** Abre el selector de medios para importar una imagen guardada previamente.

> [!TIP]
> **Consejos para una mejor detección:**
> * Asegúrate de tener buena luz natural o enfocar adecuadamente el espécimen.
> * Intenta que el insecto o arácnido ocupe una porción representativa del encuadre.
> * Evita fondos con patrones excesivamente caóticos si el espécimen es muy pequeño.

### Paso 2: Vista Previa de la Fotografía
Una vez seleccionada la imagen, se desplegará en el lienzo central adaptándose automáticamente a la pantalla del dispositivo.

### Paso 3: Activar Ubicación GPS (Opcional)
Encontrarás un interruptor llamado **"Incluir ubicación GPS"**:
* **Activado (Recomendado):** La app solicitará al sensor satelital tus coordenadas exactas en ese instante y las adjuntará al avistamiento para situarlo en el mapa global.
* **Desactivado:** El avistamiento se registrará sin coordenadas territoriales.

### Paso 4: Iniciar el Análisis con IA
Presiona el botón verde **"Analizar Ahora"**:
* Mientras la imagen es enviada y procesada por el servidor, los botones se deshabilitarán temporalmente y un indicador animado mostrará el progreso: *"Detectando y clasificando artrópodo..."*.
* El sistema previene envíos duplicados o clics repetidos accidentales.

---

## 🚦 Resultados Posibles de la Inferencia

### Caso A: Detección Exitosa (Artrópodos Identificados)
1. El servidor identifica las cajas delimitadoras y clasifica los órdenes correspondientes.
2. La captura se almacena permanentemente en MongoDB asociada a tu usuario.
3. Se muestra una notificación de éxito: *"¡Se detectaron X artrópodo(s)! Mostrando detalle..."*.
4. **Redirección Inmediata:** La aplicación te lleva directamente a la **Pantalla de Detalle**, reseteando el formulario de captura para que al volver atrás la pantalla esté limpia y lista para una nueva fotografía.

### Caso B: Sin Detecciones (Imagen Vacía o Sin Artrópodos)
Si subes una foto donde no hay insectos o el modelo no detecta ningún artrópodo con suficiente certeza:
* Se desplegará una alerta explicativa: *"No se detectaron artrópodos en la imagen"*.
* **Protección de Almacenamiento:** Esta fotografía **NO se guarda** en la base de datos ni ensucia tu historial.
* Puedes descartarla o presionar los botones superiores para intentar con otra toma con mejor iluminación y mayor acercamiento.
