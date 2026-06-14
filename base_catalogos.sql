-- ================================================================
-- BASE UNIFICADA Y NORMALIZADA — FUNDACIÓN NNA (DataCore)
-- Fusiona: script del equipo + pg_dump, corrige normalización
-- y agrega catálogos y módulos (NNA, tutores, casos, apoyos,
-- consultas, donantes, donaciones).  Motor: PostgreSQL
-- ================================================================

-- ---------- 0. LIMPIEZA (orden de dependencias) ----------------
DROP VIEW  IF EXISTS v_personal_rol CASCADE;
DROP TABLE IF EXISTS apoyo_donacion, donacion_especie, donacion_monetaria,
    donacion, metodo_pago, donante_moral, donante_fisico, donante,
    consulta, tipo_consulta, apoyo, tipo_apoyo,
    seguimiento, asignacion_caso, caso_derecho, caso_nna, caso,
    derecho, estatus_caso, equipo_miembro, equipo_multidisciplinario,
    nna_tutor, contacto_tutor, tutor,
    lenguaje_nna, nivel_competencia_oral, modo_adquisicion_lengua,
    ubicacion_lengua, lengua,
    nna_condicion, contacto_nna, nacionalidad_nna, nna,
    persona_condicion, persona,                -- tablas viejas del equipo
    condicion, subcategoria, categoria,
    contacto_personal, personal, roles,
    tipo_contacto, parentesco, escolaridad, nacionalidad, sexo,
    direccion, asentamiento, entidad_federativa CASCADE;

-- ================================================================
-- 1. CATÁLOGOS GEOGRÁFICOS Y DIRECCIÓN (antes: direccion TEXT /
--    municipio y estado como varchar → ahora FK a catálogos)
-- ================================================================
CREATE TABLE entidad_federativa (
    id_ent  SERIAL PRIMARY KEY,
    nom_ent VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE asentamiento (
    id_asen  SERIAL PRIMARY KEY,
    nom_mun  VARCHAR(150) NOT NULL,         -- municipio
    nom_col  VARCHAR(150),                  -- colonia
    cp_asen  VARCHAR(5),
    id_ent   INT NOT NULL REFERENCES entidad_federativa(id_ent)
);

CREATE TABLE direccion (
    id_direccion SERIAL PRIMARY KEY,
    calle        VARCHAR(150) NOT NULL,
    numero_ext   VARCHAR(20)  NOT NULL,
    numero_int   VARCHAR(20),
    referencias  VARCHAR(200),
    id_asen      INT NOT NULL REFERENCES asentamiento(id_asen)
);
-- NOTA: ya NO tiene id_persona. La dirección es independiente y
-- cada entidad (personal, nna, tutor) la referencia con su FK.

-- ================================================================
-- 2. CATÁLOGOS GENERALES
-- ================================================================
CREATE TABLE sexo (
    id_sexo  SERIAL PRIMARY KEY,
    nom_sexo VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO sexo (nom_sexo) VALUES ('MASCULINO'), ('FEMENINO');

CREATE TABLE nacionalidad (
    id_nac  SERIAL PRIMARY KEY,
    nom_nac VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO nacionalidad (nom_nac) VALUES ('Mexicana');

CREATE TABLE escolaridad (
    id_esc  SERIAL PRIMARY KEY,
    nom_esc VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO escolaridad (nom_esc) VALUES
 ('Sin escolaridad'),('Preescolar'),('Primaria'),('Secundaria'),('Preparatoria');

CREATE TABLE parentesco (
    id_paren  SERIAL PRIMARY KEY,
    nom_paren VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO parentesco (nom_paren) VALUES
 ('Abuela/o'),('Tia/o'),('Hermana/o mayor'),('Madrina/Padrino'),('Otro');

CREATE TABLE tipo_contacto (
    id_tipo_con  SERIAL PRIMARY KEY,
    nom_tipo_con VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO tipo_contacto (nom_tipo_con) VALUES ('Telefono'),('Celular'),('Correo');

-- ================================================================
-- 3. CATÁLOGO DE LENGUAS (idiomas)
-- ================================================================
CREATE TABLE lengua (
    id_len         SERIAL PRIMARY KEY,
    familia_len    VARCHAR(100),
    agrupacion_len VARCHAR(100),
    variante_len   VARCHAR(100),
    autodenom_len  VARCHAR(100)
);
INSERT INTO lengua (familia_len, agrupacion_len, variante_len, autodenom_len)
VALUES ('Indoeuropea','Romance','Español','Español'),
       ('Yuto-nahua','Nahua','Náhuatl central','Mexicano');

CREATE TABLE ubicacion_lengua (              -- dónde se habla cada lengua
    id_ent INT NOT NULL REFERENCES entidad_federativa(id_ent),
    id_len INT NOT NULL REFERENCES lengua(id_len),
    PRIMARY KEY (id_ent, id_len)
);

CREATE TABLE modo_adquisicion_lengua (
    id_mod_adc    SERIAL PRIMARY KEY,
    categ_mod_adc VARCHAR(100),
    desc_mod_adc  VARCHAR(200)
);

CREATE TABLE nivel_competencia_oral (
    id_niv_com   SERIAL PRIMARY KEY,
    niv_prac_com VARCHAR(100),
    sign_niv_com VARCHAR(200)
);

-- ================================================================
-- 4. TAXONOMÍA DE CONDICIONES (del equipo, se conserva tal cual:
--    Categoria → Subcategoria → Condicion con código CIF)
-- ================================================================
CREATE TABLE categoria (
    id_categoria INT PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL
);

CREATE TABLE subcategoria (
    id_subcategoria INT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    id_categoria    INT REFERENCES categoria(id_categoria)
);

CREATE TABLE condicion (
    id_condicion    INT PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    codigo_cif      VARCHAR(20),
    id_subcategoria INT REFERENCES subcategoria(id_subcategoria)
);

INSERT INTO categoria VALUES
 (1,'Física'),(2,'Sensorial'),(3,'Intelectual'),(4,'Psicosocial');

INSERT INTO subcategoria VALUES
 (1,'Neuromotora',1),(2,'Musculoesquelética',1),(3,'Lesión Medular',1),
 (4,'Visual',2),(5,'Auditiva',2),(6,'Olfativa/Gustativa/Táctil',2),
 (7,'Del Desarrollo',3),(8,'Espectro Autista',3),
 (9,'Trastornos Mentales',4),(10,'Trastornos del Ánimo',4);

INSERT INTO condicion VALUES
 (1,'Parálisis cerebral','a770',1),(2,'Esclerosis','a770',1),
 (3,'Parkinson','a770',1),(4,'Amputación','a730',2),
 (5,'Malformación','a730',2),(6,'Distrofia','a730',2),
 (7,'Paraplejia','a120',3),(8,'Cuadriplejia','a120',3),
 (9,'Ceguera total','a210',4),(10,'Baja visión','a210',4),
 (11,'Sordera total','a230',5),(12,'Hipoacusia','a230',5),
 (13,'Anosmia','a240',6),(14,'Hipoestesia','a260',6),
 (15,'Síndrome de Down','a110',7),(16,'Retraso global','a110',7),
 (17,'TEA grado 1','d160',8),(18,'TEA grado 2','d160',8),
 (19,'TEA grado 3','d160',8),(20,'Esquizofrenia','b152',9),
 (21,'Psicosis','b152',9),(22,'Depresión mayor','b152',10),
 (23,'Trastorno bipolar','b152',10);

-- ================================================================
-- 5. ROLES Y PERSONAL (se conserva login del equipo:
--    correo / password1 / rol_id / es_empleado / esta_activo)
-- ================================================================
CREATE TABLE roles (
    id                   SERIAL PRIMARY KEY,
    nombre_rol           VARCHAR(50) NOT NULL UNIQUE,
    permite_voluntariado BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO roles (nombre_rol, permite_voluntariado) VALUES
 ('Director', FALSE), ('Coordinador', FALSE), ('Psicologo', TRUE),
 ('Doctor', TRUE), ('Abogado', TRUE), ('Trabajador Social', TRUE),
 ('Analista', FALSE), ('Equipo Multidisciplinario', FALSE);

CREATE TABLE personal (
    id               SERIAL PRIMARY KEY,
    nombre           VARCHAR(100),
    apellido_p       VARCHAR(100),
    apellido_m       VARCHAR(100),
    rfc              VARCHAR(13) UNIQUE,
    curp             VARCHAR(18) UNIQUE,
    fecha_nacimiento DATE,
    id_sexo          INT REFERENCES sexo(id_sexo),          -- antes VARCHAR
    id_direccion     INT REFERENCES direccion(id_direccion),-- antes TEXT
    correo           VARCHAR(100) UNIQUE,
    password1        VARCHAR(100),
    rol_id           INT REFERENCES roles(id),              -- ahora con FK real
    es_empleado      BOOLEAN DEFAULT TRUE,   -- TRUE empleado / FALSE voluntario
    esta_activo      BOOLEAN DEFAULT TRUE
);

-- Regla de negocio: solo Psicologo, Doctor, Abogado y Trabajador
-- Social pueden ser voluntarios (es_empleado = FALSE)
CREATE OR REPLACE FUNCTION fn_valida_voluntariado() RETURNS trigger AS $$
BEGIN
    IF NEW.es_empleado = FALSE
       AND NOT (SELECT permite_voluntariado FROM roles WHERE id = NEW.rol_id)
    THEN
        RAISE EXCEPTION 'El rol % no admite voluntariado', NEW.rol_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_voluntariado
BEFORE INSERT OR UPDATE ON personal
FOR EACH ROW EXECUTE FUNCTION fn_valida_voluntariado();

CREATE TABLE contacto_personal (
    id_contacto SERIAL PRIMARY KEY,
    id_personal INT NOT NULL REFERENCES personal(id),
    id_tipo_con INT NOT NULL REFERENCES tipo_contacto(id_tipo_con),
    valor       VARCHAR(150) NOT NULL
);

-- Usuario inicial (cambien la contraseña: nunca en texto plano)
INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp,
    fecha_nacimiento, id_sexo, correo, password1, rol_id, es_empleado, esta_activo)
VALUES ('Ian','Director','General','RFC12345','CURP12345',
    '1990-01-01', 1, 'director@datacore.com', 'admin123', 1, TRUE, TRUE);

CREATE TABLE equipo_multidisciplinario (
    id_equipo  SERIAL PRIMARY KEY,
    nom_equipo VARCHAR(100) NOT NULL UNIQUE,
    fecha_crea DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE equipo_miembro (
    id_equipo  INT NOT NULL REFERENCES equipo_multidisciplinario(id_equipo),
    id_personal INT NOT NULL REFERENCES personal(id),
    fecha_alta DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_baja DATE,
    PRIMARY KEY (id_equipo, id_personal, fecha_alta)
);

-- ================================================================
-- 6. NNA (sustituye a la tabla "Persona" del segundo script)
-- ================================================================
CREATE TABLE nna (
    id_nna           SERIAL PRIMARY KEY,
    folio_nna        VARCHAR(10) UNIQUE,
    nombre           VARCHAR(150) NOT NULL,
    apellido_p       VARCHAR(150),
    apellido_m       VARCHAR(150),
    fecha_nacimiento DATE,
    curp             VARCHAR(18) UNIQUE,
    id_sexo          INT REFERENCES sexo(id_sexo),
    id_esc           INT REFERENCES escolaridad(id_esc),
    id_direccion     INT REFERENCES direccion(id_direccion),      -- domicilio actual
    lugar_nacimiento INT REFERENCES entidad_federativa(id_ent)
);

CREATE TABLE nacionalidad_nna (
    id_nna INT NOT NULL REFERENCES nna(id_nna),
    id_nac INT NOT NULL REFERENCES nacionalidad(id_nac),
    PRIMARY KEY (id_nna, id_nac)
);

CREATE TABLE contacto_nna (
    id_contacto SERIAL PRIMARY KEY,
    id_nna      INT NOT NULL REFERENCES nna(id_nna),
    id_tipo_con INT NOT NULL REFERENCES tipo_contacto(id_tipo_con),
    valor       VARCHAR(150) NOT NULL
);

CREATE TABLE nna_condicion (                 -- antes persona_condicion
    id_nna       INT NOT NULL REFERENCES nna(id_nna),
    id_condicion INT NOT NULL REFERENCES condicion(id_condicion),
    fecha_diag   DATE,
    diagnosticada BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_nna, id_condicion)
);

CREATE TABLE lenguaje_nna (
    id_nna         INT NOT NULL REFERENCES nna(id_nna),
    id_len         INT NOT NULL REFERENCES lengua(id_len),
    preferente     BOOLEAN DEFAULT FALSE,
    id_niv_com     INT REFERENCES nivel_competencia_oral(id_niv_com),
    id_mod_adc     INT REFERENCES modo_adquisicion_lengua(id_mod_adc),
    PRIMARY KEY (id_nna, id_len)
);

-- ================================================================
-- 7. TUTORES
-- ================================================================
CREATE TABLE tutor (
    id_tutor         SERIAL PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    apellido_p       VARCHAR(150),
    apellido_m       VARCHAR(150),
    fecha_nacimiento DATE,
    curp             VARCHAR(18) UNIQUE,
    ocupacion        VARCHAR(100),
    id_sexo          INT REFERENCES sexo(id_sexo),
    id_direccion     INT REFERENCES direccion(id_direccion)
);

CREATE TABLE contacto_tutor (
    id_contacto SERIAL PRIMARY KEY,
    id_tutor    INT NOT NULL REFERENCES tutor(id_tutor),
    id_tipo_con INT NOT NULL REFERENCES tipo_contacto(id_tipo_con),
    valor       VARCHAR(150) NOT NULL
);

CREATE TABLE nna_tutor (
    id_nna      INT NOT NULL REFERENCES nna(id_nna),
    id_tutor    INT NOT NULL REFERENCES tutor(id_tutor),
    fecha_ini   DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin   DATE,
    id_paren    INT REFERENCES parentesco(id_paren),
    tutor_legal BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_nna, id_tutor, fecha_ini)
);

-- ================================================================
-- 8. CASOS (procedimiento art. 123 LGDNNA)
-- ================================================================
CREATE TABLE estatus_caso (
    id_est_caso  SERIAL PRIMARY KEY,
    nom_est_caso VARCHAR(40) NOT NULL UNIQUE
);
INSERT INTO estatus_caso (nom_est_caso) VALUES
 ('Deteccion'),('Diagnostico'),('Plan de restitucion'),('Seguimiento'),('Cerrado');

CREATE TABLE derecho (                       -- art. 13 LGDNNA
    id_der  SERIAL PRIMARY KEY,
    nom_der VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE caso (
    id_caso      SERIAL PRIMARY KEY,
    folio_caso   VARCHAR(25) NOT NULL UNIQUE,
    nom_caso     VARCHAR(150) NOT NULL,
    fecha_aper   DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_cierre DATE,
    narracion    TEXT,
    id_est_caso  INT NOT NULL REFERENCES estatus_caso(id_est_caso),
    id_equipo    INT REFERENCES equipo_multidisciplinario(id_equipo)
);

CREATE TABLE caso_nna (
    id_caso      INT NOT NULL REFERENCES caso(id_caso),
    id_nna       INT NOT NULL REFERENCES nna(id_nna),
    fecha_incorp DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_caso, id_nna)
);

CREATE TABLE caso_derecho (
    id_caso     INT NOT NULL,
    id_nna      INT NOT NULL,
    id_der      INT NOT NULL REFERENCES derecho(id_der),
    fecha_detec DATE NOT NULL DEFAULT CURRENT_DATE,
    restituido  BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_rest  DATE,
    PRIMARY KEY (id_caso, id_nna, id_der),
    FOREIGN KEY (id_caso, id_nna) REFERENCES caso_nna(id_caso, id_nna)
);

CREATE TABLE asignacion_caso (               -- ternaria legítima: 5FN
    id_caso    INT NOT NULL REFERENCES caso(id_caso),
    id_personal INT NOT NULL REFERENCES personal(id),
    rol_id     INT NOT NULL REFERENCES roles(id),
    fecha_asig DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin  DATE,
    PRIMARY KEY (id_caso, id_personal, rol_id, fecha_asig)
);

CREATE TABLE seguimiento (
    id_seg      SERIAL PRIMARY KEY,
    id_caso     INT NOT NULL REFERENCES caso(id_caso),
    id_personal INT NOT NULL REFERENCES personal(id),
    fecha_seg   DATE NOT NULL DEFAULT CURRENT_DATE,
    descripcion TEXT NOT NULL
);

-- ================================================================
-- 9. APOYOS Y CONSULTAS
-- ================================================================
CREATE TABLE tipo_apoyo (
    id_tipo_apo  SERIAL PRIMARY KEY,
    nom_tipo_apo VARCHAR(60) NOT NULL UNIQUE
);
INSERT INTO tipo_apoyo (nom_tipo_apo) VALUES
 ('Economico'),('Medico'),('Psicologico'),('Juridico'),
 ('Educativo'),('Alimentario'),('Vivienda');

CREATE TABLE apoyo (
    id_apo        SERIAL PRIMARY KEY,
    id_caso       INT NOT NULL,
    id_nna        INT NOT NULL,
    id_tipo_apo   INT NOT NULL REFERENCES tipo_apoyo(id_tipo_apo),
    fecha_apo     DATE NOT NULL DEFAULT CURRENT_DATE,
    descripcion   VARCHAR(200),
    monto         NUMERIC(12,2),
    id_autoriza   INT NOT NULL REFERENCES personal(id),
    FOREIGN KEY (id_caso, id_nna) REFERENCES caso_nna(id_caso, id_nna)
);

CREATE TABLE tipo_consulta (
    id_tipo_consul  SERIAL PRIMARY KEY,
    nom_tipo_consul VARCHAR(40) NOT NULL UNIQUE
);
INSERT INTO tipo_consulta (nom_tipo_consul) VALUES
 ('Medica'),('Psicologica'),('Juridica'),('Trabajo Social');

CREATE TABLE consulta (
    id_consul      SERIAL PRIMARY KEY,
    id_nna         INT NOT NULL REFERENCES nna(id_nna),
    id_personal    INT NOT NULL REFERENCES personal(id),
    id_tipo_consul INT NOT NULL REFERENCES tipo_consulta(id_tipo_consul),
    fecha_consul   TIMESTAMP NOT NULL DEFAULT NOW(),
    motivo         VARCHAR(200),
    notas          TEXT
);

-- ================================================================
-- 10. DONANTES Y DONACIONES
-- ================================================================
CREATE TABLE donante (
    id_don    SERIAL PRIMARY KEY,
    fecha_reg DATE NOT NULL DEFAULT CURRENT_DATE,
    activo    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE donante_fisico (
    id_don     INT PRIMARY KEY REFERENCES donante(id_don),
    nombre     VARCHAR(150) NOT NULL,
    apellido_p VARCHAR(150),
    apellido_m VARCHAR(150),
    rfc        VARCHAR(13) UNIQUE
);

CREATE TABLE donante_moral (
    id_don        INT PRIMARY KEY REFERENCES donante(id_don),
    razon_social  VARCHAR(150) NOT NULL,
    rfc           VARCHAR(12) NOT NULL UNIQUE,
    representante VARCHAR(150)
);

CREATE TABLE metodo_pago (
    id_met_pago  SERIAL PRIMARY KEY,
    nom_met_pago VARCHAR(40) NOT NULL UNIQUE
);
INSERT INTO metodo_pago (nom_met_pago) VALUES
 ('Efectivo'),('Transferencia'),('Tarjeta'),('Cheque');

CREATE TABLE donacion (
    id_donacion SERIAL PRIMARY KEY,
    id_don      INT NOT NULL REFERENCES donante(id_don),
    fecha       DATE NOT NULL DEFAULT CURRENT_DATE,
    observacion VARCHAR(200)
);

CREATE TABLE donacion_monetaria (
    id_donacion INT PRIMARY KEY REFERENCES donacion(id_donacion),
    monto       NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    id_met_pago INT NOT NULL REFERENCES metodo_pago(id_met_pago)
);

CREATE TABLE donacion_especie (
    id_donacion INT PRIMARY KEY REFERENCES donacion(id_donacion),
    descripcion VARCHAR(200) NOT NULL,
    cantidad    NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    valor_est   NUMERIC(12,2)
);

CREATE TABLE apoyo_donacion (
    id_apo         INT NOT NULL REFERENCES apoyo(id_apo),
    id_donacion    INT NOT NULL REFERENCES donacion(id_donacion),
    monto_aplicado NUMERIC(12,2),
    PRIMARY KEY (id_apo, id_donacion)
); 
INSERT INTO entidad_federativa (nom_ent) VALUES
('Aguascalientes'),('Baja California'),('Baja California Sur'),('Campeche'),
('Chiapas'),('Chihuahua'),('Ciudad de México'),('Coahuila'),('Colima'),
('Durango'),('Estado de México'),('Guanajuato'),('Guerrero'),('Hidalgo'),
('Jalisco'),('Michoacán'),('Morelos'),('Nayarit'),('Nuevo León'),('Oaxaca'),
('Puebla'),('Querétaro'),('Quintana Roo'),('San Luis Potosí'),('Sinaloa'),
('Sonora'),('Tabasco'),('Tamaulipas'),('Tlaxcala'),('Veracruz'),('Yucatán'),
('Zacatecas')
ON CONFLICT (nom_ent) DO NOTHING;


-- 1. DERECHOS (art. 13 de la LGDNNA) — necesario para el módulo de casos
INSERT INTO derecho (nom_der) VALUES
 ('Derecho a la vida, a la paz, a la supervivencia y al desarrollo'),
 ('Derecho de prioridad'),
 ('Derecho a la identidad'),
 ('Derecho a vivir en familia'),
 ('Derecho a la igualdad sustantiva'),
 ('Derecho a no ser discriminado'),
 ('Derecho a vivir en condiciones de bienestar y a un sano desarrollo integral'),
 ('Derecho a una vida libre de violencia y a la integridad personal'),
 ('Derecho a la protección de la salud y a la seguridad social'),
 ('Derecho a la inclusión de NNA con discapacidad'),
 ('Derecho a la educación'),
 ('Derecho al descanso y al esparcimiento'),
 ('Derecho a la libertad de convicciones éticas, pensamiento, conciencia, religión y cultura'),
 ('Derecho a la libertad de expresión y de acceso a la información'),
 ('Derecho de participación'),
 ('Derecho de asociación y reunión'),
 ('Derecho a la intimidad'),
 ('Derecho a la seguridad jurídica y al debido proceso'),
 ('Derechos de NNA migrantes'),
 ('Derecho de acceso a las tecnologías de la información y comunicación')
ON CONFLICT (nom_der) DO NOTHING;

-- 2. EQUIPO MULTIDISCIPLINARIO inicial (los casos pueden asignarse a un equipo)
INSERT INTO equipo_multidisciplinario (nom_equipo) VALUES
 ('Equipo de Atención Integral A')
ON CONFLICT (nom_equipo) DO NOTHING;

-- 3. CATÁLOGOS DE LENGUA que estaban vacíos (los usa el registro de NNA)
INSERT INTO modo_adquisicion_lengua (categ_mod_adc, desc_mod_adc) VALUES
 ('Lengua materna', 'Adquirida en el hogar desde el nacimiento'),
 ('Segunda lengua', 'Aprendida después de la lengua materna'),
 ('Lengua escolar', 'Aprendida en el entorno educativo');

INSERT INTO nivel_competencia_oral (niv_prac_com, sign_niv_com) VALUES
 ('Nativo', 'Comprende y se expresa con total fluidez'),
 ('Avanzado', 'Se comunica con fluidez en la mayoría de los contextos'),
 ('Intermedio', 'Mantiene conversaciones cotidianas con algunas limitaciones'),
 ('Básico', 'Comprende y usa frases sencillas');

 -- ================================================================
-- POBLADO DE CATÁLOGOS + TABLA ENFERMEDAD + REGLA DE NEGOCIO
-- Fundación NNA (DataCore) — ejecutar UNA VEZ en pgAdmin
-- (Query Tool sobre base_normalizada, F5)
--
-- DISEÑO: todo respeta la normalización existente.
--   * Catálogos = tablas independientes con su PK propia (no hay
--     valores repetidos ni datos derivados almacenados).
--   * Las relaciones NNA<->catálogo siguen siendo N:M en sus
--     tablas puente (un NNA tiene varias lenguas/condiciones/
--     enfermedades y viceversa) -> se mantiene 5FN.
--   * Usamos ON CONFLICT DO NOTHING para poder re-ejecutar sin
--     duplicar (idempotente).
-- ================================================================

-- ----------------------------------------------------------------
-- 1. SEXO  (agregamos opción no binaria / no especificado)
-- ----------------------------------------------------------------
INSERT INTO sexo (nom_sexo) VALUES
 ('OTRO'), ('NO ESPECIFICADO')
ON CONFLICT (nom_sexo) DO NOTHING;

-- ----------------------------------------------------------------
-- 2. NACIONALIDAD
-- ----------------------------------------------------------------
INSERT INTO nacionalidad (nom_nac) VALUES
 ('Guatemalteca'), ('Hondureña'), ('Salvadoreña'), ('Estadounidense'),
 ('Venezolana'), ('Colombiana'), ('Haitiana'), ('Otra')
ON CONFLICT (nom_nac) DO NOTHING;

-- ----------------------------------------------------------------
-- 3. ESCOLARIDAD  (completamos niveles faltantes)
-- ----------------------------------------------------------------
INSERT INTO escolaridad (nom_esc) VALUES
 ('Bachillerato técnico'), ('Educación especial'),
 ('Licenciatura'), ('No aplica (lactante)')
ON CONFLICT (nom_esc) DO NOTHING;

-- ----------------------------------------------------------------
-- 4. PARENTESCO  (más opciones reales de tutela)
-- ----------------------------------------------------------------
INSERT INTO parentesco (nom_paren) VALUES
 ('Madre'), ('Padre'), ('Abuela'), ('Abuelo'),
 ('Hermana/o'), ('Prima/o'), ('Tutor designado por DIF'),
 ('Familia de acogida')
ON CONFLICT (nom_paren) DO NOTHING;

-- ----------------------------------------------------------------
-- 5. TIPO DE CONTACTO
-- ----------------------------------------------------------------
INSERT INTO tipo_contacto (nom_tipo_con) VALUES
 ('WhatsApp'), ('Telefono de recados'), ('Red social')
ON CONFLICT (nom_tipo_con) DO NOTHING;

-- ----------------------------------------------------------------
-- 6. LENGUAS DE MÉXICO (catálogo amplio)
--    La tabla 'lengua' NO tiene UNIQUE, así que para no duplicar
--    al re-ejecutar insertamos sólo las que aún no existen
--    (NOT EXISTS por variante_len).
-- ----------------------------------------------------------------
INSERT INTO lengua (familia_len, agrupacion_len, variante_len, autodenom_len)
SELECT * FROM (VALUES
 ('Yuto-nahua','Nahua','Náhuatl de la Huasteca','Mexicano'),
 ('Maya','Maya peninsular','Maya','Maaya t''aan'),
 ('Oto-mangue','Zapoteco','Zapoteco del Istmo','Diidxazá'),
 ('Oto-mangue','Mixteco','Mixteco de la Costa','Tu''un savi'),
 ('Oto-mangue','Otomí','Otomí del Valle','Hñähñu'),
 ('Maya','Tzeltal','Tzeltal','Bats''il k''op'),
 ('Maya','Tzotzil','Tzotzil','Bats''i k''op'),
 ('Maya','Chol','Chol','Lakty''añ'),
 ('Totonaco-tepehua','Totonaco','Totonaco de la Sierra','Tachiwín'),
 ('Oto-mangue','Mazateco','Mazateco','Ha shuta enima'),
 ('Oto-mangue','Mazahua','Mazahua','Jñatjo'),
 ('Oto-mangue','Chinanteco','Chinanteco','Tsa jujmí'),
 ('Maya','Huasteco','Huasteco','Téenek'),
 ('Yuto-nahua','Cora','Cora','Naáyeri'),
 ('Yuto-nahua','Huichol','Huichol','Wixárika'),
 ('Yuto-nahua','Yaqui','Yaqui','Yoeme'),
 ('Yuto-nahua','Tarahumara','Tarahumara','Rarámuri'),
 ('Oto-mangue','Triqui','Triqui','Tinujéi'),
 ('Tarasca','Purépecha','Purépecha','P''urhépecha'),
 ('Oto-mangue','Amuzgo','Amuzgo','Tzjon Noan'),
 ('Mixe-zoque','Mixe','Mixe','Ayüük'),
 ('Mixe-zoque','Zoque','Zoque','O''de püt'),
 ('Maya','Tojolabal','Tojolabal','Tojol-ab''al'),
 ('Maya','Chontal de Tabasco','Chontal','Yoko ochoco'),
 ('Oto-mangue','Chatino','Chatino','Cha''cña'),
 ('Oto-mangue','Popoloca','Popoloca','Ngiwa'),
 ('Álgica','Kickapoo','Kickapoo','Kikapú'),
 ('Cochimí-yumana','Pápago','Pápago','Tohono O''odham'),
 ('Seri','Seri','Seri','Cmiique iitom'),
 ('Huave','Huave','Huave','Ikoots'),
 ('Lengua de señas','LSM','Lengua de Señas Mexicana','LSM')
) AS nuevas(familia_len, agrupacion_len, variante_len, autodenom_len)
WHERE NOT EXISTS (
    SELECT 1 FROM lengua l WHERE l.variante_len = nuevas.variante_len
);

-- ----------------------------------------------------------------
-- 7. CONDICIONES (DISCAPACIDAD) — completamos la taxonomía CIF
--    que ya existe. id_condicion es INT manual, seguimos la
--    numeración desde 24 para no chocar con las 23 existentes.
-- ----------------------------------------------------------------
INSERT INTO condicion (id_condicion, nombre, codigo_cif, id_subcategoria) VALUES
 (24,'Espina bífida','a730',2),
 (25,'Artritis idiopática juvenil','a730',2),
 (26,'Hemiplejia','a120',3),
 (27,'Debilidad visual severa','a210',4),
 (28,'Sordoceguera','a230',5),
 (29,'Trastorno del lenguaje','d160',7),
 (30,'Discapacidad intelectual leve','a110',7),
 (31,'Discapacidad intelectual moderada','a110',7),
 (32,'TDAH','b152',9),
 (33,'Trastorno de ansiedad','b152',9)
ON CONFLICT (id_condicion) DO NOTHING;

-- ================================================================
-- 8. NUEVA TABLA: ENFERMEDAD (separada de discapacidad)
--    Una discapacidad clasifica con CIF; una enfermedad clasifica
--    con CIE-10. Son cosas distintas -> tabla propia.
--    Estructura espejo de 'condicion' (catálogo simple) con su
--    relación N:M hacia NNA -> respeta 5FN.
-- ================================================================
CREATE TABLE IF NOT EXISTS tipo_enfermedad (
    id_tipo_enf  SERIAL PRIMARY KEY,
    nom_tipo_enf VARCHAR(80) NOT NULL UNIQUE
);
INSERT INTO tipo_enfermedad (nom_tipo_enf) VALUES
 ('Crónico-degenerativa'),('Infecciosa'),('Respiratoria'),
 ('Cardiovascular'),('Metabólica'),('Autoinmune'),
 ('Neurológica'),('Gastrointestinal'),('Otra')
ON CONFLICT (nom_tipo_enf) DO NOTHING;

CREATE TABLE IF NOT EXISTS enfermedad (
    id_enf       SERIAL PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL UNIQUE,
    codigo_cie   VARCHAR(20),              -- clasificación CIE-10
    id_tipo_enf  INT REFERENCES tipo_enfermedad(id_tipo_enf),
    cronica      BOOLEAN DEFAULT FALSE
);
INSERT INTO enfermedad (nombre, codigo_cie, id_tipo_enf, cronica) VALUES
 ('Diabetes tipo 1','E10',5,TRUE),
 ('Asma','J45',3,TRUE),
 ('Epilepsia','G40',7,TRUE),
 ('Desnutrición','E46',5,FALSE),
 ('Anemia','D64',5,FALSE),
 ('Tuberculosis','A15',2,FALSE),
 ('VIH','B20',2,TRUE),
 ('Cardiopatía congénita','Q24',4,TRUE),
 ('Insuficiencia renal','N18',5,TRUE),
 ('Hepatitis','B19',2,FALSE),
 ('Cáncer infantil (leucemia)','C91',1,TRUE),
 ('Bronquitis','J40',3,FALSE),
 ('Gastritis','K29',8,FALSE),
 ('Artritis','M13',6,TRUE),
 ('Hipotiroidismo','E03',5,TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- Relación N:M NNA <-> enfermedad (espejo de nna_condicion)
CREATE TABLE IF NOT EXISTS nna_enfermedad (
    id_nna        INT NOT NULL REFERENCES nna(id_nna),
    id_enf        INT NOT NULL REFERENCES enfermedad(id_enf),
    fecha_diag    DATE,
    en_tratamiento BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_nna, id_enf)
);

-- ================================================================
-- 9. REGLA DE NEGOCIO (TRIGGER):
--    "Un equipo atiende varios NNA, pero un NNA NO puede ser
--     atendido por varios equipos distintos."
--
--    El equipo vive en 'caso' (caso.id_equipo) y un caso agrupa
--    NNA vía caso_nna. Entonces la regla se traduce a:
--    "ningún NNA puede estar en dos casos con equipos diferentes".
--
--    Se valida en DOS puntos (los dos caminos por los que un NNA
--    podría terminar con dos equipos):
--      (a) cuando se cambia el equipo de un caso  -> trigger en caso
--      (b) cuando se agrega un NNA a un caso       -> trigger en caso_nna
-- ================================================================

-- (a) Al insertar/actualizar el equipo de un CASO, verificamos que
--     ninguno de sus NNA ya tenga otro equipo en otro caso.
CREATE OR REPLACE FUNCTION fn_un_equipo_por_nna_en_caso()
RETURNS trigger AS $$
BEGIN
    IF NEW.id_equipo IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM caso_nna cn
            JOIN caso c2 ON c2.id_caso = cn.id_caso
            WHERE cn.id_nna IN (SELECT id_nna FROM caso_nna WHERE id_caso = NEW.id_caso)
              AND c2.id_caso <> NEW.id_caso
              AND c2.id_equipo IS NOT NULL
              AND c2.id_equipo <> NEW.id_equipo
        ) THEN
            RAISE EXCEPTION 'Regla de negocio: uno de los NNA de este caso ya es atendido por otro equipo multidisciplinario.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_un_equipo_por_nna_caso ON caso;
CREATE TRIGGER trg_un_equipo_por_nna_caso
BEFORE INSERT OR UPDATE OF id_equipo ON caso
FOR EACH ROW EXECUTE FUNCTION fn_un_equipo_por_nna_en_caso();

-- (b) Al agregar un NNA a un caso, verificamos que ese NNA no esté
--     ya en otro caso con un equipo distinto al de este caso.
CREATE OR REPLACE FUNCTION fn_un_equipo_por_nna_en_casonna()
RETURNS trigger AS $$
DECLARE
    equipo_actual INT;
BEGIN
    SELECT id_equipo INTO equipo_actual FROM caso WHERE id_caso = NEW.id_caso;

    IF equipo_actual IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM caso_nna cn
            JOIN caso c2 ON c2.id_caso = cn.id_caso
            WHERE cn.id_nna = NEW.id_nna
              AND c2.id_caso <> NEW.id_caso
              AND c2.id_equipo IS NOT NULL
              AND c2.id_equipo <> equipo_actual
        ) THEN
            RAISE EXCEPTION 'Regla de negocio: este NNA ya es atendido por otro equipo multidisciplinario en otro caso.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_un_equipo_por_nna_casonna ON caso_nna;
CREATE TRIGGER trg_un_equipo_por_nna_casonna
BEFORE INSERT OR UPDATE ON caso_nna
FOR EACH ROW EXECUTE FUNCTION fn_un_equipo_por_nna_en_casonna();

-- ----------------------------------------------------------------
-- 10. MÁS EQUIPOS MULTIDISCIPLINARIOS de ejemplo
-- ----------------------------------------------------------------
INSERT INTO equipo_multidisciplinario (nom_equipo) VALUES
 ('Equipo de Atención Integral B'),
 ('Equipo de Restitución de Derechos'),
 ('Equipo de Primera Infancia')
ON CONFLICT (nom_equipo) DO NOTHING;

-- ================================================================
-- VERIFICACIÓN RÁPIDA (opcional: selecciona y ejecuta para revisar)
-- ================================================================
-- SELECT 'lenguas' AS catalogo, COUNT(*) FROM lengua
-- UNION ALL SELECT 'condiciones', COUNT(*) FROM condicion
-- UNION ALL SELECT 'enfermedades', COUNT(*) FROM enfermedad
-- UNION ALL SELECT 'parentescos', COUNT(*) FROM parentesco
-- UNION ALL SELECT 'nacionalidades', COUNT(*) FROM nacionalidad;