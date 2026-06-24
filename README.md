# CORE-NNA

## Sistema de Gestión y Seguimiento Institucional para Niñas, Niños y Adolescentes

CORE-NNA es un sistema web desarrollado para la asignatura de Bases de Datos en ESCOM - IPN. Su objetivo es apoyar el registro, seguimiento y control institucional de información relacionada con niñas, niños y adolescentes en situación de vulnerabilidad, garantizando la integridad, confidencialidad y correcta administración de los datos.

El sistema permite administrar información de NNA, casos, tutores, apoyos, consultas, equipos de trabajo y catálogos CIF, mediante una aplicación web desarrollada con Flask y PostgreSQL.

## Objetivo del proyecto

Desarrollar un sistema de base de datos que permita el registro, seguimiento y control institucional de información relacionada con niñas, niños y adolescentes en situación de vulnerabilidad, para garantizar integridad, confidencialidad y correcta administración de los datos.

## Tecnologías utilizadas

* Python 3
* Flask
* PostgreSQL
* HTML5
* CSS3
* Jinja2

## Archivos principales

* `app.py`: archivo principal del sistema en Flask.
* `base_normalizada.sql`: script principal para crear y cargar la base de datos.
* `categoria.CSV`, `subcategoria.CSV`, `condicion.CSV`: archivos de catálogos CIF.
* `templates/`: vistas HTML del sistema.
* `static/`: estilos CSS y archivos estáticos.
* `.gitignore`: archivo para evitar subir archivos locales innecesarios como el entorno virtual.

## Módulos principales

El sistema contempla los siguientes módulos:

* NNA: registro, consulta, edición y visualización de información.
* Casos: registro y seguimiento de casos institucionales.
* Tutores: registro de tutores vinculados a los NNA.
* Apoyos: registro y consulta de apoyos otorgados.
* Consultas: seguimiento de consultas realizadas.
* Equipos: consulta de equipos o personal responsable.
* Catálogos CIF: administración de categorías, subcategorías y condiciones.

## Instalación

### 1. Instalar dependencias

Desde la terminal, ejecutar:

```bash
python3 -m pip install flask psycopg2-binary
```

### 2. Crear la base de datos

Crear una base de datos en PostgreSQL con el nombre `base_normalizada`.

Opción directa desde terminal:

```bash
createdb base_normalizada
```

Si el comando anterior no funciona, ingresar primero a PostgreSQL:

```bash
psql -U postgres
```

Dentro de PostgreSQL, ejecutar:

```sql
CREATE DATABASE base_normalizada;
```

Para salir de PostgreSQL:

```sql
\q
```

En Mac, si PostgreSQL fue instalado con Homebrew, al entrar puede aparecer algo como:

```text
psql (16.x, Homebrew)
```

Si al conectarse aparece:

```text
base_normalizada=#
```

significa que la conexión a la base de datos fue exitosa.

### 3. Cargar la base de datos

Desde la carpeta principal del proyecto, ejecutar:

```bash
psql -U postgres -d base_normalizada -f base_normalizada.sql
```

### 4. Verificar conexión a la base de datos

Para comprobar que la base fue creada correctamente, ejecutar:

```bash
psql -U postgres -d base_normalizada
```

Si aparece:

```text
base_normalizada=#
```

la conexión fue exitosa.

Para salir:

```sql
\q
```

## Configuración de conexión

Antes de ejecutar el sistema, revisar el archivo `app.py` y modificar los datos de conexión a PostgreSQL según la configuración local del equipo.

La conexión se encuentra en la función `conectar_db()`:

```python
def conectar_db():
    return psycopg2.connect(
        host="localhost",
        database="base_normalizada",
        user="postgres",
        password="TU_CONTRASEÑA"
    )
```

En el campo `password`, sustituir `TU_CONTRASEÑA` por la contraseña local del usuario de PostgreSQL.

En el código puede aparecer una contraseña de prueba. Cada usuario debe cambiarla por la contraseña configurada en su instalación local de PostgreSQL.

Si no se recuerda la contraseña de PostgreSQL, primero se puede probar la conexión con:

```bash
psql -U postgres -d base_normalizada
```

Si PostgreSQL solicita contraseña y no se recuerda, será necesario restablecerla o utilizar el usuario configurado en la instalación local.

## Ejecución del sistema

Desde la carpeta principal del proyecto, ejecutar:

```bash
python3 app.py
```

Si la aplicación inicia correctamente, en la terminal aparecerá una dirección similar a:

```text
http://127.0.0.1:5000
```

Abrir esa dirección en el navegador.

## Acceso al sistema

El sistema cuenta con inicio de sesión. Las siguientes credenciales de prueba ya se encuentran precargadas en la base de datos:

### Director

```text
Correo: director@datacore.com
Contraseña: admin123
```

### Coordinador

```text
Correo: coordinador@datacore.com
Contraseña: coord123
```

El usuario Director cuenta con permisos administrativos. El usuario Coordinador cuenta con permisos de coordinación y gestión del sistema.

## Notas importantes

- Verificar que PostgreSQL esté activo antes de ejecutar el sistema.
- Verificar que exista la base de datos `base_normalizada`.
- Verificar que los datos de conexión en `app.py` sean correctos.
- Si ocurre un error de conexión, revisar el usuario y la contraseña configurados en PostgreSQL.
