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
* Visual Studio Code

## Estructura del proyecto

```text
CORE-NNA/
│
├── app.py
├── README.md
├── index.html
├── base_normalizada.sql
├── base_catalogos.sql
├── fundacion1_db.sql
├── mi_respaldo.sql
├── categoria.CSV
├── subcategoria.CSV
├── condicion.CSV
│
├── templates/
│   ├── home.html
│   ├── login.html
│   ├── dashboard.html
│   ├── nna_registro.html
│   ├── nna_listado.html
│   ├── detalle_nna.html
│   ├── editar_nna.html
│   ├── tutor_registro.html
│   ├── caso_registro.html
│   ├── casos_listado.html
│   ├── caso_detalle.html
│   ├── apoyo_registro.html
│   ├── apoyos_listado.html
│   ├── consulta_registro.html
│   ├── consultas_listado.html
│   ├── equipos_listado.html
│   ├── equipo_detalle.html
│   └── catalogos.html
│
└── static/
    └── css/
        ├── dashboard.css
        ├── login.css
        ├── consultar.css
        ├── editar.css
        ├── editarNNA.css
        ├── listadoNNA.css
        ├── profesional.css
        └── boton_inicio.js
```

La carpeta `venv/` corresponde al entorno virtual local y no es indispensable para revisar la estructura lógica del sistema.

## Módulos principales

El sistema contempla los siguientes módulos:

### NNA

Permite registrar, consultar, editar y visualizar información relacionada con niñas, niños y adolescentes.

### Casos

Permite registrar y consultar casos institucionales asociados a los NNA.

### Tutores

Permite registrar información de tutores vinculados a los NNA.

### Apoyos

Permite registrar y consultar apoyos otorgados por la institución.

### Consultas

Permite llevar registro de consultas o seguimientos realizados.

### Equipos

Permite consultar información relacionada con equipos o personal responsable.

### Catálogos CIF

Incluye catálogos relacionados con la Clasificación Internacional del Funcionamiento, de la Discapacidad y de la Salud, organizados en categorías, subcategorías y condiciones.

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

### 3. Cargar la estructura de la base de datos

Ejecutar el script principal:

```bash
psql -d base_normalizada -f base_normalizada.sql
```

En caso de que el sistema requiera catálogos adicionales, ejecutar también:

```bash
psql -d base_normalizada -f base_catalogos.sql
```

### 4. Cargar archivos CSV de catálogos

Si los catálogos no se cargan automáticamente desde los scripts SQL, entrar a PostgreSQL:

```bash
psql -d base_normalizada
```

Y ejecutar:

```sql
\copy Categoria FROM 'categoria.CSV' DELIMITER ',' CSV HEADER;
\copy Subcategoria FROM 'subcategoria.CSV' DELIMITER ',' CSV HEADER;
\copy Condicion FROM 'condicion.CSV' DELIMITER ',' CSV HEADER;
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

## Usuario de acceso

El sistema cuenta con inicio de sesión. Para acceder, utilizar el usuario coordinador registrado en la base de datos.

El coordinador es el usuario con permisos para modificar la información del sistema.

Credenciales de prueba:

```text
Correo: COLOCAR_CORREO_DEL_COORDINADOR
Contraseña: COLOCAR_CONTRASEÑA_DEL_COORDINADOR
```

Estas credenciales deben corresponder a los datos cargados en la base de datos.

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
* Verificar que la base de datos `base_normalizada` exista.
* Verificar que los datos de conexión en `app.py` sean correctos.
* No es necesario incluir la carpeta `venv/` para la entrega.
* El código debe entregarse completo, no únicamente mediante enlace a repositorio externo.
