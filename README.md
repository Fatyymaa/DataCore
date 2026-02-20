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
