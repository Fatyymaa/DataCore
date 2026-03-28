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

DROP TABLE IF EXISTS Persona_Condicion;
DROP TABLE IF EXISTS Persona;
DROP TABLE IF EXISTS Condicion;
DROP TABLE IF EXISTS Subcategoria;
DROP TABLE IF EXISTS Categoria;

CREATE TABLE Categoria (
    id_categoria INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Subcategoria (
    id_subcategoria INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_categoria INT,
    FOREIGN KEY (id_categoria) REFERENCES Categoria(id_categoria)
);

CREATE TABLE Condicion (
    id_condicion INT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    codigo_cif VARCHAR(20),
    id_subcategoria INT,
    FOREIGN KEY (id_subcategoria) REFERENCES Subcategoria(id_subcategoria)
);

CREATE TABLE Persona (
    id_persona INT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL
);

CREATE TABLE Persona_Condicion (
    id_persona INT,
    id_condicion INT,
    PRIMARY KEY (id_persona, id_condicion),
    FOREIGN KEY (id_persona) REFERENCES Persona(id_persona),
    FOREIGN KEY (id_condicion) REFERENCES Condicion(id_condicion)
);

INSERT INTO Categoria VALUES
(1, 'Física'),
(2, 'Sensorial'),
(3, 'Intelectual'),
(4, 'Psicosocial');

INSERT INTO Subcategoria VALUES
(1, 'Neuromotora', 1),
(2, 'Musculoesquelética', 1),
(3, 'Lesión Medular', 1),
(4, 'Visual', 2),
(5, 'Auditiva', 2),
(6, 'Olfativa/Gustativa/Táctil', 2),
(7, 'Del Desarrollo', 3),
(8, 'Espectro Autista', 3),
(9, 'Trastornos Mentales', 4),
(10, 'Trastornos del Ánimo', 4);

INSERT INTO Condicion VALUES
(1, 'Parálisis cerebral', 'a770', 1),
(2, 'Esclerosis', 'a770', 1),
(3, 'Parkinson', 'a770', 1),
(4, 'Amputación', 'a730', 2),
(5, 'Malformación', 'a730', 2),
(6, 'Distrofia', 'a730', 2),
(7, 'Paraplejia', 'a120', 3),
(8, 'Cuadriplejia', 'a120', 3),
(9, 'Ceguera total', 'a210', 4),
(10, 'Baja visión', 'a210', 4),
(11, 'Sordera total', 'a230', 5),
(12, 'Hipoacusia', 'a230', 5),
(13, 'Anosmia', 'a240', 6),
(14, 'Hipoestesia', 'a260', 6),
(15, 'Síndrome de Down', 'a110', 7),
(16, 'Retraso global', 'a110', 7),
(17, 'TEA grado 1', 'd160', 8),
(18, 'TEA grado 2', 'd160', 8),
(19, 'TEA grado 3', 'd160', 8),
(20, 'Esquizofrenia', 'b152', 9),
(21, 'Psicosis', 'b152', 9),
(22, 'Depresión mayor', 'b152', 10),
(23, 'Trastorno bipolar', 'b152', 10);

INSERT INTO Persona VALUES
(1, 'Juan Pérez'),
(2, 'María López');

INSERT INTO Persona_Condicion VALUES
(1, 9),
(1, 22),
(2, 11);

SELECT 
    p.nombre AS persona,
    c.nombre AS condicion,
    s.nombre AS subcategoria,
    cat.nombre AS categoria
FROM Persona p
JOIN Persona_Condicion pc ON p.id_persona = pc.id_persona
JOIN Condicion c ON pc.id_condicion = c.id_condicion
JOIN Subcategoria s ON c.id_subcategoria = s.id_subcategoria
JOIN Categoria cat ON s.id_categoria = cat.id_categoria;
