# DataCore — Sistema de Gestión de Capital Humano y Catálogos CIF

Este repositorio contiene el desarrollo final del sistema DataCore, un proyecto integral diseñado para la asignatura de Bases de Datos en la ESCOM - IPN. El sistema ofrece una solución para una fundación de Niñas, Niños y Adolescentes (NNA) en situación de orfandad, integrando un backend en Flask con una arquitectura de datos relacional y normalizada en PostgreSQL.
## Instalación del programa
Crear base de datos con nombre "base_normalizada" usando el codigo que se encuentra en nuestro codigo sql con el mismo nombre
cambiar contraseña del postgress en app.py en def conectad_db
la contraseña sera mla que cada usuario tiene en su postgress

## Ejecutar programa
En la terminal, comando python3 app.py
## Especificaciones Técnicas y Alcance

El sistema cubre el ciclo completo de vida de los datos (CRUD), garantizando la persistencia, seguridad e integridad de la información mediante dos grandes módulos:

### 1. Módulo de Administración de Personal
* **Backend:** Desarrollado sobre Python 3.12, utilizando la librería psycopg2 para gestionar la persistencia y consultas mediante cursores de diccionario (RealDictCursor).
* **Validaciones de Integridad:** Restricciones de longitud para identificadores fiscales (RFC de 13 caracteres y CURP de 18 caracteres). Control de reglas de negocio como la mayoría de edad y estados lógicos (Activo/Inactivo).
* **Seguridad:** Sistema de autenticación (Login) integrado para la protección de las rutas administrativas del sistema.

### 2. Módulo de Catálogo Clínico (Estándar CIF - OMS)
* **Estructura en Cascada:** Implementación de la Clasificación Internacional del Funcionamiento, de la Discapacidad y de la Salud (CIF), organizada en una jerarquía de tres niveles para evitar redundancias:
  * Categoria: Almacena los tipos generales de discapacidad.
  * Subcategoria: Representa clasificaciones específicas ligadas a una categoría.
  * Condicion: Contiene los diagnósticos o padecimientos clínicos concretos, incluyendo el atributo especializado cod_cif.
* **Resolución de Discapacidades Múltiples:** Uso de la entidad intermedia Persona_Condicion mediante una relación Muchos a Muchos (M:N), permitiendo registrar múltiples diagnósticos por NNA sin duplicar registros en la entidad Persona.

## Stack de Desarrollo (Entorno Local)

* **Sistema Operativo:** Ubuntu Linux.
* **Lenguaje de Programación:** Python 3.12.
* **Framework Web:** Flask con motor de plantillas Jinja2 para interfaces dinámicas.
* **Motor de Base de Datos:** PostgreSQL 16.
* **IDE:** Visual Studio Code.

## Archivos Incluidos en el Repositorio

* app.py: Código fuente principal del backend en Flask (rutas, validaciones y controladores).
* base_normalizada.sql / fundacion1_db.sql: Scripts SQL con la creación de tablas, restricciones e integridad.
* categoria.csv, subcategoria.csv, condicion.csv: Archivos de datos estructurados para la carga masiva de la clasificación CIF.
* templates/ y static/ : Vistas HTML5 y hojas de estilo (CSS) del dashboard administrativo.

## Instrucciones de Instalación y Despliegue

Siga estos pasos en su entorno local de Ubuntu Linux para inicializar el servidor y la base de datos:

### 1. Instalación de Dependencias
Asegúrese de contar con Python y las librerías necesarias instaladas en su sistema:
```bash
pip install flask psycopg2-binary
createdb discapacidad_db
psql -d discapacidad_db -f fundacion1_db.sql
\copy Categoria FROM 'categoria.csv' DELIMITER ',' CSV HEADER;
\copy Subcategoria FROM 'subcategoria.csv' DELIMITER ',' CSV HEADER;
\copy Condicion FROM 'condicion.csv' DELIMITER ',' CSV HEADER;
python3 app.py

