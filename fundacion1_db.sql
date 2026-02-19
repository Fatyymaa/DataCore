CREATE TABLE roles (id SERIAL PRIMARY KEY, nombre_rol VARCHAR(50) UNIQUE NOT NULL);
-- insertar roles --
INSERT INTO roles (nombre_rol) VALUES ('Director'), ('Coordinador'), ('Psicologo'), ('Doctor'), ('Abogado'), ('Trabajador Social'), ('Analista'), ('Equipo Multidisciplinario');
-- 1. BORRAR TABLA SI EXISTE PARA EVITAR CONFLICTOS
DROP TABLE IF EXISTS personal;

-- 2. CREAR TABLA CON LA ESTRUCTURA COMPLETA
CREATE TABLE personal (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    apellido_p VARCHAR(100),
    apellido_m VARCHAR(100),
    rfc VARCHAR(13),
    curp VARCHAR(18),
    edad INTEGER,
    sexo VARCHAR(15),
    direccion TEXT,
    correo VARCHAR(100) UNIQUE,
    password1 VARCHAR(100),
    rol_id INTEGER, -- 1: Director, 2: Coordinador
    es_empleado BOOLEAN DEFAULT TRUE, -- TRUE: Empleado, FALSE: Voluntario
    esta_activo BOOLEAN DEFAULT TRUE
);

-- 3. INSERTAR AL DIRECTOR PARA QUE PUEDAS ENTRAR
INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp, edad, sexo, direccion, correo, password1, rol_id, es_empleado, esta_activo)
VALUES ('Ian', 'Director', 'General', 'RFC12345', 'CURP12345', 30, 'MASCULINO', 'Oficina Central', 'director@datacore.com', 'admin123', 1, TRUE, TRUE);