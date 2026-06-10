--
-- PostgreSQL database dump
--

\restrict VFN4EEI7gGx4fEX8bqaDg5CxNkW937K3VWeMDZfF0cW88cPe6LPkfnOfyuSYWPk

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- Name: condicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.condicion (
    id_condicion integer NOT NULL,
    nombre character varying(150) NOT NULL,
    codigo_cif character varying(20),
    id_subcategoria integer
);


ALTER TABLE public.condicion OWNER TO postgres;

--
-- Name: direccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.direccion (
    id_direccion integer NOT NULL,
    id_persona integer,
    calle character varying(150) NOT NULL,
    numero_ext character varying(20) NOT NULL,
    numero_int character varying(20),
    colonia character varying(100) NOT NULL,
    cp character varying(10) NOT NULL,
    municipio character varying(100) NOT NULL,
    estado character varying(100) NOT NULL
);


ALTER TABLE public.direccion OWNER TO postgres;

--
-- Name: direccion_id_direccion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.direccion_id_direccion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.direccion_id_direccion_seq OWNER TO postgres;

--
-- Name: direccion_id_direccion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.direccion_id_direccion_seq OWNED BY public.direccion.id_direccion;


--
-- Name: persona; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.persona (
    id_persona integer NOT NULL,
    nombre character varying(150) NOT NULL,
    apellido_p character varying(150) NOT NULL,
    apellido_m character varying(150) NOT NULL,
    fecha_nacimiento date,
    sexo character varying(20),
    nacionalidad character varying(50)
);


ALTER TABLE public.persona OWNER TO postgres;

--
-- Name: persona_condicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.persona_condicion (
    id_persona integer NOT NULL,
    id_condicion integer NOT NULL
);


ALTER TABLE public.persona_condicion OWNER TO postgres;

--
-- Name: personal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal (
    id integer NOT NULL,
    nombre character varying(100),
    apellido_p character varying(100),
    apellido_m character varying(100),
    rfc character varying(13),
    curp character varying(18),
    fecha_nacimiento date,
    sexo character varying(15),
    correo character varying(100),
    password1 character varying(100),
    rol_id integer,
    es_empleado boolean DEFAULT true,
    esta_activo boolean DEFAULT true
);


ALTER TABLE public.personal OWNER TO postgres;

--
-- Name: personal_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_id_seq OWNER TO postgres;

--
-- Name: personal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personal_id_seq OWNED BY public.personal.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre_rol character varying(50) NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: subcategoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subcategoria (
    id_subcategoria integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_categoria integer
);


ALTER TABLE public.subcategoria OWNER TO postgres;

--
-- Name: direccion id_direccion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion ALTER COLUMN id_direccion SET DEFAULT nextval('public.direccion_id_direccion_seq'::regclass);


--
-- Name: personal id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal ALTER COLUMN id SET DEFAULT nextval('public.personal_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id_categoria, nombre) FROM stdin;
1	Física
2	Sensorial
3	Intelectual
4	Psicosocial
\.


--
-- Data for Name: condicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.condicion (id_condicion, nombre, codigo_cif, id_subcategoria) FROM stdin;
1	Parálisis cerebral	a770	1
2	Esclerosis	a770	1
3	Parkinson	a770	1
4	Amputación	a730	2
5	Malformación	a730	2
6	Distrofia	a730	2
7	Paraplejia	a120	3
8	Cuadriplejia	a120	3
9	Ceguera total	a210	4
10	Baja visión	a210	4
11	Sordera total	a230	5
12	Hipoacusia	a230	5
13	Anosmia	a240	6
14	Hipoestesia	a260	6
15	Síndrome de Down	a110	7
16	Retraso global	a110	7
17	TEA grado 1	d160	8
18	TEA grado 2	d160	8
19	TEA grado 3	d160	8
20	Esquizofrenia	b152	9
21	Psicosis	b152	9
22	Depresión mayor	b152	10
23	Trastorno bipolar	b152	10
\.


--
-- Data for Name: direccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.direccion (id_direccion, id_persona, calle, numero_ext, numero_int, colonia, cp, municipio, estado) FROM stdin;
1	16	calle culera generica	9	\N	zona culera generica	0624444	Ecatepec	Estado de Mexico
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.persona (id_persona, nombre, apellido_p, apellido_m, fecha_nacimiento, sexo, nacionalidad) FROM stdin;
\.


--
-- Data for Name: persona_condicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.persona_condicion (id_persona, id_condicion) FROM stdin;
\.


--
-- Data for Name: personal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal (id, nombre, apellido_p, apellido_m, rfc, curp, fecha_nacimiento, sexo, correo, password1, rol_id, es_empleado, esta_activo) FROM stdin;
1	Ian	Director	General	RFC12345	CURP12345	1990-01-01	MASCULINO	director@datacore.com	admin123	1	t	t
9	NPC1	generico 1	generico1	saaaaaaaaaaaa	asssssssssssssssss	2007-07-07	MASCULINO	npcgenerico1@organizacion.org.mx	ola	3	t	f
11	Saul	Mcmuffin	Martinez	MUMS0402271A2	MUMS040227HASCRL01	2004-02-27	MASCULINO	smcmuffin@datacore.com	olis	7	t	f
16	pendejo	tarado	estupido	PETE050725AB3	MUMS040227HASCRL01	2007-05-16	MASCULINO	Ptarado@gmail.com	OLA	3	t	f
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre_rol) FROM stdin;
1	Director
2	Coordinador
3	Psicologo
4	Doctor
5	Abogado
6	Trabajador Social
7	Analista
8	Equipo Multidisciplinario
\.


--
-- Data for Name: subcategoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subcategoria (id_subcategoria, nombre, id_categoria) FROM stdin;
1	Neuromotora	1
2	Musculoesquelética	1
3	Lesión Medular	1
4	Visual	2
5	Auditiva	2
6	Olfativa/Gustativa/Táctil	2
7	Del Desarrollo	3
8	Espectro Autista	3
9	Trastornos Mentales	4
10	Trastornos del Ánimo	4
\.


--
-- Name: direccion_id_direccion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.direccion_id_direccion_seq', 1, true);


--
-- Name: personal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_id_seq', 16, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 8, true);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- Name: condicion condicion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_pkey PRIMARY KEY (id_condicion);


--
-- Name: direccion direccion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_pkey PRIMARY KEY (id_direccion);


--
-- Name: persona_condicion persona_condicion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona_condicion
    ADD CONSTRAINT persona_condicion_pkey PRIMARY KEY (id_persona, id_condicion);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- Name: personal personal_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_correo_key UNIQUE (correo);


--
-- Name: personal personal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_pkey PRIMARY KEY (id);


--
-- Name: roles roles_nombre_rol_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_rol_key UNIQUE (nombre_rol);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: subcategoria subcategoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria
    ADD CONSTRAINT subcategoria_pkey PRIMARY KEY (id_subcategoria);


--
-- Name: condicion condicion_id_subcategoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_id_subcategoria_fkey FOREIGN KEY (id_subcategoria) REFERENCES public.subcategoria(id_subcategoria);


--
-- Name: direccion direccion_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.personal(id) ON DELETE CASCADE;


--
-- Name: persona_condicion persona_condicion_id_condicion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona_condicion
    ADD CONSTRAINT persona_condicion_id_condicion_fkey FOREIGN KEY (id_condicion) REFERENCES public.condicion(id_condicion);


--
-- Name: persona_condicion persona_condicion_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona_condicion
    ADD CONSTRAINT persona_condicion_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona);


--
-- Name: subcategoria subcategoria_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria
    ADD CONSTRAINT subcategoria_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);


--
-- PostgreSQL database dump complete
--

\unrestrict VFN4EEI7gGx4fEX8bqaDg5CxNkW937K3VWeMDZfF0cW88cPe6LPkfnOfyuSYWPk

