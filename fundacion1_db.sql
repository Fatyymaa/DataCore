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
    fecha_nacimiento DATE,
    sexo VARCHAR(15),
    direccion TEXT,
    correo VARCHAR(100) UNIQUE,
    password1 VARCHAR(100),
    rol_id INTEGER, 
    es_empleado BOOLEAN DEFAULT TRUE, 
    esta_activo BOOLEAN DEFAULT TRUE
);
-- 1: Director, 2: Coordinador
-- TRUE: Empleado, FALSE: Voluntario
-- 3. INSERTAR AL DIRECTOR PARA QUE PUEDAS ENTRAR
INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp, fecha_nacimiento, sexo, direccion, correo, password1, rol_id, es_empleado, esta_activo)
VALUES ('Ian', 'Director', 'General', 'RFC12345', 'CURP12345', '1990-01-01', 'MASCULINO', 'Oficina Central', 'director@datacore.com', 'admin123', 1, TRUE, TRUE);