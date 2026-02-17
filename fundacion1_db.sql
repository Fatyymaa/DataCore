CREATE TABLE roles (id SERIAL PRIMARY KEY, nombre_rol VARCHAR(50) UNIQUE NOT NULL);

INSERT INTO roles (nombre_rol) VALUES ('Director'), ('Coordinador'), ('Psicologo'), ('Doctor'), ('Abogado'), ('Trabajador Social'), ('Analista'), ('Equipo Multidisciplinario');

CREATE TABLE personal (id SERIAL PRIMARY KEY, nombre VARCHAR(250) NOT NULL, apellido_P VARCHAR(250) NOT NULL, apellido_M VARCHAR(250), rfc VARCHAR(13), UNIQUE NOT NULL, curp VARCHAR(18), UNIQUE NOT NULL, rol_id INT REFERENCES roles(id), correo VARCHAR(100), UNIQUE NOT NULL, password1 VARCHAR(250) NOT NULL, esta_activo BOOLEAN DEFAULT TRUE );