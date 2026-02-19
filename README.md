# Proyecto: DataCore (Sistema de Gestión)

Repositorio oficial del equipo para la materia de **Bases de Datos**. Estamos integrando el frontend con el servidor de Flask y la base de datos PostgreSQL.

### Estado del Proyecto:
* **Backend y DB:** Ya se integró el `app.py` y el esquema `fundacion1_db.sql`. Tenemos listas las rutas para el login, dashboard y consultas.
* **Registro de Personal:** El `index.html` ya tiene el formulario funcionando con validaciones de longitud para RFC (13) y CURP (18) para evitar errores de inserción.
* **Catálogo de Roles:** Menú desplegable sincronizado con los 8 puestos oficiales definidos en el catálogo de la base de datos.

### Entorno de Trabajo:
Desarrollado en **Ubuntu** usando Python 3.12 y PostgreSQL. Para pruebas locales del frontend usamos la extensión Live Server.

---
**Equipo:** DataCore