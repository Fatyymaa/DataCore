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
* `base_normalizada.sql`: script principal para crear la base de datos.
* `categoria.CSV`, `subcategoria.CSV`, `condicion.CSV`: archivos de catálogos CIF.
* `templates/`: vistas HTML del sistema.
* `static/`: estilos CSS y archivos estáticos.

Los archivos `base_catalogos.sql`, `fundacion1_db.sql` y `mi_respaldo.sql` eran respaldos de trabajo, por lo que no son necesarios para ejecutar el sistema final.

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
pip install flask psycopg2-binary
```

### 2. Crear la base de datos

Crear una base de datos en PostgreSQL con el nombre:

```bash
createdb base_normalizada
```

### 3. Cargar la base de datos

Ejecutar el script principal:

```bash
psql -d base_normalizada -f base_normalizada.sql
```

## Configuración de conexión

Antes de ejecutar el sistema, revisar el archivo `app.py` y modificar los datos de conexión a PostgreSQL según la configuración local del equipo.

Ejemplo:

```python
dbname="base_normalizada"
user="postgres"
password="TU_CONTRASEÑA"
host="localhost"
port="5432"
```

Cada usuario debe colocar la contraseña correspondiente a su instalación local de PostgreSQL.

## Acceso al sistema

El sistema cuenta con inicio de sesión. Para ingresar, utilizar el usuario coordinador registrado en la base de datos.

El coordinador es el usuario con permisos para modificar la información del sistema.

Credenciales de acceso:

```text
Correo: COLOCAR_CORREO_DEL_COORDINADOR
Contraseña: COLOCAR_CONTRASEÑA_DEL_COORDINADOR
```

Estas credenciales deben coincidir con los datos cargados en la base de datos.

## Ejecución del sistema

Desde la carpeta principal del proyecto, ejecutar:

```bash
python3 app.py
```

Después abrir el navegador en:

```text
http://127.0.0.1:5000
```

## Notas importantes

* Verificar que PostgreSQL esté activo antes de ejecutar el sistema.
* Verificar que exista la base de datos `base_normalizada`.
* Verificar que los datos de conexión en `app.py` sean correctos.
* No es necesario incluir la carpeta `venv/` para la entrega.
* El código debe entregarse completo, no únicamente mediante enlace a repositorio externo.
