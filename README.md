# DataCore 

Este repositorio contiene el desarrollo del sistema **DataCore**, un proyecto diseñado para la asignatura de **Bases de Datos** en la **ESCOM - IPN**. El objetivo es ofrecer una solución robusta para la administración de capital humano, integrando un backend eficiente en **Flask** con una base de datos relacional en **PostgreSQL**.

### Especificaciones Técnicas y Alcance
El sistema se encuentra en una fase funcional al 100%, cubriendo el ciclo completo de vida de los datos (**CRUD**):

* **Arquitectura del Backend:** Desarrollado sobre **Python 3.12**, utilizando la librería `psycopg2` para gestionar la persistencia de datos y consultas mediante cursores de diccionario (`RealDictCursor`).
* **Frontend y UX:** Dashboard administrativo con estética minimalista, priorizando la legibilidad y la eficiencia operativa mediante el motor de plantillas **Jinja2**.
* **Validaciones de Integridad:** * **Identificadores Fiscales:** Implementación de restricciones de longitud para **RFC (13 caracteres)** y **CURP (18 caracteres)**, alineadas con los tipos de datos del esquema SQL.
    * **Reglas de Negocio:** Validación de mayoría de edad y gestión de estados lógicos para el personal (Activo/Inactivo).
* **Modelo Relacional:** Esquema normalizado que incluye tablas para `personal` y `roles`, con restricciones de unicidad en correos y llaves foráneas integradas.

### Stack de Desarrollo (Entorno Local)
* **Sistema Operativo:** Ubuntu (Linux).
* **Lenguaje:** Python 3.12 con Flask.
* **Motor de BD:** PostgreSQL 16.
* **Herramientas de Control:** Git para el versionamiento y VS Code como IDE principal.

#como instalar
instalar este sistema es bastante facil solo descomprima el archivo .zip arme la base de datos y de ahi solo corra el ccodigo app.py de preferencia en un entormo como lo es visual studio code 
Catálogo de Discapacidades

Descripción

Este proyecto consiste en el diseño e implementación de un catálogo de discapacidades mediante un modelo relacional. Está orientado a una fundación que apoya a niñas y niños en situación de orfandad, con el objetivo de organizar la información de manera clara, estructurada y eficiente.

El catálogo permite clasificar las discapacidades en categorías, subcategorías y condiciones específicas, facilitando su consulta y análisis.

⸻

Estructura de la base de datos

El modelo está compuesto por las siguientes tablas:
	•	Categoria: almacena los tipos generales de discapacidad.
	•	Subcategoria: representa una clasificación más específica relacionada con una categoría.
	•	Condicion: contiene las condiciones o diagnósticos asociados.
	•	Persona: registra la información de las personas.
	•	Persona_Condicion: tabla intermedia que permite asociar múltiples condiciones a una persona.

Las tablas están relacionadas mediante claves primarias y foráneas, garantizando la integridad de los datos.

⸻

Archivos incluidos
	•	fundacion1_db.sql: script con la creación de tablas e inserción de datos.
	•	categoria.csv: catálogo de categorías.
	•	subcategoria.csv: catálogo de subcategorías.
	•	condicion.csv: catálogo de condiciones.
	•	README.md: descripción del proyecto.

⸻

Cómo ejecutar la base de datos (PostgreSQL)

1. Crear la base de datos
createdb discapacidad_db
2. Ejecutar el script SQL
psql -d discapacidad_db -f fundacion1_db.sql
Cómo importar los archivos CSV

En caso de querer cargar los datos desde archivos CSV, se pueden utilizar los siguientes comandos:
\copy Categoria FROM 'categoria.csv' DELIMITER ',' CSV HEADER;
\copy Subcategoria FROM 'subcategoria.csv' DELIMITER ',' CSV HEADER;
\copy Condicion FROM 'condicion.csv' DELIMITER ',' CSV HEADER;
Uso del sistema

El modelo permite consultar la información completa mediante consultas SQL que integran múltiples tablas. Por ejemplo, es posible obtener el nombre de la persona junto con su condición, subcategoría y categoría correspondiente.

⸻

Contexto del proyecto

Este catálogo fue desarrollado para una fundación que brinda apoyo a niñas y niños en situación de orfandad. La correcta organización de la información permite mejorar la toma de decisiones, asignar recursos de manera adecuada y ofrecer una atención más eficiente. 
