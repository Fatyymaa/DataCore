-- ================================================================
-- BASE NORMALIZADA — FUNDACIÓN NNA (DataCore)   [VERSIÓN LIMPIA]
-- ================================================================

-- ---------- orden de dependencias ----------------
DROP VIEW  IF EXISTS v_personal_rol CASCADE;
DROP TABLE IF EXISTS
    codigo_postal,
    seguimiento, asignacion_caso, caso_derecho, caso_nna, caso,
    derecho, estatus_caso, equipo_miembro, equipo_multidisciplinario,
    lenguaje_tutor, tutor_condicion, nna_tutor, contacto_tutor, tutor,
    lenguaje_nna, nivel_competencia_oral, modo_adquisicion_lengua,
    ubicacion_lengua, lengua,
    nna_condicion, nna,
    grado_dificultad, grado_dependencia,
    condicion, subcategoria, categoria,
    telefono_tutor, telefono_personal, contacto_personal, contacto_tutor, contacto_nna, personal, roles,
    tipo_contacto, parentesco, escolaridad, nacionalidad, sexo,
    direccion, asentamiento, entidad_federativa CASCADE;

-- ================================================================
-- 1. CATÁLOGOS DIRECCIÓN
-- ================================================================
CREATE TABLE entidad_federativa (
    id_ent  SERIAL PRIMARY KEY,
    nom_ent VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE asentamiento (
    id_asen  SERIAL PRIMARY KEY,
    nom_mun  VARCHAR(150) NOT NULL,
    nom_col  VARCHAR(150),
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

-- ================================================================
-- 2. CATÁLOGOS GENERALES
-- ================================================================
CREATE TABLE sexo (
    id_sexo  SERIAL PRIMARY KEY,
    nom_sexo VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO sexo (nom_sexo) VALUES
 ('MASCULINO'),('FEMENINO'),('OTRO'),('NO ESPECIFICADO');

CREATE TABLE escolaridad (
    id_esc  SERIAL PRIMARY KEY,
    nom_esc VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO escolaridad (nom_esc) VALUES
 ('Sin escolaridad'),('Preescolar'),('Primaria'),('Secundaria'),
 ('Preparatoria'),('Bachillerato técnico'),('Educación especial'),
 ('Licenciatura'),('No aplica (lactante)');

CREATE TABLE parentesco (
    id_paren  SERIAL PRIMARY KEY,
    nom_paren VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO parentesco (nom_paren) VALUES
 ('Abuela/o'),('Tia/o'),('Hermana/o mayor'),('Madrina/Padrino'),('Otro'),
 ('Madre'),('Padre'),('Abuela'),('Abuelo'),('Hermana/o'),('Prima/o'),
 ('Tutor designado por DIF'),('Familia de acogida');

-- ================================================================
-- 3. CATÁLOGO DE LENGUAS (INALI)
-- ================================================================
CREATE TABLE lengua (
    id_len         SERIAL PRIMARY KEY,
    familia_len    VARCHAR(100),
    agrupacion_len VARCHAR(100),
    variante_len   VARCHAR(100),
    autodenom_len  VARCHAR(100)
);
INSERT INTO lengua (familia_len, agrupacion_len, variante_len, autodenom_len) VALUES
 ('Indoeuropea','Romance','Español','Español'),
 ('Yuto-nahua','Nahua','Náhuatl central','Mexicano'),
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
 ('Lengua de señas','LSM','Lengua de Señas Mexicana','LSM');

CREATE TABLE ubicacion_lengua (
    id_ent INT NOT NULL REFERENCES entidad_federativa(id_ent),
    id_len INT NOT NULL REFERENCES lengua(id_len),
    PRIMARY KEY (id_ent, id_len)
);

CREATE TABLE modo_adquisicion_lengua (
    id_mod_adc    SERIAL PRIMARY KEY,
    categ_mod_adc VARCHAR(100),
    desc_mod_adc  VARCHAR(200)
);
INSERT INTO modo_adquisicion_lengua (categ_mod_adc, desc_mod_adc) VALUES
 ('Lengua materna', 'Adquirida en el hogar desde el nacimiento'),
 ('Segunda lengua', 'Aprendida después de la lengua materna'),
 ('Lengua escolar', 'Aprendida en el entorno educativo');

CREATE TABLE nivel_competencia_oral (
    id_niv_com   SERIAL PRIMARY KEY,
    niv_prac_com VARCHAR(100),
    sign_niv_com VARCHAR(200)
);
INSERT INTO nivel_competencia_oral (niv_prac_com, sign_niv_com) VALUES
 ('Nativo', 'Comprende y se expresa con total fluidez'),
 ('Avanzado', 'Se comunica con fluidez en la mayoría de los contextos'),
 ('Intermedio', 'Mantiene conversaciones cotidianas con algunas limitaciones'),
 ('Básico', 'Comprende y usa frases sencillas');

-- ================================================================
-- 4. CATALOGO DE DISCAPACIDAD (CIF) 
-- ================================================================
CREATE TABLE categoria (
    id_categoria INT PRIMARY KEY,
    nombre       VARCHAR(120) NOT NULL
);

CREATE TABLE subcategoria (
    id_subcategoria INT PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    id_categoria    INT REFERENCES categoria(id_categoria)
);

CREATE TABLE condicion (
    id_condicion    INT PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    codigo_cif      VARCHAR(10),
    id_subcategoria INT REFERENCES subcategoria(id_subcategoria)
);
-- 200 discapacidades de la CIF, balanceadas (50 por categoria)
INSERT INTO categoria (id_categoria, nombre) VALUES
 (1,'Física'),
 (2,'Intelectual'),
 (3,'Psicosocial'),
 (4,'Sensorial');

INSERT INTO subcategoria (id_subcategoria, nombre, id_categoria) VALUES
 (1,'Actitudes',3),
 (2,'Apoyo y relaciones',3),
 (3,'Aprendizaje y aplicación del conocimiento',2),
 (4,'Areas principales de la vida',3),
 (5,'Autocuidado',1),
 (6,'Comunicación',4),
 (7,'El ojo, el oído y estructuras relacionadas',4),
 (8,'Entorno natural y cambios en el entorno derivados de la actividad humana',3),
 (9,'Estructuras de los sistemas cardiovascular, inmunológico y respiratorio',1),
 (10,'Estructuras del sistema nervioso',1),
 (11,'Estructuras involucradas en la voz y el habla',4),
 (12,'Estructuras relacionadas con el movimiento',1),
 (13,'Estructuras relacionadas con el sistema genitourinario y el sistema reproductor',1),
 (14,'Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino',1),
 (15,'Funciones de la piel y estructuras relacionadas',1),
 (16,'Funciones de la voz y el habla',4),
 (17,'Funciones de los sistemas cardiovascular, hematológico, inmunológico y respiratorio',1),
 (18,'Funciones de los sistemas digestivo, metabólico y endocrino',1),
 (19,'Funciones genitourinarias y reproductoras',1),
 (20,'Funciones mentales',2),
 (21,'Funciones neuromusculoesqueléticas y relacionadas con el movimiento',1),
 (22,'Funciones sensoriales y dolor',4),
 (23,'Interacciones y relaciones interpersonales',3),
 (24,'Movilidad',1),
 (25,'Piel y estructuras relacionadas',1),
 (26,'Productos y tecnología',3),
 (27,'Servicios, sistemas y políticas',3),
 (28,'Tareas y demandas generales',2),
 (29,'Vida comunitaria, social y cívica',3),
 (30,'Vida domestica',1);

INSERT INTO condicion (id_condicion, nombre, codigo_cif, id_subcategoria) VALUES
 (1,'Funciones mentales','b1',20),
 (2,'Funciones de la conciencia','b110',20),
 (3,'Nivel de Conciencia','b1100',20),
 (4,'Continuidad de la conciencia','b1101',20),
 (5,'Cualidad de la conciencia','b1102',20),
 (6,'Regulacion de los estados de vigilia','b1103',20),
 (7,'Funciones de la conciencia, otras especificadas','b1108',20),
 (8,'Funciones de la conciencia, no especificadas','b1109',20),
 (9,'Funciones de la orientación','b114',20),
 (10,'Orientación respecto al tiempo','b1140',20),
 (11,'Orientación respecto al lugar','b1141',20),
 (12,'Orientación respecto a la persona','b1142',20),
 (13,'Orientación respecto a uno mismo','b11420',20),
 (14,'Orientación respecto a los demás','b11421',20),
 (15,'Funciones de la orientación respecto a la persona, otras especificadas','b11428',20),
 (16,'Funciones de la orientación respecto a la persona, no especificadas','b11429',20),
 (17,'Funciones sensoriales y dolor','b2',22),
 (18,'Funciones visuales','b210',22),
 (19,'Funciones de la agudeza  visual','b2100',22),
 (20,'Agudeza binocular a larga distancia','b21000',22),
 (21,'Agudeza monocular a larga distancia','b21001',22),
 (22,'Agudeza binocular a corta distancia','b21002',22),
 (23,'Agudeza monocular a corta distancia','b21003',22),
 (24,'Funciones de la agudeza visual, otras especificadas','b21008',22),
 (25,'Funciones de la agudeza visual, no  especificadas','b21009',22),
 (26,'Funciones del campo visual','b2101',22),
 (27,'Funciones de la voz y el habla','b3',16),
 (28,'Funciones de la voz','b310',16),
 (29,'Producción de la voz','b3100',16),
 (30,'Calidad de la voz','b3101',16),
 (31,'Funciones de la voz, otras especificadas','b3108',16),
 (32,'Funciones de la voz, no especificadas','b3109',16),
 (33,'Funciones de articulación','b320',16),
 (34,'Funciones relacionadas con la fluidez y el ritmo del habla','b330',16),
 (35,'Fluidez del habla','b3300',16),
 (36,'Ritmo del habla','b3301',16),
 (37,'Funciones de los sistemas cardiovascular, hematológico, inmunológico y respiratorio','b4',17),
 (38,'Funciones del corazón','b410',17),
 (39,'Frecuencia cardiaca','b4100',17),
 (40,'Funciones de los sistemas digestivo, metabólico y endocrino','b5',18),
 (41,'Funciones relacionadas con la ingestión','b510',18),
 (42,'Succión','b5100',18),
 (43,'Funciones genitourinarias y reproductoras','b6',19),
 (44,'Funciones relacionadas con la excreción urinaria','b610',19),
 (45,'Filtración de orina','b6100',19),
 (46,'Funciones neuromusculoesqueléticas y relacionadas con el movimiento','b7',21),
 (47,'Funciones relacionadas con la movilidad de las articulaciones','b710',21),
 (48,'Movilidad de una sola articulación','b7100',21),
 (49,'Funciones de la piel y estructuras relacionadas','b8',15),
 (50,'Funciones protectoras de la piel','b810',15),
 (51,'Funciones reparadoras de la piel','b820',15),
 (52,'Aprendizaje y aplicación del conocimiento','d1',3),
 (53,'Mirar','d110',3),
 (54,'Escuchar','d115',3),
 (55,'Otras experiencias sensoriales intencionadas','d120',3),
 (56,'Chupar','d1200',3),
 (57,'Tocar','d1201',3),
 (58,'Oler','d1202',3),
 (59,'Saborear','d1203',3),
 (60,'Experiencias sensoriales intencionadas, otras especificadas y no especificadas','d129',3),
 (61,'Copiar','d130',3),
 (62,'Aprender mediante acciones con objetos','d131',3),
 (63,'Aprender mediante acciones simples con objetos sencillos','d1310',3),
 (64,'Aprender mediante acciones que relacionan dos o más objetos','d1311',3),
 (65,'Aprender mediante acciones con dos o más objetos teniendo en cuenta sus características especificas','d1312',3),
 (66,'Aprendizaje mediante el juego simbolico','d1313',3),
 (67,'Aprendizaje mediante juegos simulados','d1314',3),
 (68,'Aprendizaje mediante acciones con objetos, otro especificado','d1318',3),
 (69,'Aprendizaje mediante acciones con objetos, no especificado','d1319',3),
 (70,'Tareas y demandas generales','d2',28),
 (71,'Llevar a cabo una única tarea','d210',28),
 (72,'Llevar a cabo una tarea sencilla','d2100',28),
 (73,'Llevar a cabo una tarea compleja','d2101',28),
 (74,'Llevar a cabo una única tarea independientemente','d2102',28),
 (75,'Llevar a cabo una única tarea en grupo','d2103',28),
 (76,'Completar una tarea sencilla','d2104',28),
 (77,'Completar una tarea compleja','d2105',28),
 (78,'Llevar a cabo una única tarea, otra especificada','d2108',28),
 (79,'Llevar a cabo una única tarea, no especificada','d2109',28),
 (80,'Llevar a cabo múltiples tareas','d220',28),
 (81,'Realizar múltiples tareas','d2200',28),
 (82,'Completar múltiples tareas','d2201',28),
 (83,'Llevar a cabo múltiples tareas independientemente','d2202',28),
 (84,'Llevar a cabo múltiples tareas en un grupo','d2203',28),
 (85,'Completar multiples tareas independientemente','d2204',28),
 (86,'Comunicación','d3',6),
 (87,'Comunicación-recepción de mensajes hablados','d310',6),
 (88,'Respuesta a la voz humana','d3100',6),
 (89,'Comprensión de mensajes hablados simples','d3101',6),
 (90,'Comprensión de mensajes hablados complejos','d3102',6),
 (91,'Comunicación-recepción de mensajes hablados, otro especificada','d3108',6),
 (92,'Comunicación-recepción de mensajes hablados, no especificada','d3109',6),
 (93,'Comunicación-recepción de mensajes no verbales','d315',6),
 (94,'Comunicación-recepción de gestos corporales','d3150',6),
 (95,'Comunicación-recepción de señales y símbolos','d3151',6),
 (96,'Movilidad','d4',24),
 (97,'Cambiar las posturas corporales básicas','d410',24),
 (98,'Tumbarse','d4100',24),
 (99,'Autocuidado','d5',5),
 (100,'Lavarse','d510',5),
 (101,'Lavar partes individuales del cuerpo','d5100',5),
 (102,'Lavar todo el cuerpo','d5101',5),
 (103,'Secarse','d5102',5),
 (104,'Lavarse, otro especificado','d5108',5),
 (105,'Lavarse, no especificado','d5109',5),
 (106,'Cuidado de partes del cuerpo','d520',5),
 (107,'Cuidado de la piel','d5200',5),
 (108,'Cuidado de los dientes','d5201',5),
 (109,'Cuidado del pelo','d5202',5),
 (110,'Vida domestica','d6',30),
 (111,'Adquisición de un lugar para vivir','d610',30),
 (112,'Comprar un lugar para vivir','d6100',30),
 (113,'Interacciones y relaciones interpersonales','d7',23),
 (114,'Interacciones interpersonales básicas','d710',23),
 (115,'Respeto y afecto en las relaciones','d7100',23),
 (116,'Aprecio en las relaciones','d7101',23),
 (117,'Tolerancia en las relaciones','d7102',23),
 (118,'Actitud crítica en las relaciones','d7103',23),
 (119,'Areas principales de la vida','d8',4),
 (120,'Educación no reglada','d810',4),
 (121,'Educación preescolar','d815',4),
 (122,'Incorporarse al programa de educación preescolar o a alguno de sus niveles','d8150',4),
 (123,'Mantenerse en el programa de educación preescolar','d8151',4),
 (124,'Porgresar en el programa de educación preescolar','d8152',4),
 (125,'Vida comunitaria, social y cívica','d9',29),
 (126,'Vida comunitaria','d910',29),
 (127,'Asociaciones informales','d9100',29),
 (128,'Asociaciones formales','d9101',29),
 (129,'Ceremonias','d9102',29),
 (130,'Vida comunitaria informal','d9103',29),
 (131,'Productos y tecnología','e1',26),
 (132,'Productos o sustancias para el consumo personal','e110',26),
 (133,'Comida','e1100',26),
 (134,'Medicamentos','e1101',26),
 (135,'Productos o sustancias para el consumo personal, otros especificados','e1108',26),
 (136,'Productos o sustancias para el consumo personal, no especificados','e1109',26),
 (137,'Entorno natural y cambios en el entorno derivados de la actividad humana','e2',8),
 (138,'Geografía física','e210',8),
 (139,'Formaciones geológicas','e2100',8),
 (140,'Configuración hidrológica','e2101',8),
 (141,'Geografía física, otros especificados','e2108',8),
 (142,'Geografía física, no especificados','e2109',8),
 (143,'Apoyo y relaciones','e3',2),
 (144,'Familiares cercanos','e310',2),
 (145,'Otros familiares','e315',2),
 (146,'Amigos','e320',2),
 (147,'Conocidos, compañeros, colegas, vecinos y miembros de la comunidad','e325',2),
 (148,'Personas en cargos de autoridad','e330',2),
 (149,'Actitudes','e4',1),
 (150,'Actitudes individuales de miembros de la familia cercana','e410',1),
 (151,'Actitudes individuales de otros familiares','e415',1),
 (152,'Actitudes individuales de amigos','e420',1),
 (153,'Actitudes individuales de conocidos, compañeros, colegas, vecinos y miembros de la comunidad','e425',1),
 (154,'Actitudes individuales de personas en cargos de autoridad','e430',1),
 (155,'Actitudes individuales de personas en cargos subordinados','e435',1),
 (156,'Actitudes individuales de cuidadores y personal de ayuda','e440',1),
 (157,'Servicios, sistemas y políticas','e5',27),
 (158,'Servicios, sistemas y políticas de producción de artículos de consumo','e510',27),
 (159,'Servicios de producción de artículos de consumo','e5100',27),
 (160,'Sistemas de producción de artículos de consumo','e5101',27),
 (161,'Políticas de producción de artículos de consumo','e5102',27),
 (162,'Servicios, sistemas y políticas de producción de artículos de consumo, otros especificados','e5108',27),
 (163,'Estructuras del sistema nervioso','s1',10),
 (164,'Estructura del cerebro','s110',10),
 (165,'Estructura de los lóbulos corticales','s1100',10),
 (166,'El ojo, el oído y estructuras relacionadas','s2',7),
 (167,'Estructura de la órbita ocular','s210',7),
 (168,'Estructura del globo ocular','s220',7),
 (169,'Conjuntiva, esclerótica, coroides','s2200',7),
 (170,'Cornea','s2201',7),
 (171,'Iris','s2202',7),
 (172,'Retina','s2203',7),
 (173,'Cristalino','s2204',7),
 (174,'Humor vítreo','s2205',7),
 (175,'Estructura del globo ocular, otra especificada','s2208',7),
 (176,'Estructuras involucradas en la voz y el habla','s3',11),
 (177,'Estructura de la nariz','s310',11),
 (178,'Nariz externa','s3100',11),
 (179,'Tabique nasal','s3101',11),
 (180,'Fosas nasales','s3102',11),
 (181,'Estructura de la nariz, otra especificada','s3108',11),
 (182,'Estructura de la nariz, no especificada','s3109',11),
 (183,'Estructura de la boca','s320',11),
 (184,'Dientes','s3200',11),
 (185,'Dentición primaria','s32000',11),
 (186,'Estructuras de los sistemas cardiovascular, inmunológico y respiratorio','s4',9),
 (187,'Estructura del sistema cardiovascular','s410',9),
 (188,'Corazón','s4100',9),
 (189,'Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino','s5',14),
 (190,'Estructura de las glándulas salivales','s510',14),
 (191,'Estructura del esófago','s520',14),
 (192,'Estructuras relacionadas con el sistema genitourinario y el sistema reproductor','s6',13),
 (193,'Estructura del sistema urinario','s610',13),
 (194,'Riñones','s6100',13),
 (195,'Estructuras relacionadas con el movimiento','s7',12),
 (196,'Estructuras de la cabeza y de la región del cuello','s710',12),
 (197,'Huesos del cráneo','s7100',12),
 (198,'Piel y estructuras relacionadas','s8',25),
 (199,'Estructura de las áreas de la piel','s810',25),
 (200,'Piel de la cabeza y de la región del cuello','s8100',25);

-- ------------------------------------------------
-- 4b. GRADOS (escalas fijas de la CIF) 
-- ------------------------------------------------
CREATE TABLE grado_dificultad (
    id_grado_dif    SERIAL PRIMARY KEY,
    nom_grado_dif   VARCHAR(40) NOT NULL UNIQUE,
    codigo_cif_dif  VARCHAR(4)  NOT NULL UNIQUE,
    rango_porcent   VARCHAR(20),
    desc_cualitativa VARCHAR(100)
);
INSERT INTO grado_dificultad (nom_grado_dif, codigo_cif_dif, rango_porcent, desc_cualitativa) VALUES
 ('NO hay dificultad',   '.0', '0-4 %',   'ninguna, insignificante'),
 ('Dificultad LIGERA',   '.1', '5-24 %',  'poca, escasa'),
 ('Dificultad MODERADA', '.2', '25-49 %', 'media, regular'),
 ('Dificultad GRAVE',    '.3', '50-95 %', 'mucha, extrema'),
 ('Dificultad COMPLETA', '.4', '96-100 %','total');

CREATE TABLE grado_dependencia (
    id_grado_dep  SERIAL PRIMARY KEY,
    nom_grado_dep VARCHAR(40) NOT NULL UNIQUE,
    descripcion   VARCHAR(200)
);
INSERT INTO grado_dependencia (nom_grado_dep, descripcion) VALUES
 ('Independiente', 'Realiza las actividades por sí mismo'),
 ('Dependencia parcial', 'Requiere apoyo en algunas actividades'),
 ('Dependencia total', 'Requiere apoyo en la mayoría o todas las actividades');

-- ================================================================
-- 5. ROLES Y PERSONAL
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
    id_sexo          INT REFERENCES sexo(id_sexo),
    id_direccion     INT REFERENCES direccion(id_direccion),
    correo           VARCHAR(100) UNIQUE,
    password1        VARCHAR(100),
    rol_id           INT REFERENCES roles(id),
    es_empleado      BOOLEAN DEFAULT TRUE,
    esta_activo      BOOLEAN DEFAULT TRUE
);

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

CREATE TABLE telefono_personal (
    id_telefono SERIAL PRIMARY KEY,
    id_personal INT NOT NULL REFERENCES personal(id),
    numero      VARCHAR(20) NOT NULL
);

INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp,
    fecha_nacimiento, id_sexo, correo, password1, rol_id, es_empleado, esta_activo)
VALUES ('Ian','Director','General','RFC12345','CURP12345',
    '1990-01-01', 1, 'director@datacore.com', 'admin123', 1, TRUE, TRUE);

CREATE TABLE equipo_multidisciplinario (
    id_equipo  SERIAL PRIMARY KEY,
    nom_equipo VARCHAR(100) NOT NULL UNIQUE,
    fecha_crea DATE NOT NULL DEFAULT CURRENT_DATE
);
INSERT INTO equipo_multidisciplinario (nom_equipo) VALUES
 ('Equipo de Atención Integral A'),
 ('Equipo de Atención Integral B'),
 ('Equipo de Restitución de Derechos'),
 ('Equipo de Primera Infancia');

CREATE TABLE equipo_miembro (
    id_equipo   INT NOT NULL REFERENCES equipo_multidisciplinario(id_equipo),
    id_personal INT NOT NULL REFERENCES personal(id),
    fecha_alta  DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_baja  DATE,
    PRIMARY KEY (id_equipo, id_personal, fecha_alta)
);

-- ================================================================
-- 6. NNA
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
    id_direccion     INT REFERENCES direccion(id_direccion),
    lugar_nacimiento INT REFERENCES entidad_federativa(id_ent)
);

CREATE TABLE nna_condicion (
    id_nna        INT NOT NULL REFERENCES nna(id_nna),
    id_condicion  INT NOT NULL REFERENCES condicion(id_condicion),
    id_grado_dif  INT REFERENCES grado_dificultad(id_grado_dif),
    id_grado_dep  INT REFERENCES grado_dependencia(id_grado_dep),
    fecha_diag    DATE,
    diagnosticada BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_nna, id_condicion)
);

CREATE TABLE lenguaje_nna (
    id_nna         INT NOT NULL REFERENCES nna(id_nna),
    id_len         INT NOT NULL REFERENCES lengua(id_len),
    preferente     BOOLEAN DEFAULT FALSE,
    id_mod_adc     INT REFERENCES modo_adquisicion_lengua(id_mod_adc),
    id_niv_com     INT REFERENCES nivel_competencia_oral(id_niv_com),
    id_niv_escrito INT REFERENCES nivel_competencia_oral(id_niv_com),
    PRIMARY KEY (id_nna, id_len)
);
CREATE TABLE public.personal_lengua (
	id_personal int4 NOT NULL,
	id_len int4 NOT NULL,
	id_mod_adc int4 NULL,
	id_niv_com int4 NULL,
	id_niv_escrito int4 NULL,
	CONSTRAINT personal_lengua_pkey PRIMARY KEY (id_personal, id_len)
);


ALTER TABLE public.personal_lengua ADD CONSTRAINT personal_lengua_id_len_fkey FOREIGN KEY (id_len) REFERENCES public.lengua(id_len);
ALTER TABLE public.personal_lengua ADD CONSTRAINT personal_lengua_id_mod_adc_fkey FOREIGN KEY (id_mod_adc) REFERENCES public.modo_adquisicion_lengua(id_mod_adc);
ALTER TABLE public.personal_lengua ADD CONSTRAINT personal_lengua_id_niv_com_fkey FOREIGN KEY (id_niv_com) REFERENCES public.nivel_competencia_oral(id_niv_com);
ALTER TABLE public.personal_lengua ADD CONSTRAINT personal_lengua_id_niv_escrito_fkey FOREIGN KEY (id_niv_escrito) REFERENCES public.nivel_competencia_oral(id_niv_com);
ALTER TABLE public.personal_lengua ADD CONSTRAINT personal_lengua_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);

-- =================================
-- 7. TUTORES 
-- =================================
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

CREATE TABLE telefono_tutor (
    id_telefono SERIAL PRIMARY KEY,
    id_tutor    INT NOT NULL REFERENCES tutor(id_tutor),
    numero      VARCHAR(20) NOT NULL
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

CREATE TABLE lenguaje_tutor (
    id_tutor       INT NOT NULL REFERENCES tutor(id_tutor),
    id_len         INT NOT NULL REFERENCES lengua(id_len),
    preferente     BOOLEAN DEFAULT FALSE,
    id_mod_adc     INT REFERENCES modo_adquisicion_lengua(id_mod_adc),
    id_niv_com     INT REFERENCES nivel_competencia_oral(id_niv_com),
    id_niv_escrito INT REFERENCES nivel_competencia_oral(id_niv_com),
    PRIMARY KEY (id_tutor, id_len)
);

CREATE TABLE tutor_condicion (
    id_tutor     INT NOT NULL REFERENCES tutor(id_tutor),
    id_condicion INT NOT NULL REFERENCES condicion(id_condicion),
    id_grado_dif INT REFERENCES grado_dificultad(id_grado_dif),
    id_grado_dep INT REFERENCES grado_dependencia(id_grado_dep),
    PRIMARY KEY (id_tutor, id_condicion)
);

-- ===================================
-- 8. CASOS 
-- ===================================
CREATE TABLE estatus_caso (
    id_est_caso  SERIAL PRIMARY KEY,
    nom_est_caso VARCHAR(40) NOT NULL UNIQUE
);
INSERT INTO estatus_caso (nom_est_caso) VALUES
 ('Deteccion'),('Diagnostico'),('Plan de restitucion'),('Seguimiento'),('Cerrado');

CREATE TABLE derecho (
    id_der  SERIAL PRIMARY KEY,
    nom_der VARCHAR(150) NOT NULL UNIQUE
);
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
 ('Derecho de acceso a las tecnologías de la información y comunicación');

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

CREATE TABLE asignacion_caso (
    id_caso     INT NOT NULL REFERENCES caso(id_caso),
    id_personal INT NOT NULL REFERENCES personal(id),
    rol_id      INT NOT NULL REFERENCES roles(id),
    fecha_asig  DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_fin   DATE,
    PRIMARY KEY (id_caso, id_personal, rol_id, fecha_asig)
);

CREATE TABLE seguimiento (
    id_seg      SERIAL PRIMARY KEY,
    id_caso     INT NOT NULL REFERENCES caso(id_caso),
    id_personal INT NOT NULL REFERENCES personal(id),
    fecha_seg   DATE NOT NULL DEFAULT CURRENT_DATE,
    descripcion TEXT NOT NULL
);

CREATE OR REPLACE FUNCTION fn_un_equipo_por_nna_en_caso()
RETURNS trigger AS $$
BEGIN
    IF NEW.id_equipo IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM caso_nna cn
            JOIN caso c2 ON c2.id_caso = cn.id_caso
            WHERE cn.id_nna IN (SELECT id_nna FROM caso_nna WHERE id_caso = NEW.id_caso)
              AND c2.id_caso <> NEW.id_caso
              AND c2.id_equipo IS NOT NULL
              AND c2.id_equipo <> NEW.id_equipo
        ) THEN
            RAISE EXCEPTION 'Regla de negocio: uno de los NNA de este caso ya es atendido por otro equipo.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_un_equipo_por_nna_caso ON caso;
CREATE TRIGGER trg_un_equipo_por_nna_caso
BEFORE INSERT OR UPDATE OF id_equipo ON caso
FOR EACH ROW EXECUTE FUNCTION fn_un_equipo_por_nna_en_caso();

CREATE OR REPLACE FUNCTION fn_un_equipo_por_nna_en_casonna()
RETURNS trigger AS $$
DECLARE equipo_actual INT;
BEGIN
    SELECT id_equipo INTO equipo_actual FROM caso WHERE id_caso = NEW.id_caso;
    IF equipo_actual IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM caso_nna cn
            JOIN caso c2 ON c2.id_caso = cn.id_caso
            WHERE cn.id_nna = NEW.id_nna
              AND c2.id_caso <> NEW.id_caso
              AND c2.id_equipo IS NOT NULL
              AND c2.id_equipo <> equipo_actual
        ) THEN
            RAISE EXCEPTION 'Regla de negocio: este NNA ya es atendido por otro equipo en otro caso.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_un_equipo_por_nna_casonna ON caso_nna;
CREATE TRIGGER trg_un_equipo_por_nna_casonna
BEFORE INSERT OR UPDATE ON caso_nna
FOR EACH ROW EXECUTE FUNCTION fn_un_equipo_por_nna_en_casonna();

-- ================================================================
-- 12. CÓDIGO POSTAL (catálogo SEPOMEX) 
-- ================================================================
CREATE TABLE codigo_postal (
    cp        VARCHAR(5)   NOT NULL,
    estado    VARCHAR(100) NOT NULL,
    municipio VARCHAR(150) NOT NULL,
    ciudad    VARCHAR(150),
    colonia   VARCHAR(200) NOT NULL,
    PRIMARY KEY (cp, colonia)
);
CREATE INDEX idx_cp ON codigo_postal(cp);

-- ================================================================
-- 13. ENTIDADES FEDERATIVAS 
-- ================================================================
INSERT INTO entidad_federativa (nom_ent) VALUES
('Aguascalientes'),('Baja California'),('Baja California Sur'),('Campeche'),
('Chiapas'),('Chihuahua'),('Ciudad de México'),('Coahuila'),('Colima'),
('Durango'),('Estado de México'),('Guanajuato'),('Guerrero'),('Hidalgo'),
('Jalisco'),('Michoacán'),('Morelos'),('Nayarit'),('Nuevo León'),('Oaxaca'),
('Puebla'),('Querétaro'),('Quintana Roo'),('San Luis Potosí'),('Sinaloa'),
('Sonora'),('Tabasco'),('Tamaulipas'),('Tlaxcala'),('Veracruz'),('Yucatán'),
('Zacatecas');

INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp,
    fecha_nacimiento, id_sexo, correo, password1, rol_id, es_empleado, esta_activo)
VALUES ('Diana','Coordinadora','General','RFCDIANA01','CURPDIANA0123456',
    '1995-01-01', 2, 'coordinador@datacore.com', 'coord123', 2, TRUE, TRUE);