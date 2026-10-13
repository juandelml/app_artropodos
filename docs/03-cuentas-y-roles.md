# 3. Cuentas, Sesión y Roles

El sistema cuenta con un esquema de autenticación seguro basado en tokens, diseñado para atribuir cada observación a un autor y permitir diferentes niveles de administración.

---

## Registro de Nuevo Usuario

Si no tienes una cuenta creada:

1. En la pantalla de bienvenida, toca en **"¿No tienes cuenta? Regístrate aquí"**.
2. Completa los campos solicitados en el formulario:
   * **Nombre y Apellidos:** Para identificarte formalmente.
   * **Nombre de Usuario (Username):** Nombre público que aparecerá en tus capturas (ej. `@juan_perez`).
   * **Correo Electrónico:** Se utiliza como tu identificador de acceso principal.
   * **Institución o Universidad (Opcional):** Centro educativo, instituto o laboratorio de procedencia (ej. *CIMAT*, *UNAM*, *UGto*).
   * **Contraseña:** Mínimo 8 caracteres (se solicita confirmación para evitar errores de escritura).
3. Presiona el botón **"Registrarse"**. El sistema creará tu cuenta con rol de **Observador** e iniciará tu sesión automáticamente.

> [!NOTE]
> La fecha y hora de registro es registrada internamente de forma automática por el servidor.

---

## Inicio de Sesión

1. Abre la aplicación e ingresa tu **Correo electrónico** y **Contraseña**.
2. Presiona **"Iniciar Sesión"**.
3. Si los datos son correctos, el servidor responderá con un token de autenticación que la app almacenará de forma segura en tu dispositivo para que no tengas que ingresar tus credenciales cada vez que abras la app.

---

## Gestión del Perfil y Cierre de Sesión

En la esquina superior derecha de todas las pantallas principales encontrarás tu **avatar de usuario**:
* **Borde y fondo verde:** Cuenta de tipo *Observador*.
* **Borde y fondo dorado/ámbar:** Cuenta de tipo *Administrador*.

Al tocar este avatar se desplegará el **Diálogo de Perfil**:
* Consulta tu nombre completo, correo, usuario (`@username`), institución y fecha de ingreso.
* **Cerrar Sesión:** Toca el botón rojo **"Cerrar sesión"** para desvincular tu token del dispositivo de forma segura y regresar a la pantalla de login.

---

## Tabla Comparativa de Roles

| Característica / Permiso | Observador | Administrador |
| :--- | :---: | :---: |
| Capturar fotos y analizar artrópodos | Sí | Sí |
| Guardar ubicación GPS en MongoDB | Sí | Sí |
| Consultar sus propias capturas en el Historial | Sí | Sí |
| Consultar capturas de otros usuarios en el Historial | No *(Solo propias)* | Sí *(Todas las de la comunidad)* |
| Visualizar todas las observaciones en el Mapa global | Sí | Sí |
| Eliminar sus propias capturas | Sí | Sí |
| Eliminar capturas de otros usuarios (Moderación) | No | Sí |
