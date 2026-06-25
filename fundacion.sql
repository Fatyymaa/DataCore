
-- =====================================================================
--  Base de datos: Fundación de apoyo a niñas y niños huérfanos por feminicidio
--  Módulo: REGISTRO DE PERSONAL
--  Motor: PostgreSQL 14+ (probado en 14/15/16)
--  Normalización: hasta 5FN (ver NOTAS al final del archivo)
-- =====================================================================

-- Ejecutar estas dos líneas por separado (no corren dentro de una transacción):
--   CREATE DATABASE fundacion;          -- el clúster suele estar en UTF8
--   \connect fundacion                  -- en psql; en otra herramienta, conéctate manualmente

-- =====================================================================
--  1. CATÁLOGOS BÁSICOS
-- =====================================================================

-- Sexo (clave compatible con CURP: H / M)
CREATE TABLE cat_sexo (
  id_sexo     SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  clave       CHAR(1)     NOT NULL UNIQUE,
  descripcion VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE cat_tipo_telefono (
  id_tipo_telefono SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion      VARCHAR(20) NOT NULL UNIQUE   -- Celular, Fijo
);

-- =====================================================================
--  2. GEOGRAFÍA  (limitada a la Ciudad de México)
--     CP -> municipio -> estado se resuelven por encadenamiento (sin redundancia)
-- =====================================================================

CREATE TABLE cat_estado (
  id_estado SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre    VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE cat_municipio (                 -- Alcaldías de la CDMX
  id_municipio SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre       VARCHAR(80) NOT NULL,
  id_estado    SMALLINT NOT NULL REFERENCES cat_estado(id_estado),
  CONSTRAINT uq_municipio UNIQUE (id_estado, nombre)
);

CREATE TABLE cat_asentamiento (              -- Colonias (catálogo SEPOMEX)
  id_asentamiento INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre_colonia  VARCHAR(120) NOT NULL,
  codigo_postal   CHAR(5)      NOT NULL,
  id_municipio    SMALLINT NOT NULL REFERENCES cat_municipio(id_municipio),
  CONSTRAINT uq_asentamiento UNIQUE (codigo_postal, nombre_colonia)
);

-- =====================================================================
--  3. CATÁLOGO LINGÜÍSTICO (INALI)
--     Familia -> Agrupación (lengua) -> Variante (con autodenominación)
-- =====================================================================

CREATE TABLE cat_familia_linguistica (
  id_familia SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre     VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE cat_lengua (                     -- Agrupación lingüística
  id_lengua  SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre     VARCHAR(120) NOT NULL,
  id_familia SMALLINT NOT NULL REFERENCES cat_familia_linguistica(id_familia),
  CONSTRAINT uq_lengua UNIQUE (nombre, id_familia)
);

CREATE TABLE cat_variante (                   -- Variante lingüística
  id_variante      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre           VARCHAR(160) NOT NULL,
  autodenominacion VARCHAR(160),
  id_lengua        SMALLINT NOT NULL REFERENCES cat_lengua(id_lengua),
  CONSTRAINT uq_variante UNIQUE (nombre, id_lengua)
);

-- Modo de adquisición: Lengua materna / Segunda lengua / Aprendizaje escolar
CREATE TABLE cat_modo_adquisicion (
  id_modo     SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion VARCHAR(40) NOT NULL UNIQUE
);

-- Nivel de dominio: Nativo / Avanzado / Intermedio / Básico  (sirve para oral y escrito)
CREATE TABLE cat_nivel_dominio (
  id_nivel    SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion VARCHAR(20) NOT NULL UNIQUE
);

-- =====================================================================
--  4. PUESTOS Y CONTROL DE ACCESO (RBAC)
-- =====================================================================

CREATE TABLE cat_puesto (
  id_puesto          SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre             VARCHAR(40) NOT NULL UNIQUE,
  permite_voluntario BOOLEAN NOT NULL DEFAULT FALSE   -- TRUE solo: psicólogo, abogado, médico, T. social
);

CREATE TABLE cat_tipo_contratacion (
  id_tipo_contratacion SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion          VARCHAR(20) NOT NULL UNIQUE     -- Contratado, Voluntario
);

CREATE TABLE cat_modulo (                      -- Áreas del sistema sobre las que se otorgan permisos
  id_modulo   SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  clave       VARCHAR(40)  NOT NULL UNIQUE,
  descripcion VARCHAR(120) NOT NULL
);

CREATE TABLE puesto_permiso (                  -- Qué puede leer/modificar cada puesto
  id_puesto       SMALLINT NOT NULL REFERENCES cat_puesto(id_puesto),
  id_modulo       SMALLINT NOT NULL REFERENCES cat_modulo(id_modulo),
  puede_leer      BOOLEAN NOT NULL DEFAULT TRUE,
  puede_modificar BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_puesto, id_modulo)
);

-- =====================================================================
--  5. PERSONA  (datos personales, multivaluados separados)
-- =====================================================================

CREATE TABLE persona (
  id_persona       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre           VARCHAR(80) NOT NULL,
  primer_apellido  VARCHAR(80) NOT NULL,
  segundo_apellido VARCHAR(80),
  anio_nacimiento  SMALLINT NOT NULL,
  curp             CHAR(18) NOT NULL UNIQUE,
  rfc              VARCHAR(13) NOT NULL UNIQUE,
  id_sexo          SMALLINT NOT NULL REFERENCES cat_sexo(id_sexo),
  CONSTRAINT chk_anio CHECK (anio_nacimiento BETWEEN 1900 AND 2100)
);

-- Multivaluado: una persona puede tener varios números (varios celulares)
CREATE TABLE telefono (
  id_telefono      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_persona       INTEGER NOT NULL REFERENCES persona(id_persona) ON DELETE CASCADE,
  numero           VARCHAR(15) NOT NULL,
  id_tipo_telefono SMALLINT NOT NULL REFERENCES cat_tipo_telefono(id_tipo_telefono),
  CONSTRAINT uq_tel UNIQUE (id_persona, numero)
);

-- Dirección 1:1 (relájalo a 1:N quitando el UNIQUE si necesitas varias)
CREATE TABLE direccion (
  id_direccion    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_persona      INTEGER NOT NULL UNIQUE REFERENCES persona(id_persona) ON DELETE CASCADE,
  calle           VARCHAR(160) NOT NULL,
  numero_exterior VARCHAR(15)  NOT NULL,
  numero_interior VARCHAR(15),
  id_asentamiento INTEGER NOT NULL REFERENCES cat_asentamiento(id_asentamiento)
);

-- Multivaluado con atributos propios: persona <-> variante lingüística
CREATE TABLE persona_lengua (
  id_persona       INTEGER  NOT NULL REFERENCES persona(id_persona) ON DELETE CASCADE,
  id_variante      INTEGER  NOT NULL REFERENCES cat_variante(id_variante),
  id_modo          SMALLINT NOT NULL REFERENCES cat_modo_adquisicion(id_modo),
  id_nivel_oral    SMALLINT NOT NULL REFERENCES cat_nivel_dominio(id_nivel),
  id_nivel_escrito SMALLINT NOT NULL REFERENCES cat_nivel_dominio(id_nivel),
  PRIMARY KEY (id_persona, id_variante)
);

-- =====================================================================
--  6. PERSONAL Y CUENTAS DE ACCESO
-- =====================================================================

CREATE TABLE personal (
  id_personal          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_persona           INTEGER  NOT NULL UNIQUE REFERENCES persona(id_persona),
  id_puesto            SMALLINT NOT NULL REFERENCES cat_puesto(id_puesto),
  id_tipo_contratacion SMALLINT NOT NULL REFERENCES cat_tipo_contratacion(id_tipo_contratacion),
  fecha_ingreso        DATE NOT NULL,
  activo               BOOLEAN NOT NULL DEFAULT TRUE
);

-- Credenciales de acceso al sistema (1:1 con personal)
CREATE TABLE cuenta_usuario (
  id_cuenta       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_personal     INTEGER NOT NULL UNIQUE REFERENCES personal(id_personal) ON DELETE CASCADE,
  correo          VARCHAR(160) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,   -- NUNCA texto plano: usar bcrypt / argon2
  activo          BOOLEAN NOT NULL DEFAULT TRUE
);

-- =====================================================================
--  7. EQUIPOS DE TRABAJO (esquema base, a ampliar)
-- =====================================================================

CREATE TABLE equipo_trabajo (
  id_equipo   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre      VARCHAR(120) NOT NULL UNIQUE,
  descripcion VARCHAR(255)
);

CREATE TABLE equipo_integrante (
  id_equipo   INTEGER NOT NULL REFERENCES equipo_trabajo(id_equipo) ON DELETE CASCADE,
  id_personal INTEGER NOT NULL REFERENCES personal(id_personal) ON DELETE CASCADE,
  fecha_alta  DATE NOT NULL,
  PRIMARY KEY (id_equipo, id_personal)
);

-- =====================================================================
--  8. REGLA: puestos que NO admiten voluntarios
--     (Director, Coordinador y Analista solo pueden ser "Contratado")
--     En PostgreSQL un CHECK no consulta otras tablas -> función + trigger.
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_valida_contratacion()
RETURNS TRIGGER AS $$
DECLARE
  v_permite BOOLEAN;
  v_desc    VARCHAR(20);
BEGIN
  SELECT permite_voluntario INTO v_permite
    FROM cat_puesto WHERE id_puesto = NEW.id_puesto;
  SELECT descripcion INTO v_desc
    FROM cat_tipo_contratacion WHERE id_tipo_contratacion = NEW.id_tipo_contratacion;

  IF v_desc = 'Voluntario' AND v_permite = FALSE THEN
    RAISE EXCEPTION 'El puesto seleccionado solo admite personal contratado.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_personal_contratacion
  BEFORE INSERT OR UPDATE ON personal
  FOR EACH ROW
  EXECUTE FUNCTION fn_valida_contratacion();

-- =====================================================================
--  9. DATOS SEMILLA
-- =====================================================================

INSERT INTO cat_sexo (clave, descripcion) VALUES ('H','Hombre'), ('M','Mujer');

INSERT INTO cat_tipo_telefono (descripcion) VALUES ('Celular'), ('Fijo');

INSERT INTO cat_estado (nombre) VALUES ('Ciudad de México');

INSERT INTO cat_municipio (nombre, id_estado) VALUES
('Álvaro Obregón',1),('Azcapotzalco',1),('Benito Juárez',1),('Coyoacán',1),
('Cuajimalpa de Morelos',1),('Cuauhtémoc',1),('Gustavo A. Madero',1),('Iztacalco',1),
('Iztapalapa',1),('La Magdalena Contreras',1),('Miguel Hidalgo',1),('Milpa Alta',1),
('Tláhuac',1),('Tlalpan',1),('Venustiano Carranza',1),('Xochimilco',1);

INSERT INTO cat_modo_adquisicion (descripcion) VALUES
('Lengua materna'),('Segunda lengua'),('Aprendizaje escolar');

INSERT INTO cat_nivel_dominio (descripcion) VALUES
('Nativo'),('Avanzado'),('Intermedio'),('Básico');

INSERT INTO cat_tipo_contratacion (descripcion) VALUES ('Contratado'),('Voluntario');

INSERT INTO cat_puesto (nombre, permite_voluntario) VALUES
('Director', FALSE),
('Coordinador', FALSE),
('Analista', FALSE),
('Psicólogo', TRUE),
('Abogado', TRUE),
('Médico', TRUE),
('Trabajador social', TRUE);

INSERT INTO cat_modulo (clave, descripcion) VALUES
('registro_personal','Registro de personal'),
('gestion_equipos','Gestión de equipos de trabajo'),
('exp_psicologico','Expediente del niño - área psicológica'),
('exp_legal','Expediente del niño - área legal'),
('exp_medico','Expediente del niño - área médica'),
('exp_trabajo_social','Expediente del niño - área de trabajo social'),
('exp_completo','Expediente del niño - completo');

-- Permisos por puesto -------------------------------------------------
-- Director: modifica TODO
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p CROSS JOIN cat_modulo m
WHERE p.nombre = 'Director';

-- Coordinador: registro de personal + gestión de equipos
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p JOIN cat_modulo m ON m.clave IN ('registro_personal','gestion_equipos')
WHERE p.nombre = 'Coordinador';

-- Psicólogo: solo su área del expediente
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p JOIN cat_modulo m ON m.clave = 'exp_psicologico'
WHERE p.nombre = 'Psicólogo';

-- Abogado: solo área legal
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p JOIN cat_modulo m ON m.clave = 'exp_legal'
WHERE p.nombre = 'Abogado';

-- Médico: solo área médica
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p JOIN cat_modulo m ON m.clave = 'exp_medico'
WHERE p.nombre = 'Médico';

-- Trabajador social: TODO el expediente del niño
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, TRUE
FROM cat_puesto p JOIN cat_modulo m ON m.clave LIKE 'exp%'
WHERE p.nombre = 'Trabajador social';

-- Analista: (permisos NO especificados) -> de momento solo lectura del registro de personal
INSERT INTO puesto_permiso (id_puesto, id_modulo, puede_leer, puede_modificar)
SELECT p.id_puesto, m.id_modulo, TRUE, FALSE
FROM cat_puesto p JOIN cat_modulo m ON m.clave = 'registro_personal'
WHERE p.nombre = 'Analista';

-- Ejemplos INALI (importar catálogo completo: 11 familias, 68 agrupaciones, 364 variantes)
INSERT INTO cat_familia_linguistica (nombre) VALUES ('Yuto-nahua'), ('Oto-mangue'), ('Maya');
INSERT INTO cat_lengua (nombre, id_familia) VALUES
('Náhuatl', 1), ('Otomí', 2), ('Maya', 3);
INSERT INTO cat_variante (nombre, autodenominacion, id_lengua) VALUES
('Náhuatl de la Huasteca Hidalguense', 'mexihcatl', 1);

-- Ejemplos de asentamiento (importar catálogo SEPOMEX de la CDMX)
INSERT INTO cat_asentamiento (nombre_colonia, codigo_postal, id_municipio) VALUES
('Roma Norte', '06700', 6),       -- Cuauhtémoc
('Del Valle Centro', '03100', 3); -- Benito Juárez

-- =====================================================================
--  CONSULTA DE EJEMPLO: permisos efectivos de un puesto
-- =====================================================================
-- SELECT pu.nombre AS puesto, mo.descripcion AS modulo,
--        pp.puede_leer, pp.puede_modificar
-- FROM puesto_permiso pp
-- JOIN cat_puesto pu ON pu.id_puesto = pp.id_puesto
-- JOIN cat_modulo mo ON mo.id_modulo = pp.id_modulo
-- WHERE pu.nombre = 'Coordinador';

-- =====================================================================
--  Base de datos: Fundación de apoyo a niñas y niños huérfanos por feminicidio
--  Módulo: EXPEDIENTE DEL NIÑO (datos generales)
--  Motor: PostgreSQL 14+
--  Requiere haber ejecutado antes: fundacion_registro_personal_postgresql.sql
--      (usa cat_sexo, cat_estado, cat_municipio, cat_asentamiento,
--       cat_variante, cat_modo_adquisicion, cat_nivel_dominio)
--  Normalización: hasta 5FN (ver NOTAS al final)
-- =====================================================================

-- =====================================================================
--  1. GEOGRAFÍA NACIONAL (para LUGAR DE NACIMIENTO)
--     El domicilio sigue siendo CDMX; el nacimiento puede ser de cualquier
--     entidad. cat_estado pasa a contener las 32 entidades federativas.
--     CDMX ya existe (id 1) del script de personal: aquí se agregan las 31 restantes.
-- =====================================================================

INSERT INTO cat_estado (nombre) VALUES
('Aguascalientes'),('Baja California'),('Baja California Sur'),('Campeche'),
('Coahuila de Zaragoza'),('Colima'),('Chiapas'),('Chihuahua'),('Durango'),
('Guanajuato'),('Guerrero'),('Hidalgo'),('Jalisco'),('México'),
('Michoacán de Ocampo'),('Morelos'),('Nayarit'),('Nuevo León'),('Oaxaca'),
('Puebla'),('Querétaro'),('Quintana Roo'),('San Luis Potosí'),('Sinaloa'),
('Sonora'),('Tabasco'),('Tamaulipas'),('Tlaxcala'),
('Veracruz de Ignacio de la Llave'),('Yucatán'),('Zacatecas');
-- NOTA: para usar el lugar de nacimiento a nivel nacional debes importar el
--       catálogo completo de municipios del INEGI a cat_municipio (hoy solo
--       tiene las 16 alcaldías de la CDMX). La estructura ya lo soporta.

-- =====================================================================
--  2. CATÁLOGOS DEL EXPEDIENTE
-- =====================================================================

CREATE TABLE cat_escolaridad (
  id_escolaridad SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion    VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE cat_estado_civil (
  id_estado_civil SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descripcion     VARCHAR(40) NOT NULL UNIQUE,
  grupo           VARCHAR(10) NOT NULL
                  CHECK (grupo IN ('Soltero','Casado','Otro'))
);

-- Escalas de la CIF -----------------------------------------------------
CREATE TABLE cat_grado_dificultad (        -- calificador CIF (0-4, 8, 9)
  id_grado_dificultad SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo              SMALLINT NOT NULL UNIQUE,
  descripcion         VARCHAR(60) NOT NULL
);

CREATE TABLE cat_grado_dependencia (       -- escala de dependencia (CIF)
  id_grado_dependencia SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo               SMALLINT UNIQUE,
  descripcion          VARCHAR(60) NOT NULL
);

-- Clasificación CIF: Categoría -> Subcategoría -> Condición ------------
CREATE TABLE cat_cif_categoria (
  id_cif_categoria SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre           VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE cat_cif_subcategoria (
  id_cif_subcategoria SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre              VARCHAR(160) NOT NULL,
  id_cif_categoria    SMALLINT NOT NULL REFERENCES cat_cif_categoria(id_cif_categoria),
  CONSTRAINT uq_cif_subcat UNIQUE (nombre, id_cif_categoria)
);

CREATE TABLE cat_cif_condicion (
  id_cif_condicion    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre              VARCHAR(200) NOT NULL,
  codigo_cif          VARCHAR(12) NOT NULL UNIQUE,
  id_cif_subcategoria SMALLINT NOT NULL REFERENCES cat_cif_subcategoria(id_cif_subcategoria)
);

-- Clasificación CIE-10: Categoría -> Padecimiento ---------------------
CREATE TABLE cat_cie10_categoria (
  id_cie10_categoria SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre             VARCHAR(160) NOT NULL UNIQUE
);

CREATE TABLE cat_cie10 (
  id_cie10           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre             VARCHAR(200) NOT NULL,
  codigo_cie         VARCHAR(10) NOT NULL UNIQUE,
  id_cie10_categoria SMALLINT NOT NULL REFERENCES cat_cie10_categoria(id_cie10_categoria)
);

-- =====================================================================
--  3. NÚCLEO: NIÑO
-- =====================================================================

CREATE TABLE nino (
  id_nino                 INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre                  VARCHAR(80) NOT NULL,
  primer_apellido         VARCHAR(80) NOT NULL,
  segundo_apellido        VARCHAR(80),
  fecha_nacimiento        DATE NOT NULL,
  id_sexo                 SMALLINT NOT NULL REFERENCES cat_sexo(id_sexo),
  curp                    CHAR(18) UNIQUE,            -- "si tiene": admite NULL (varios NULL permitidos)
  id_municipio_nacimiento SMALLINT REFERENCES cat_municipio(id_municipio),  -- entidad + municipio de nacimiento
  id_escolaridad          SMALLINT REFERENCES cat_escolaridad(id_escolaridad),
  id_estado_civil         SMALLINT REFERENCES cat_estado_civil(id_estado_civil),
  fecha_ingreso           DATE NOT NULL,
  CONSTRAINT chk_fechas_nino CHECK (fecha_nacimiento <= fecha_ingreso)
);

-- Domicilio (CDMX) 1:1 ------------------------------------------------
CREATE TABLE nino_domicilio (
  id_domicilio    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_nino         INTEGER NOT NULL UNIQUE REFERENCES nino(id_nino) ON DELETE CASCADE,
  calle           VARCHAR(160) NOT NULL,
  numero_exterior VARCHAR(15)  NOT NULL,
  numero_interior VARCHAR(15),
  id_asentamiento INTEGER NOT NULL REFERENCES cat_asentamiento(id_asentamiento)  -- da colonia, CP y municipio
);

-- Lenguas del niño (con idioma preferente) ----------------------------
CREATE TABLE nino_lengua (
  id_nino          INTEGER  NOT NULL REFERENCES nino(id_nino) ON DELETE CASCADE,
  id_variante      INTEGER  NOT NULL REFERENCES cat_variante(id_variante),
  id_modo          SMALLINT NOT NULL REFERENCES cat_modo_adquisicion(id_modo),
  id_nivel_oral    SMALLINT NOT NULL REFERENCES cat_nivel_dominio(id_nivel),
  id_nivel_escrito SMALLINT NOT NULL REFERENCES cat_nivel_dominio(id_nivel),
  es_preferente    BOOLEAN  NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_nino, id_variante)
);
-- Solo una lengua preferente por niño:
CREATE UNIQUE INDEX uq_nino_lengua_preferente
  ON nino_lengua (id_nino) WHERE es_preferente;

-- Discapacidades (CIF) ------------------------------------------------
CREATE TABLE nino_discapacidad (
  id_nino              INTEGER  NOT NULL REFERENCES nino(id_nino) ON DELETE CASCADE,
  id_cif_condicion     INTEGER  NOT NULL REFERENCES cat_cif_condicion(id_cif_condicion),
  id_grado_dificultad  SMALLINT NOT NULL REFERENCES cat_grado_dificultad(id_grado_dificultad),
  id_grado_dependencia SMALLINT NOT NULL REFERENCES cat_grado_dependencia(id_grado_dependencia),
  PRIMARY KEY (id_nino, id_cif_condicion)
);

-- Enfermedades (CIE-10) -----------------------------------------------
CREATE TABLE nino_enfermedad (
  id_nino           INTEGER NOT NULL REFERENCES nino(id_nino) ON DELETE CASCADE,
  id_cie10          INTEGER NOT NULL REFERENCES cat_cie10(id_cie10),
  fecha_diagnostico DATE,
  observaciones     VARCHAR(255),
  PRIMARY KEY (id_nino, id_cie10)
);

-- =====================================================================
--  4. DATOS SEMILLA
-- =====================================================================

INSERT INTO cat_escolaridad (descripcion) VALUES
('Sin escolaridad'),('Preescolar'),('Primaria'),('Secundaria'),
('Media superior'),('Educación especial');

INSERT INTO cat_estado_civil (descripcion, grupo) VALUES
('Soltero',     'Soltero'),
('Casado',      'Casado'),
('Divorciado',  'Otro'),
('Concubinato', 'Otro'),
('Viudo',       'Otro'),
('Separado',    'Otro'),
('Unión libre', 'Otro');

-- Calificador CIF de dificultad (escala oficial 0-4, 8, 9)
INSERT INTO cat_grado_dificultad (codigo, descripcion) VALUES
(0,'NO hay dificultad (0-4%)'),
(1,'Dificultad LIGERA (5-24%)'),
(2,'Dificultad MODERADA (25-49%)'),
(3,'Dificultad GRAVE (50-95%)'),
(4,'Dificultad COMPLETA (96-100%)'),
(8,'Sin especificar'),
(9,'No aplicable');

-- Escala de dependencia (PLACEHOLDER: ajústala a la escala CIF que uses)
INSERT INTO cat_grado_dependencia (codigo, descripcion) VALUES
(0,'Independiente'),
(1,'Dependencia leve'),
(2,'Dependencia moderada'),
(3,'Dependencia grave'),
(4,'Dependencia total');

-- Ejemplos CIF (importar catálogo completo de la CIF) -----------------
INSERT INTO cat_cif_categoria (nombre) VALUES
('Funciones mentales'),
('Funciones sensoriales y dolor'),
('Funciones neuromusculoesqueléticas y relacionadas con el movimiento');

INSERT INTO cat_cif_subcategoria (nombre, id_cif_categoria) VALUES
('Funciones mentales específicas', 1),
('Visión y funciones relacionadas', 2),
('Funciones relacionadas con el movimiento', 3);

INSERT INTO cat_cif_condicion (nombre, codigo_cif, id_cif_subcategoria) VALUES
('Funciones de la atención', 'b140', 1),
('Funciones visuales',       'b210', 2),
('Movilidad de las articulaciones', 'b710', 3);

-- Ejemplos CIE-10 (importar catálogo completo del CIE-10) -------------
INSERT INTO cat_cie10_categoria (nombre) VALUES
('Enfermedades del sistema respiratorio'),
('Trastornos mentales y del comportamiento'),
('Enfermedades endocrinas, nutricionales y metabólicas');

INSERT INTO cat_cie10 (nombre, codigo_cie, id_cie10_categoria) VALUES
('Asma',                                'J45',   1),
('Trastorno de estrés postraumático',   'F43.1', 2),
('Diabetes mellitus tipo 1',            'E10',   3);
