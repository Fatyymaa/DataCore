--
-- PostgreSQL database dump
--

\restrict 0hvNdYOO4pGKoF7hhVqDVPcvMyO8e20dM4gK2g1LbXsRGwezPPwdOB6za52Ls7x

-- Dumped from database version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)

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

--
-- Name: fn_un_equipo_por_nna_en_caso(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_un_equipo_por_nna_en_caso() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.fn_un_equipo_por_nna_en_caso() OWNER TO postgres;

--
-- Name: fn_un_equipo_por_nna_en_casonna(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_un_equipo_por_nna_en_casonna() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.fn_un_equipo_por_nna_en_casonna() OWNER TO postgres;

--
-- Name: fn_valida_voluntariado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_valida_voluntariado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.es_empleado = FALSE
       AND NOT (SELECT permite_voluntariado FROM roles WHERE id = NEW.rol_id)
    THEN
        RAISE EXCEPTION 'El rol % no admite voluntariado', NEW.rol_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_valida_voluntariado() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: apoyo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.apoyo (
    id_apo integer NOT NULL,
    id_caso integer NOT NULL,
    id_nna integer NOT NULL,
    id_tipo_apo integer NOT NULL,
    fecha_apo date DEFAULT CURRENT_DATE NOT NULL,
    descripcion character varying(200),
    monto numeric(12,2),
    id_autoriza integer NOT NULL
);


ALTER TABLE public.apoyo OWNER TO postgres;

--
-- Name: apoyo_id_apo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.apoyo_id_apo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.apoyo_id_apo_seq OWNER TO postgres;

--
-- Name: apoyo_id_apo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.apoyo_id_apo_seq OWNED BY public.apoyo.id_apo;


--
-- Name: asentamiento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asentamiento (
    id_asen integer NOT NULL,
    nom_mun character varying(150) NOT NULL,
    nom_col character varying(150),
    cp_asen character varying(5),
    id_ent integer NOT NULL
);


ALTER TABLE public.asentamiento OWNER TO postgres;

--
-- Name: asentamiento_id_asen_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.asentamiento_id_asen_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.asentamiento_id_asen_seq OWNER TO postgres;

--
-- Name: asentamiento_id_asen_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.asentamiento_id_asen_seq OWNED BY public.asentamiento.id_asen;


--
-- Name: asignacion_caso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asignacion_caso (
    id_caso integer NOT NULL,
    id_personal integer NOT NULL,
    rol_id integer NOT NULL,
    fecha_asig date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date
);


ALTER TABLE public.asignacion_caso OWNER TO postgres;

--
-- Name: caso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caso (
    id_caso integer NOT NULL,
    folio_caso character varying(25) NOT NULL,
    nom_caso character varying(150) NOT NULL,
    fecha_aper date DEFAULT CURRENT_DATE NOT NULL,
    fecha_cierre date,
    narracion text,
    id_est_caso integer NOT NULL,
    id_equipo integer
);


ALTER TABLE public.caso OWNER TO postgres;

--
-- Name: caso_derecho; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caso_derecho (
    id_caso integer NOT NULL,
    id_nna integer NOT NULL,
    id_der integer NOT NULL,
    fecha_detec date DEFAULT CURRENT_DATE NOT NULL,
    restituido boolean DEFAULT false NOT NULL,
    fecha_rest date
);


ALTER TABLE public.caso_derecho OWNER TO postgres;

--
-- Name: caso_id_caso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caso_id_caso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.caso_id_caso_seq OWNER TO postgres;

--
-- Name: caso_id_caso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caso_id_caso_seq OWNED BY public.caso.id_caso;


--
-- Name: caso_nna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caso_nna (
    id_caso integer NOT NULL,
    id_nna integer NOT NULL,
    fecha_incorp date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE public.caso_nna OWNER TO postgres;

--
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    nombre character varying(120) NOT NULL
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- Name: cif_catalogo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_catalogo (
    codigo_cif character varying(10) NOT NULL,
    descripcion character varying(250) NOT NULL,
    nivel integer NOT NULL,
    id_dominio integer NOT NULL,
    codigo_padre character varying(10),
    categoria_id integer
);


ALTER TABLE public.cif_catalogo OWNER TO postgres;

--
-- Name: cif_dominio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_dominio (
    id_dominio integer NOT NULL,
    letra character(1) NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.cif_dominio OWNER TO postgres;

--
-- Name: cif_dominio_id_dominio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cif_dominio_id_dominio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cif_dominio_id_dominio_seq OWNER TO postgres;

--
-- Name: cif_dominio_id_dominio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cif_dominio_id_dominio_seq OWNED BY public.cif_dominio.id_dominio;


--
-- Name: cif_eval_actividad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_eval_actividad (
    id_evaluacion integer NOT NULL,
    codigo_cif character varying(10) NOT NULL,
    desempeno integer NOT NULL,
    capacidad integer NOT NULL,
    CONSTRAINT cif_eval_actividad_capacidad_check CHECK (((capacidad >= 0) AND (capacidad <= 9))),
    CONSTRAINT cif_eval_actividad_desempeno_check CHECK (((desempeno >= 0) AND (desempeno <= 9)))
);


ALTER TABLE public.cif_eval_actividad OWNER TO postgres;

--
-- Name: cif_eval_ambiental; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_eval_ambiental (
    id_evaluacion integer NOT NULL,
    codigo_cif character varying(10) NOT NULL,
    impacto integer NOT NULL,
    CONSTRAINT cif_eval_ambiental_impacto_check CHECK (((impacto >= '-4'::integer) AND (impacto <= 4)))
);


ALTER TABLE public.cif_eval_ambiental OWNER TO postgres;

--
-- Name: cif_eval_estructura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_eval_estructura (
    id_evaluacion integer NOT NULL,
    codigo_cif character varying(10) NOT NULL,
    deficiencia integer NOT NULL,
    naturaleza integer NOT NULL,
    localizacion integer NOT NULL,
    CONSTRAINT cif_eval_estructura_deficiencia_check CHECK (((deficiencia >= 0) AND (deficiencia <= 9))),
    CONSTRAINT cif_eval_estructura_localizacion_check CHECK (((localizacion >= 0) AND (localizacion <= 9))),
    CONSTRAINT cif_eval_estructura_naturaleza_check CHECK (((naturaleza >= 0) AND (naturaleza <= 9)))
);


ALTER TABLE public.cif_eval_estructura OWNER TO postgres;

--
-- Name: cif_eval_funcion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_eval_funcion (
    id_evaluacion integer NOT NULL,
    codigo_cif character varying(10) NOT NULL,
    deficiencia integer NOT NULL,
    CONSTRAINT cif_eval_funcion_deficiencia_check CHECK (((deficiencia >= 0) AND (deficiencia <= 9)))
);


ALTER TABLE public.cif_eval_funcion OWNER TO postgres;

--
-- Name: cif_evaluacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_evaluacion (
    id_evaluacion integer NOT NULL,
    id_nna integer NOT NULL,
    id_personal integer NOT NULL,
    fecha_eval date DEFAULT CURRENT_DATE NOT NULL,
    observaciones text
);


ALTER TABLE public.cif_evaluacion OWNER TO postgres;

--
-- Name: cif_evaluacion_id_evaluacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cif_evaluacion_id_evaluacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cif_evaluacion_id_evaluacion_seq OWNER TO postgres;

--
-- Name: cif_evaluacion_id_evaluacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cif_evaluacion_id_evaluacion_seq OWNED BY public.cif_evaluacion.id_evaluacion;


--
-- Name: cif_import; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cif_import (
    categoria character varying(120),
    subcategoria character varying(120),
    codigo_cif character varying(10),
    nombre character varying(200)
);


ALTER TABLE public.cif_import OWNER TO postgres;

--
-- Name: condicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.condicion (
    id_condicion integer NOT NULL,
    nombre character varying(200) NOT NULL,
    codigo_cif character varying(10),
    id_subcategoria integer,
    id_grado_dif integer,
    id_grado_dep integer
);


ALTER TABLE public.condicion OWNER TO postgres;

--
-- Name: condicion_funcion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.condicion_funcion (
    id_condicion integer NOT NULL,
    id_funcion integer NOT NULL
);


ALTER TABLE public.condicion_funcion OWNER TO postgres;

--
-- Name: condicion_producto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.condicion_producto (
    id_condicion integer NOT NULL,
    id_producto integer NOT NULL
);


ALTER TABLE public.condicion_producto OWNER TO postgres;

--
-- Name: consulta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.consulta (
    id_consul integer NOT NULL,
    id_nna integer NOT NULL,
    id_personal integer NOT NULL,
    id_tipo_consul integer NOT NULL,
    fecha_consul timestamp without time zone DEFAULT now() NOT NULL,
    motivo character varying(200),
    notas text
);


ALTER TABLE public.consulta OWNER TO postgres;

--
-- Name: consulta_id_consul_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.consulta_id_consul_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.consulta_id_consul_seq OWNER TO postgres;

--
-- Name: consulta_id_consul_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.consulta_id_consul_seq OWNED BY public.consulta.id_consul;


--
-- Name: contacto_nna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contacto_nna (
    id_contacto integer NOT NULL,
    id_nna integer NOT NULL,
    id_tipo_con integer NOT NULL,
    valor character varying(150) NOT NULL
);


ALTER TABLE public.contacto_nna OWNER TO postgres;

--
-- Name: contacto_nna_id_contacto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacto_nna_id_contacto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contacto_nna_id_contacto_seq OWNER TO postgres;

--
-- Name: contacto_nna_id_contacto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacto_nna_id_contacto_seq OWNED BY public.contacto_nna.id_contacto;


--
-- Name: contacto_personal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contacto_personal (
    id_contacto integer NOT NULL,
    id_personal integer NOT NULL,
    id_tipo_con integer NOT NULL,
    valor character varying(150) NOT NULL
);


ALTER TABLE public.contacto_personal OWNER TO postgres;

--
-- Name: contacto_personal_id_contacto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacto_personal_id_contacto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contacto_personal_id_contacto_seq OWNER TO postgres;

--
-- Name: contacto_personal_id_contacto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacto_personal_id_contacto_seq OWNED BY public.contacto_personal.id_contacto;


--
-- Name: contacto_tutor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contacto_tutor (
    id_contacto integer NOT NULL,
    id_tutor integer NOT NULL,
    id_tipo_con integer NOT NULL,
    valor character varying(150) NOT NULL
);


ALTER TABLE public.contacto_tutor OWNER TO postgres;

--
-- Name: contacto_tutor_id_contacto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contacto_tutor_id_contacto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contacto_tutor_id_contacto_seq OWNER TO postgres;

--
-- Name: contacto_tutor_id_contacto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contacto_tutor_id_contacto_seq OWNED BY public.contacto_tutor.id_contacto;


--
-- Name: derecho; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.derecho (
    id_der integer NOT NULL,
    nom_der character varying(150) NOT NULL
);


ALTER TABLE public.derecho OWNER TO postgres;

--
-- Name: derecho_id_der_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.derecho_id_der_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.derecho_id_der_seq OWNER TO postgres;

--
-- Name: derecho_id_der_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.derecho_id_der_seq OWNED BY public.derecho.id_der;


--
-- Name: direccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.direccion (
    id_direccion integer NOT NULL,
    calle character varying(150) NOT NULL,
    numero_ext character varying(20) NOT NULL,
    numero_int character varying(20),
    referencias character varying(200),
    id_asen integer NOT NULL
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
-- Name: donacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donacion (
    id_donacion integer NOT NULL,
    id_don integer NOT NULL,
    fecha date DEFAULT CURRENT_DATE NOT NULL,
    observacion character varying(200)
);


ALTER TABLE public.donacion OWNER TO postgres;

--
-- Name: donacion_especie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donacion_especie (
    id_donacion integer NOT NULL,
    descripcion character varying(200) NOT NULL,
    cantidad numeric(10,2) NOT NULL,
    valor_est numeric(12,2),
    CONSTRAINT donacion_especie_cantidad_check CHECK ((cantidad > (0)::numeric))
);


ALTER TABLE public.donacion_especie OWNER TO postgres;

--
-- Name: donacion_id_donacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.donacion_id_donacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.donacion_id_donacion_seq OWNER TO postgres;

--
-- Name: donacion_id_donacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.donacion_id_donacion_seq OWNED BY public.donacion.id_donacion;


--
-- Name: donacion_monetaria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donacion_monetaria (
    id_donacion integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    id_met_pago integer NOT NULL,
    CONSTRAINT donacion_monetaria_monto_check CHECK ((monto > (0)::numeric))
);


ALTER TABLE public.donacion_monetaria OWNER TO postgres;

--
-- Name: donante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donante (
    id_don integer NOT NULL,
    fecha_reg date DEFAULT CURRENT_DATE NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.donante OWNER TO postgres;

--
-- Name: donante_fisico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donante_fisico (
    id_don integer NOT NULL,
    nombre character varying(150) NOT NULL,
    apellido_p character varying(150),
    apellido_m character varying(150),
    rfc character varying(13)
);


ALTER TABLE public.donante_fisico OWNER TO postgres;

--
-- Name: donante_id_don_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.donante_id_don_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.donante_id_don_seq OWNER TO postgres;

--
-- Name: donante_id_don_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.donante_id_don_seq OWNED BY public.donante.id_don;


--
-- Name: donante_moral; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donante_moral (
    id_don integer NOT NULL,
    razon_social character varying(150) NOT NULL,
    rfc character varying(12) NOT NULL,
    representante character varying(150)
);


ALTER TABLE public.donante_moral OWNER TO postgres;

--
-- Name: enfermedad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enfermedad (
    id_enf integer NOT NULL,
    nombre character varying(150) NOT NULL,
    codigo_cie character varying(20),
    id_tipo_enf integer,
    cronica boolean DEFAULT false
);


ALTER TABLE public.enfermedad OWNER TO postgres;

--
-- Name: enfermedad_id_enf_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.enfermedad_id_enf_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enfermedad_id_enf_seq OWNER TO postgres;

--
-- Name: enfermedad_id_enf_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.enfermedad_id_enf_seq OWNED BY public.enfermedad.id_enf;


--
-- Name: entidad_federativa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entidad_federativa (
    id_ent integer NOT NULL,
    nom_ent character varying(100) NOT NULL
);


ALTER TABLE public.entidad_federativa OWNER TO postgres;

--
-- Name: entidad_federativa_id_ent_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entidad_federativa_id_ent_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.entidad_federativa_id_ent_seq OWNER TO postgres;

--
-- Name: entidad_federativa_id_ent_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entidad_federativa_id_ent_seq OWNED BY public.entidad_federativa.id_ent;


--
-- Name: equipo_miembro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo_miembro (
    id_equipo integer NOT NULL,
    id_personal integer NOT NULL,
    fecha_alta date DEFAULT CURRENT_DATE NOT NULL,
    fecha_baja date
);


ALTER TABLE public.equipo_miembro OWNER TO postgres;

--
-- Name: equipo_multidisciplinario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo_multidisciplinario (
    id_equipo integer NOT NULL,
    nom_equipo character varying(100) NOT NULL,
    fecha_crea date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE public.equipo_multidisciplinario OWNER TO postgres;

--
-- Name: equipo_multidisciplinario_id_equipo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipo_multidisciplinario_id_equipo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipo_multidisciplinario_id_equipo_seq OWNER TO postgres;

--
-- Name: equipo_multidisciplinario_id_equipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipo_multidisciplinario_id_equipo_seq OWNED BY public.equipo_multidisciplinario.id_equipo;


--
-- Name: escolaridad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.escolaridad (
    id_esc integer NOT NULL,
    nom_esc character varying(50) NOT NULL
);


ALTER TABLE public.escolaridad OWNER TO postgres;

--
-- Name: escolaridad_id_esc_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.escolaridad_id_esc_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.escolaridad_id_esc_seq OWNER TO postgres;

--
-- Name: escolaridad_id_esc_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.escolaridad_id_esc_seq OWNED BY public.escolaridad.id_esc;


--
-- Name: estatus_caso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estatus_caso (
    id_est_caso integer NOT NULL,
    nom_est_caso character varying(40) NOT NULL
);


ALTER TABLE public.estatus_caso OWNER TO postgres;

--
-- Name: estatus_caso_id_est_caso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estatus_caso_id_est_caso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estatus_caso_id_est_caso_seq OWNER TO postgres;

--
-- Name: estatus_caso_id_est_caso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estatus_caso_id_est_caso_seq OWNED BY public.estatus_caso.id_est_caso;


--
-- Name: funcion_corporal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.funcion_corporal (
    id_funcion integer NOT NULL,
    nom_funcion character varying(120) NOT NULL,
    codigo_cif character varying(10)
);


ALTER TABLE public.funcion_corporal OWNER TO postgres;

--
-- Name: funcion_corporal_id_funcion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.funcion_corporal_id_funcion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.funcion_corporal_id_funcion_seq OWNER TO postgres;

--
-- Name: funcion_corporal_id_funcion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.funcion_corporal_id_funcion_seq OWNED BY public.funcion_corporal.id_funcion;


--
-- Name: grado_dependencia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grado_dependencia (
    id_grado_dep integer NOT NULL,
    nom_grado_dep character varying(50)
);


ALTER TABLE public.grado_dependencia OWNER TO postgres;

--
-- Name: grado_dificultad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grado_dificultad (
    id_grado_dif integer NOT NULL,
    nom_grado_dif character varying(50),
    codigo_cif_dif character varying(10),
    desc_cualitativa character varying(100),
    rango_porcent character varying(20)
);


ALTER TABLE public.grado_dificultad OWNER TO postgres;

--
-- Name: hecho_dano; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hecho_dano (
    id_caso integer NOT NULL,
    id_tipo_dano integer NOT NULL
);


ALTER TABLE public.hecho_dano OWNER TO postgres;

--
-- Name: hecho_victimizante; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hecho_victimizante (
    id_caso integer NOT NULL,
    id_tipo_vic integer NOT NULL,
    fecha_hecho date,
    lugar_hecho integer,
    relato text,
    victima_directa_nombre character varying(200),
    victima_directa_parentesco integer,
    folio_renavi character varying(50),
    carpeta_investigacion character varying(50),
    autoridad_conoce character varying(200),
    fecha_registro date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE public.hecho_victimizante OWNER TO postgres;

--
-- Name: lengua; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lengua (
    id_len integer NOT NULL,
    familia_len character varying(100),
    agrupacion_len character varying(100),
    variante_len character varying(100),
    autodenom_len character varying(100)
);


ALTER TABLE public.lengua OWNER TO postgres;

--
-- Name: lengua_id_len_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lengua_id_len_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lengua_id_len_seq OWNER TO postgres;

--
-- Name: lengua_id_len_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lengua_id_len_seq OWNED BY public.lengua.id_len;


--
-- Name: lenguaje_nna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lenguaje_nna (
    id_nna integer NOT NULL,
    id_len integer NOT NULL,
    preferente boolean DEFAULT false,
    id_mod_adc integer,
    id_niv_com integer,
    id_niv_escrito integer,
    id_personal_registro integer
);


ALTER TABLE public.lenguaje_nna OWNER TO postgres;

--
-- Name: lenguaje_tutor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lenguaje_tutor (
    id_tutor integer NOT NULL,
    id_len integer NOT NULL,
    preferente boolean DEFAULT false,
    id_mod_adc integer,
    id_niv_com integer,
    id_niv_escrito integer
);


ALTER TABLE public.lenguaje_tutor OWNER TO postgres;

--
-- Name: metodo_pago; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.metodo_pago (
    id_met_pago integer NOT NULL,
    nom_met_pago character varying(40) NOT NULL
);


ALTER TABLE public.metodo_pago OWNER TO postgres;

--
-- Name: metodo_pago_id_met_pago_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.metodo_pago_id_met_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.metodo_pago_id_met_pago_seq OWNER TO postgres;

--
-- Name: metodo_pago_id_met_pago_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.metodo_pago_id_met_pago_seq OWNED BY public.metodo_pago.id_met_pago;


--
-- Name: modo_adquisicion_lengua; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modo_adquisicion_lengua (
    id_mod_adc integer NOT NULL,
    categ_mod_adc character varying(100),
    desc_mod_adc character varying(200)
);


ALTER TABLE public.modo_adquisicion_lengua OWNER TO postgres;

--
-- Name: modo_adquisicion_lengua_id_mod_adc_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modo_adquisicion_lengua_id_mod_adc_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modo_adquisicion_lengua_id_mod_adc_seq OWNER TO postgres;

--
-- Name: modo_adquisicion_lengua_id_mod_adc_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modo_adquisicion_lengua_id_mod_adc_seq OWNED BY public.modo_adquisicion_lengua.id_mod_adc;


--
-- Name: nacionalidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nacionalidad (
    id_nac integer NOT NULL,
    nom_nac character varying(50) NOT NULL
);


ALTER TABLE public.nacionalidad OWNER TO postgres;

--
-- Name: nacionalidad_id_nac_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nacionalidad_id_nac_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nacionalidad_id_nac_seq OWNER TO postgres;

--
-- Name: nacionalidad_id_nac_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nacionalidad_id_nac_seq OWNED BY public.nacionalidad.id_nac;


--
-- Name: nacionalidad_nna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nacionalidad_nna (
    id_nna integer NOT NULL,
    id_nac integer NOT NULL
);


ALTER TABLE public.nacionalidad_nna OWNER TO postgres;

--
-- Name: nivel_competencia_oral; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nivel_competencia_oral (
    id_niv_com integer NOT NULL,
    niv_prac_com character varying(100),
    sign_niv_com character varying(200)
);


ALTER TABLE public.nivel_competencia_oral OWNER TO postgres;

--
-- Name: nivel_competencia_oral_id_niv_com_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nivel_competencia_oral_id_niv_com_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nivel_competencia_oral_id_niv_com_seq OWNER TO postgres;

--
-- Name: nivel_competencia_oral_id_niv_com_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nivel_competencia_oral_id_niv_com_seq OWNED BY public.nivel_competencia_oral.id_niv_com;


--
-- Name: nna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nna (
    id_nna integer NOT NULL,
    folio_nna character varying(10),
    nombre character varying(150) NOT NULL,
    apellido_p character varying(150),
    apellido_m character varying(150),
    fecha_nacimiento date,
    curp character varying(18),
    id_sexo integer,
    id_esc integer,
    id_direccion integer,
    lugar_nacimiento integer
);


ALTER TABLE public.nna OWNER TO postgres;

--
-- Name: nna_condicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nna_condicion (
    id_nna integer NOT NULL,
    id_condicion integer NOT NULL,
    fecha_diag date,
    diagnosticada boolean DEFAULT false,
    id_grado_dif integer,
    id_grado_dep integer
);


ALTER TABLE public.nna_condicion OWNER TO postgres;

--
-- Name: nna_enfermedad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nna_enfermedad (
    id_nna integer NOT NULL,
    id_enf integer NOT NULL,
    fecha_diag date,
    en_tratamiento boolean DEFAULT false
);


ALTER TABLE public.nna_enfermedad OWNER TO postgres;

--
-- Name: nna_id_nna_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nna_id_nna_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nna_id_nna_seq OWNER TO postgres;

--
-- Name: nna_id_nna_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nna_id_nna_seq OWNED BY public.nna.id_nna;


--
-- Name: nna_tutor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nna_tutor (
    id_nna integer NOT NULL,
    id_tutor integer NOT NULL,
    fecha_ini date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date,
    id_paren integer,
    tutor_legal boolean DEFAULT false
);


ALTER TABLE public.nna_tutor OWNER TO postgres;

--
-- Name: parentesco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parentesco (
    id_paren integer NOT NULL,
    nom_paren character varying(50) NOT NULL
);


ALTER TABLE public.parentesco OWNER TO postgres;

--
-- Name: parentesco_id_paren_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parentesco_id_paren_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parentesco_id_paren_seq OWNER TO postgres;

--
-- Name: parentesco_id_paren_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parentesco_id_paren_seq OWNED BY public.parentesco.id_paren;


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
    id_sexo integer,
    id_direccion integer,
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
-- Name: personal_lengua; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal_lengua (
    id_personal integer NOT NULL,
    id_len integer NOT NULL,
    id_mod_adc integer,
    id_niv_com integer,
    id_niv_escrito integer
);


ALTER TABLE public.personal_lengua OWNER TO postgres;

--
-- Name: producto_apoyo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto_apoyo (
    id_producto integer NOT NULL,
    nom_producto character varying(120) NOT NULL,
    codigo_cif character varying(10)
);


ALTER TABLE public.producto_apoyo OWNER TO postgres;

--
-- Name: producto_apoyo_id_producto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.producto_apoyo_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.producto_apoyo_id_producto_seq OWNER TO postgres;

--
-- Name: producto_apoyo_id_producto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.producto_apoyo_id_producto_seq OWNED BY public.producto_apoyo.id_producto;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre_rol character varying(50) NOT NULL,
    permite_voluntariado boolean DEFAULT false NOT NULL
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
-- Name: seguimiento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.seguimiento (
    id_seg integer NOT NULL,
    id_caso integer NOT NULL,
    id_personal integer NOT NULL,
    fecha_seg date DEFAULT CURRENT_DATE NOT NULL,
    descripcion text NOT NULL
);


ALTER TABLE public.seguimiento OWNER TO postgres;

--
-- Name: seguimiento_id_seg_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seguimiento_id_seg_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seguimiento_id_seg_seq OWNER TO postgres;

--
-- Name: seguimiento_id_seg_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.seguimiento_id_seg_seq OWNED BY public.seguimiento.id_seg;


--
-- Name: sexo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sexo (
    id_sexo integer NOT NULL,
    nom_sexo character varying(20) NOT NULL
);


ALTER TABLE public.sexo OWNER TO postgres;

--
-- Name: sexo_id_sexo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sexo_id_sexo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sexo_id_sexo_seq OWNER TO postgres;

--
-- Name: sexo_id_sexo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sexo_id_sexo_seq OWNED BY public.sexo.id_sexo;


--
-- Name: subcategoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subcategoria (
    id_subcategoria integer NOT NULL,
    nombre character varying(120) NOT NULL,
    id_categoria integer
);


ALTER TABLE public.subcategoria OWNER TO postgres;

--
-- Name: tipo_apoyo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_apoyo (
    id_tipo_apo integer NOT NULL,
    nom_tipo_apo character varying(60) NOT NULL
);


ALTER TABLE public.tipo_apoyo OWNER TO postgres;

--
-- Name: tipo_apoyo_id_tipo_apo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_apoyo_id_tipo_apo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_apoyo_id_tipo_apo_seq OWNER TO postgres;

--
-- Name: tipo_apoyo_id_tipo_apo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_apoyo_id_tipo_apo_seq OWNED BY public.tipo_apoyo.id_tipo_apo;


--
-- Name: tipo_consulta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_consulta (
    id_tipo_consul integer NOT NULL,
    nom_tipo_consul character varying(40) NOT NULL
);


ALTER TABLE public.tipo_consulta OWNER TO postgres;

--
-- Name: tipo_consulta_id_tipo_consul_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_consulta_id_tipo_consul_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_consulta_id_tipo_consul_seq OWNER TO postgres;

--
-- Name: tipo_consulta_id_tipo_consul_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_consulta_id_tipo_consul_seq OWNED BY public.tipo_consulta.id_tipo_consul;


--
-- Name: tipo_contacto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_contacto (
    id_tipo_con integer NOT NULL,
    nom_tipo_con character varying(30) NOT NULL
);


ALTER TABLE public.tipo_contacto OWNER TO postgres;

--
-- Name: tipo_contacto_id_tipo_con_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_contacto_id_tipo_con_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_contacto_id_tipo_con_seq OWNER TO postgres;

--
-- Name: tipo_contacto_id_tipo_con_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_contacto_id_tipo_con_seq OWNED BY public.tipo_contacto.id_tipo_con;


--
-- Name: tipo_dano; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_dano (
    id_tipo_dano integer NOT NULL,
    nom_tipo_dano character varying(50) NOT NULL
);


ALTER TABLE public.tipo_dano OWNER TO postgres;

--
-- Name: tipo_dano_id_tipo_dano_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_dano_id_tipo_dano_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_dano_id_tipo_dano_seq OWNER TO postgres;

--
-- Name: tipo_dano_id_tipo_dano_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_dano_id_tipo_dano_seq OWNED BY public.tipo_dano.id_tipo_dano;


--
-- Name: tipo_enfermedad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_enfermedad (
    id_tipo_enf integer NOT NULL,
    nom_tipo_enf character varying(80) NOT NULL
);


ALTER TABLE public.tipo_enfermedad OWNER TO postgres;

--
-- Name: tipo_enfermedad_id_tipo_enf_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_enfermedad_id_tipo_enf_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_enfermedad_id_tipo_enf_seq OWNER TO postgres;

--
-- Name: tipo_enfermedad_id_tipo_enf_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_enfermedad_id_tipo_enf_seq OWNED BY public.tipo_enfermedad.id_tipo_enf;


--
-- Name: tipo_victima; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_victima (
    id_tipo_vic integer NOT NULL,
    nom_tipo_vic character varying(50) NOT NULL,
    descripcion character varying(200)
);


ALTER TABLE public.tipo_victima OWNER TO postgres;

--
-- Name: tipo_victima_id_tipo_vic_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_victima_id_tipo_vic_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_victima_id_tipo_vic_seq OWNER TO postgres;

--
-- Name: tipo_victima_id_tipo_vic_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_victima_id_tipo_vic_seq OWNED BY public.tipo_victima.id_tipo_vic;


--
-- Name: tutor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tutor (
    id_tutor integer NOT NULL,
    nombre character varying(150) NOT NULL,
    apellido_p character varying(150),
    apellido_m character varying(150),
    fecha_nacimiento date,
    curp character varying(18),
    ocupacion character varying(100),
    id_sexo integer,
    id_direccion integer
);


ALTER TABLE public.tutor OWNER TO postgres;

--
-- Name: tutor_condicion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tutor_condicion (
    id_tutor integer NOT NULL,
    id_condicion integer NOT NULL,
    id_grado_dif integer,
    id_grado_dep integer
);


ALTER TABLE public.tutor_condicion OWNER TO postgres;

--
-- Name: tutor_id_tutor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tutor_id_tutor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tutor_id_tutor_seq OWNER TO postgres;

--
-- Name: tutor_id_tutor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tutor_id_tutor_seq OWNED BY public.tutor.id_tutor;


--
-- Name: ubicacion_lengua; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ubicacion_lengua (
    id_ent integer NOT NULL,
    id_len integer NOT NULL
);


ALTER TABLE public.ubicacion_lengua OWNER TO postgres;

--
-- Name: apoyo id_apo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.apoyo ALTER COLUMN id_apo SET DEFAULT nextval('public.apoyo_id_apo_seq'::regclass);


--
-- Name: asentamiento id_asen; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asentamiento ALTER COLUMN id_asen SET DEFAULT nextval('public.asentamiento_id_asen_seq'::regclass);


--
-- Name: caso id_caso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso ALTER COLUMN id_caso SET DEFAULT nextval('public.caso_id_caso_seq'::regclass);


--
-- Name: cif_dominio id_dominio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_dominio ALTER COLUMN id_dominio SET DEFAULT nextval('public.cif_dominio_id_dominio_seq'::regclass);


--
-- Name: cif_evaluacion id_evaluacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_evaluacion ALTER COLUMN id_evaluacion SET DEFAULT nextval('public.cif_evaluacion_id_evaluacion_seq'::regclass);


--
-- Name: consulta id_consul; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consulta ALTER COLUMN id_consul SET DEFAULT nextval('public.consulta_id_consul_seq'::regclass);


--
-- Name: contacto_nna id_contacto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_nna ALTER COLUMN id_contacto SET DEFAULT nextval('public.contacto_nna_id_contacto_seq'::regclass);


--
-- Name: contacto_personal id_contacto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_personal ALTER COLUMN id_contacto SET DEFAULT nextval('public.contacto_personal_id_contacto_seq'::regclass);


--
-- Name: contacto_tutor id_contacto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_tutor ALTER COLUMN id_contacto SET DEFAULT nextval('public.contacto_tutor_id_contacto_seq'::regclass);


--
-- Name: derecho id_der; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.derecho ALTER COLUMN id_der SET DEFAULT nextval('public.derecho_id_der_seq'::regclass);


--
-- Name: direccion id_direccion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion ALTER COLUMN id_direccion SET DEFAULT nextval('public.direccion_id_direccion_seq'::regclass);


--
-- Name: donacion id_donacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion ALTER COLUMN id_donacion SET DEFAULT nextval('public.donacion_id_donacion_seq'::regclass);


--
-- Name: donante id_don; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante ALTER COLUMN id_don SET DEFAULT nextval('public.donante_id_don_seq'::regclass);


--
-- Name: enfermedad id_enf; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enfermedad ALTER COLUMN id_enf SET DEFAULT nextval('public.enfermedad_id_enf_seq'::regclass);


--
-- Name: entidad_federativa id_ent; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entidad_federativa ALTER COLUMN id_ent SET DEFAULT nextval('public.entidad_federativa_id_ent_seq'::regclass);


--
-- Name: equipo_multidisciplinario id_equipo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_multidisciplinario ALTER COLUMN id_equipo SET DEFAULT nextval('public.equipo_multidisciplinario_id_equipo_seq'::regclass);


--
-- Name: escolaridad id_esc; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escolaridad ALTER COLUMN id_esc SET DEFAULT nextval('public.escolaridad_id_esc_seq'::regclass);


--
-- Name: estatus_caso id_est_caso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_caso ALTER COLUMN id_est_caso SET DEFAULT nextval('public.estatus_caso_id_est_caso_seq'::regclass);


--
-- Name: funcion_corporal id_funcion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion_corporal ALTER COLUMN id_funcion SET DEFAULT nextval('public.funcion_corporal_id_funcion_seq'::regclass);


--
-- Name: lengua id_len; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lengua ALTER COLUMN id_len SET DEFAULT nextval('public.lengua_id_len_seq'::regclass);


--
-- Name: metodo_pago id_met_pago; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metodo_pago ALTER COLUMN id_met_pago SET DEFAULT nextval('public.metodo_pago_id_met_pago_seq'::regclass);


--
-- Name: modo_adquisicion_lengua id_mod_adc; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modo_adquisicion_lengua ALTER COLUMN id_mod_adc SET DEFAULT nextval('public.modo_adquisicion_lengua_id_mod_adc_seq'::regclass);


--
-- Name: nacionalidad id_nac; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad ALTER COLUMN id_nac SET DEFAULT nextval('public.nacionalidad_id_nac_seq'::regclass);


--
-- Name: nivel_competencia_oral id_niv_com; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nivel_competencia_oral ALTER COLUMN id_niv_com SET DEFAULT nextval('public.nivel_competencia_oral_id_niv_com_seq'::regclass);


--
-- Name: nna id_nna; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna ALTER COLUMN id_nna SET DEFAULT nextval('public.nna_id_nna_seq'::regclass);


--
-- Name: parentesco id_paren; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco ALTER COLUMN id_paren SET DEFAULT nextval('public.parentesco_id_paren_seq'::regclass);


--
-- Name: personal id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal ALTER COLUMN id SET DEFAULT nextval('public.personal_id_seq'::regclass);


--
-- Name: producto_apoyo id_producto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_apoyo ALTER COLUMN id_producto SET DEFAULT nextval('public.producto_apoyo_id_producto_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: seguimiento id_seg; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seguimiento ALTER COLUMN id_seg SET DEFAULT nextval('public.seguimiento_id_seg_seq'::regclass);


--
-- Name: sexo id_sexo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexo ALTER COLUMN id_sexo SET DEFAULT nextval('public.sexo_id_sexo_seq'::regclass);


--
-- Name: tipo_apoyo id_tipo_apo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_apoyo ALTER COLUMN id_tipo_apo SET DEFAULT nextval('public.tipo_apoyo_id_tipo_apo_seq'::regclass);


--
-- Name: tipo_consulta id_tipo_consul; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_consulta ALTER COLUMN id_tipo_consul SET DEFAULT nextval('public.tipo_consulta_id_tipo_consul_seq'::regclass);


--
-- Name: tipo_contacto id_tipo_con; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_contacto ALTER COLUMN id_tipo_con SET DEFAULT nextval('public.tipo_contacto_id_tipo_con_seq'::regclass);


--
-- Name: tipo_dano id_tipo_dano; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_dano ALTER COLUMN id_tipo_dano SET DEFAULT nextval('public.tipo_dano_id_tipo_dano_seq'::regclass);


--
-- Name: tipo_enfermedad id_tipo_enf; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_enfermedad ALTER COLUMN id_tipo_enf SET DEFAULT nextval('public.tipo_enfermedad_id_tipo_enf_seq'::regclass);


--
-- Name: tipo_victima id_tipo_vic; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_victima ALTER COLUMN id_tipo_vic SET DEFAULT nextval('public.tipo_victima_id_tipo_vic_seq'::regclass);


--
-- Name: tutor id_tutor; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor ALTER COLUMN id_tutor SET DEFAULT nextval('public.tutor_id_tutor_seq'::regclass);


--
-- Data for Name: apoyo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.apoyo (id_apo, id_caso, id_nna, id_tipo_apo, fecha_apo, descripcion, monto, id_autoriza) FROM stdin;
\.


--
-- Data for Name: asentamiento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asentamiento (id_asen, nom_mun, nom_col, cp_asen, id_ent) FROM stdin;
\.


--
-- Data for Name: asignacion_caso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asignacion_caso (id_caso, id_personal, rol_id, fecha_asig, fecha_fin) FROM stdin;
\.


--
-- Data for Name: caso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caso (id_caso, folio_caso, nom_caso, fecha_aper, fecha_cierre, narracion, id_est_caso, id_equipo) FROM stdin;
\.


--
-- Data for Name: caso_derecho; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caso_derecho (id_caso, id_nna, id_der, fecha_detec, restituido, fecha_rest) FROM stdin;
\.


--
-- Data for Name: caso_nna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caso_nna (id_caso, id_nna, fecha_incorp) FROM stdin;
\.


--
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id_categoria, nombre) FROM stdin;
1	Física
2	Intelectual
3	Psicosocial
4	Sensorial
\.


--
-- Data for Name: cif_catalogo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_catalogo (codigo_cif, descripcion, nivel, id_dominio, codigo_padre, categoria_id) FROM stdin;
b1	Funciones mentales	1	1	\N	\N
b2	Funciones sensoriales y dolor	1	1	\N	\N
b3	Funciones de la voz y el habla	1	1	\N	\N
b4	Funciones de los sistemas cardiovascular, hematológico, inmunológico y respiratorio	1	1	\N	\N
b5	Funciones de los sistemas digestivo, metabólico y endocrino	1	1	\N	\N
b6	Funciones genitourinarias y reproductoras	1	1	\N	\N
b7	Funciones neuromusculoesqueléticas y relacionadas con el movimiento	1	1	\N	\N
b8	Funciones de la piel y estructuras relacionadas	1	1	\N	\N
s1	Estructuras del sistema nervioso	1	2	\N	\N
s2	El ojo, el oído y estructuras relacionadas	1	2	\N	\N
s3	Estructuras involucradas en la voz y el habla	1	2	\N	\N
s4	Estructuras de los sistemas cardiovascular, inmunológico y respiratorio	1	2	\N	\N
s5	Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino	1	2	\N	\N
s6	Estructuras relacionadas con el sistema genitourinario y el sistema reproductor	1	2	\N	\N
s7	Estructuras relacionadas con el movimiento	1	2	\N	\N
s8	Piel y estructuras relacionadas	1	2	\N	\N
d1	Aprendizaje y aplicación del conocimiento	1	3	\N	\N
d2	Tareas y demandas generales	1	3	\N	\N
d3	Comunicación	1	3	\N	\N
d4	Movilidad	1	3	\N	\N
d5	Autocuidado	1	3	\N	\N
d6	Vida doméstica	1	3	\N	\N
d7	Interacciones y relaciones interpersonales	1	3	\N	\N
d8	Áreas principales de la vida	1	3	\N	\N
d9	Vida comunitaria, social y cívica	1	3	\N	\N
e1	Productos y tecnología	1	4	\N	\N
e2	Entorno natural y cambios en el entorno derivados de la actividad humana	1	4	\N	\N
e3	Apoyo y relaciones	1	4	\N	\N
e4	Actitudes	1	4	\N	\N
e5	Servicios, sistemas y políticas	1	4	\N	\N
\.


--
-- Data for Name: cif_dominio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_dominio (id_dominio, letra, nombre) FROM stdin;
1	b	Funciones corporales
2	s	Estructuras corporales
3	d	Actividades y participación
4	e	Factores ambientales
\.


--
-- Data for Name: cif_eval_actividad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_eval_actividad (id_evaluacion, codigo_cif, desempeno, capacidad) FROM stdin;
\.


--
-- Data for Name: cif_eval_ambiental; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_eval_ambiental (id_evaluacion, codigo_cif, impacto) FROM stdin;
\.


--
-- Data for Name: cif_eval_estructura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_eval_estructura (id_evaluacion, codigo_cif, deficiencia, naturaleza, localizacion) FROM stdin;
\.


--
-- Data for Name: cif_eval_funcion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_eval_funcion (id_evaluacion, codigo_cif, deficiencia) FROM stdin;
\.


--
-- Data for Name: cif_evaluacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_evaluacion (id_evaluacion, id_nna, id_personal, fecha_eval, observaciones) FROM stdin;
\.


--
-- Data for Name: cif_import; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cif_import (categoria, subcategoria, codigo_cif, nombre) FROM stdin;
\.


--
-- Data for Name: condicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.condicion (id_condicion, nombre, codigo_cif, id_subcategoria, id_grado_dif, id_grado_dep) FROM stdin;
1	Funciones de la conciencia	b110	20	\N	\N
2	Nivel de Conciencia	b1100	20	\N	\N
3	Continuidad de la conciencia	b1101	20	\N	\N
4	Cualidad de la conciencia	b1102	20	\N	\N
5	Regulacion de los estados de vigilia	b1103	20	\N	\N
6	Funciones de la conciencia, otras especificadas	b1108	20	\N	\N
7	Funciones de la conciencia, no especificadas	b1109	20	\N	\N
8	Funciones de la orientación	b114	20	\N	\N
9	Orientación respecto al tiempo	b1140	20	\N	\N
10	Orientación respecto al lugar	b1141	20	\N	\N
11	Orientación respecto a la persona	b1142	20	\N	\N
12	Orientación respecto a uno mismo	b11420	20	\N	\N
13	Orientación respecto a los demás	b11421	20	\N	\N
14	Funciones de la orientación respecto a la persona, otras especificadas	b11428	20	\N	\N
15	Funciones de la orientación respecto a la persona, no especificadas	b11429	20	\N	\N
16	Orientación respecto a los objetos	b1143	20	\N	\N
17	Orientación respecto al espacio	b1144	20	\N	\N
18	Funciones de la orientación, otras especificadas	b1148	20	\N	\N
19	Funciones de la orientación, no especificadas	b1149	20	\N	\N
20	Funciones intelectuales	b117	20	\N	\N
21	Funciones psicosociales globales	b122	20	\N	\N
22	Funciones relacionadas con la predisposición y el funcionamiento intrapersonal	b125	20	\N	\N
23	Adaptibilidad	b1250	20	\N	\N
24	Responsabilidad	b1251	20	\N	\N
25	Nivel de actividad	b1252	20	\N	\N
26	Predictibilidad	b1253	20	\N	\N
27	Persistencia	b1254	20	\N	\N
28	Abordabilidad	b1255	20	\N	\N
29	Predisposición y funcionamiento intra-personal, otras especificadas	b1258	20	\N	\N
30	Predisposición y funcionamiento intra-personal, no especificadas	b1259	20	\N	\N
31	Funciones del temperamento y la personalidad	b126	20	\N	\N
32	Extroversión	b1260	20	\N	\N
33	Amabilidad	b1261	20	\N	\N
34	Responsabilidad	b1262	20	\N	\N
35	Estabilidad psíquica	b1263	20	\N	\N
36	Disposición a vivir nuevas experiencias	b1264	20	\N	\N
37	Optimismo	b1265	20	\N	\N
38	Confianza	b1266	20	\N	\N
39	Ser digno de confianza	b1267	20	\N	\N
40	Funciones del temperamento y la personalidad, otras especificadas	b1268	20	\N	\N
41	Funciones del temperamento y la personalidad, no especificadas	b1269	20	\N	\N
42	Funciones relacionadas con la energía y los impulsos	b130	20	\N	\N
43	Nivel de energía	b1300	20	\N	\N
44	Motivación	b1301	20	\N	\N
45	Apetito	b1302	20	\N	\N
46	Ansia "Craving"	b1303	20	\N	\N
47	Control de los impulsos	b1304	20	\N	\N
48	Funciones relacionadas con la energía y los impulsos, otras especificadas	b1308	20	\N	\N
49	Funciones relacionadas con la energía y los impulsos, no especificadas	b1309	20	\N	\N
50	Funciones del sueño	b134	20	\N	\N
51	Cantidad del sueño	b1340	20	\N	\N
52	Comienzo del sueño	b1341	20	\N	\N
53	Mantenimiento del sueño	b1342	20	\N	\N
54	Calidad del sueño	b1343	20	\N	\N
55	Funciones del ciclo del sueño	b1344	20	\N	\N
56	Funciones del sueño, otras especificadas	b1348	20	\N	\N
57	Funciones del sueño, no especificadas	b1349	20	\N	\N
58	Funciones mentales globales, otras especificadas y no especificadas	b139	20	\N	\N
59	Funciones de la atención	b140	20	\N	\N
60	Mantenimiento de la atención	b1400	20	\N	\N
61	Cambios en la atención	b1401	20	\N	\N
62	División de la atención	b1402	20	\N	\N
63	Compartir la atención	b1403	20	\N	\N
64	Funciones de la atención, otras especificadas	b1408	20	\N	\N
65	Funciones de la atención, no especificadas	b1409	20	\N	\N
66	Funciones de la memoria	b144	20	\N	\N
67	Memoria a corto plazo	b1440	20	\N	\N
68	Memoria a largo plazo	b1441	20	\N	\N
69	Recuperación y procesamiento de la información de la memoria	b1442	20	\N	\N
70	Funciones de la memoria, otras especificadas	b1448	20	\N	\N
71	Funciones de la memoria, no especificadas	b1449	20	\N	\N
72	Funciones psicomotoras	b147	20	\N	\N
73	Control psicomotor	b1470	20	\N	\N
74	Cualidad de las funciones psicomotoras	b1471	20	\N	\N
75	Organización de las funciones psicomotoras	b1472	20	\N	\N
76	Dominancia manual	b1473	20	\N	\N
77	Dominancia lateral	b1474	20	\N	\N
78	Funciones psicomotoras, otras especificadas	b1478	20	\N	\N
79	Funciones psicomotoras, no especificadas	b1479	20	\N	\N
80	Funciones emocionales	b152	20	\N	\N
81	Adecuación de la emoción	b1520	20	\N	\N
82	Regulación de la emoción	b1521	20	\N	\N
83	Rango de la emoción	b1522	20	\N	\N
84	Funciones emocionales, otras especificadas	b1528	20	\N	\N
85	Funciones emocionales, no especificadas	b1529	20	\N	\N
86	Funciones de la percepción	b156	20	\N	\N
87	Percepción auditiva	b1560	20	\N	\N
88	Percepción visual	b1561	20	\N	\N
89	Percepción olfativa	b1562	20	\N	\N
90	Percepción gustativa	b1563	20	\N	\N
91	Percepción táctil	b1564	20	\N	\N
92	Percepción visoespacial	b1565	20	\N	\N
93	Funciones de la percepción, otras especificadas	b1568	20	\N	\N
94	Funciones de la percepción, no especificadas	b1569	20	\N	\N
95	Funciones del pensamiento	b160	20	\N	\N
96	Flujo del pensamiento	b1600	20	\N	\N
97	Forma del pensamiento	b1601	20	\N	\N
98	Contenido del pensamiento	b1602	20	\N	\N
99	Control del pensamiento	b1603	20	\N	\N
100	Funciones del pensamiento, otras especificadas	b1608	20	\N	\N
101	Funciones del pensamiento, no especificadas	b1609	20	\N	\N
102	Funciones cognitivas básicas	b163	20	\N	\N
103	Funciones cognitivas superiores	b164	20	\N	\N
104	Abstracción	b1640	20	\N	\N
105	Organización y planificación	b1641	20	\N	\N
106	Manejo del tiempo	b1642	20	\N	\N
107	Flexibilidad cognitiva	b1643	20	\N	\N
108	Instrospección "Insight"	b1644	20	\N	\N
109	Juicio	b1645	20	\N	\N
110	Resolución de problemas	b1646	20	\N	\N
111	Funciones cognitivas superiores, otras especificadas	b1648	20	\N	\N
112	Funciones cognitivas superiores, no especificadas	b1649	20	\N	\N
113	Funciones mentales del lenguaje	b167	20	\N	\N
114	Recepción del lenguaje	b1670	20	\N	\N
115	Recepción del lenguaje oral	b16700	20	\N	\N
116	Recepción del lenguaje escrito	b16701	20	\N	\N
117	Recepción del lenguaje de signos	b16702	20	\N	\N
118	Recepción del lenguaje gestual	b16703	20	\N	\N
119	Recepción del lenguaje, otras especificadas	b16708	20	\N	\N
120	Recepción del lenguaje, no especificas	b16709	20	\N	\N
121	Expresión del lenguaje	b1671	20	\N	\N
122	Expresión del lenguaje oral	b16710	20	\N	\N
123	Expresión del lenguaje escrito	b16711	20	\N	\N
124	Expresión de lenguaje de signos	b16712	20	\N	\N
125	Espresión del lenguaje gestual	b16713	20	\N	\N
126	Expresión de lenguaje, otras especificadas	b16718	20	\N	\N
127	Expresión de lenguaje, no especificadas	b16719	20	\N	\N
128	Funciones integradoras del lenguaje	b1672	20	\N	\N
129	Funciones mentales del lenguaje, otras especificadas	b1678	20	\N	\N
130	Funciones mentales del lenguaje, no especificadas	b1679	20	\N	\N
131	Funciones relacionadas con el cálculo	b172	20	\N	\N
132	Cálculo simple	b1720	20	\N	\N
133	Cálculo complejo	b1721	20	\N	\N
134	Funciones relacionadas con el cálculo, otras especificadas	b1728	20	\N	\N
135	Funciones relacionadas con el cálculo, no especificadas	b1729	20	\N	\N
136	Funciones mentales relacionadas con el encadenamiento de movimientos complejos	b176	20	\N	\N
137	Experiencias relacionadas con uno mismo y con el tiempo	b180	20	\N	\N
138	Experiencias de uno mismo	b1800	20	\N	\N
139	Imagen corporal	b1801	20	\N	\N
140	Experiencia del tiempo	b1802	20	\N	\N
141	Experiencias relacionadas con uno mismo y con el tiempo, otras especificadas	b1808	20	\N	\N
142	Experiencias relacionadas con uno mismo y con el tiempo, no especificadas	b1809	20	\N	\N
143	Funciones mentales específicas, otras especificadas y no especificadas	b189	20	\N	\N
144	Funciones mentales, otras especificadas	b198	20	\N	\N
145	Funciones mentales, no especificadas	b199	20	\N	\N
146	Funciones visuales	b210	22	\N	\N
147	Funciones de la agudeza  visual	b2100	22	\N	\N
148	Agudeza binocular a larga distancia	b21000	22	\N	\N
149	Agudeza monocular a larga distancia	b21001	22	\N	\N
150	Agudeza binocular a corta distancia	b21002	22	\N	\N
151	Agudeza monocular a corta distancia	b21003	22	\N	\N
152	Funciones de la agudeza visual, otras especificadas	b21008	22	\N	\N
153	Funciones de la agudeza visual, no  especificadas	b21009	22	\N	\N
154	Funciones del campo visual	b2101	22	\N	\N
155	Calidad de la visión	b2102	22	\N	\N
156	Sensibilidad a la luz	b21020	22	\N	\N
157	Visión en color	b21021	22	\N	\N
158	Sensibilidad al contraste	b21022	22	\N	\N
159	Calidad de la imagen visual	b21023	22	\N	\N
160	Calidad de la visión, otra especificada	b21028	22	\N	\N
161	Calidad de la visión, no  especificada	b21029	22	\N	\N
162	Funciones visuales, otras especificadas	b2108	22	\N	\N
163	Funciones visuales, no  especificadas	b2109	22	\N	\N
164	Funciones de las estructuras adyacentes al ojo	b215	22	\N	\N
165	Funciones de los músculos internos del ojo	b2150	22	\N	\N
166	Funciones del párpado	b2151	22	\N	\N
167	Funciones de los músculos externos del ojo	b2152	22	\N	\N
168	Funciones de las glándulas lacrimales	b2153	22	\N	\N
169	Funciones de las estructuras adyacentes al ojo, otras especificadas	b2158	22	\N	\N
170	Funciones de las estructuras adyacentes al ojo, no especificadas	b2159	22	\N	\N
171	Sensaciones asociadas con el ojo y estructuras adyacentes	b220	22	\N	\N
172	Vista y funciones relacionadas, otras especificadas y no especificadas	b229	22	\N	\N
173	Funciones auditivas	b230	22	\N	\N
174	Detección de sonidos	b2300	22	\N	\N
175	Discriminación de sonidos	b2301	22	\N	\N
176	Localización de la fuente de sonido	b2302	22	\N	\N
177	Lateralización del sonido	b2303	22	\N	\N
178	Discriminación del habla	b2304	22	\N	\N
179	Funciones auditivas, otras especificadas	b2308	22	\N	\N
180	Funciones auditivas, no especificadas	b2309	22	\N	\N
181	Función vestibular	b235	22	\N	\N
182	Función vestibular relacionadas con la posición	b2350	22	\N	\N
183	Función vestibular relacionada con el equilibrio	b2351	22	\N	\N
184	Función vestibular relacionada con el movimiento	b2352	22	\N	\N
185	Función vestibular, otras especificadas	b2358	22	\N	\N
186	Función vestibular, no especificadas	b2359	22	\N	\N
187	Sensaciones asociadas con la audición  y con la función vestibular	b240	22	\N	\N
188	Zumbido en los oídos o tinnitus	b2400	22	\N	\N
189	Mareo	b2401	22	\N	\N
190	Sensación de caerse	b2402	22	\N	\N
191	Náusea asociada con el mareo y el vértigo	b2403	22	\N	\N
192	Irritación en el oído	b2404	22	\N	\N
193	Presión auditiva	b2405	22	\N	\N
194	Sensaciones relacionadas con la audición y con la función vestibular, otras especificadas	b2408	22	\N	\N
195	Sensaciones relacionadas con la audición y con la función vestibular, no especificadas	b2409	22	\N	\N
196	Funciones auditivas y vestibulares, otras especificadas y no especificadas	b249	22	\N	\N
197	Función gustativa	b250	22	\N	\N
198	Función olfativa	b255	22	\N	\N
199	Función propioceptiva	b260	22	\N	\N
200	Funciones táctiles	b265	22	\N	\N
201	Funciones relacionadas con la temperatura y otros estímulos	b270	22	\N	\N
762	Atrapar	d4455	24	\N	\N
202	Sensibilidad a la temperatura	b2700	22	\N	\N
203	Sensibilidad a la vibración	b2701	22	\N	\N
204	Sensibilidad a la presión	b2702	22	\N	\N
205	Sensibilidad a estímulos nocivos	b2703	22	\N	\N
206	Funciones sensoriales relacionadas con la temperatura y otros estímulos, otras especificadas	b2708	22	\N	\N
207	Funciones sensoriales relacionadas con la temperatura y otros estímulos, no especificadas	b2709	22	\N	\N
208	Funciones sensoriales adicionales, otras especificadas y no especificadas	b279	22	\N	\N
209	Sensación de dolor	b280	22	\N	\N
210	Dolor generalizado	b2800	22	\N	\N
211	Dolor en una parte del cuerpo	b2801	22	\N	\N
212	Dolor en la cabeza y el cuello	b28010	22	\N	\N
213	Dolor en el pecho	b28011	22	\N	\N
214	Dolor en el estómago o en el abdomen	b28012	22	\N	\N
215	Dolor en la espalda	b28013	22	\N	\N
216	Dolor en una extremidad superior	b28014	22	\N	\N
217	Dolor en una extremidad inferior	b28015	22	\N	\N
218	Dolor en las articulaciones	b28016	22	\N	\N
219	Dolor en una parte del cuerpo, otra especificada	b28018	22	\N	\N
220	Dolor en una parte del cuerpo, no especificada	b28019	22	\N	\N
221	Dolor en múltiples partes del cuerpo	b2802	22	\N	\N
222	Dolor irradiado en un dermatoma	b2803	22	\N	\N
223	Dolor irradiado en un segmento o región	b2804	22	\N	\N
224	Sensación de dolor, otra especificada y no especificada	b289	22	\N	\N
225	Funciones sensoriales y dolor, otras especificadas	b298	22	\N	\N
226	Funciones sensoriales y dolor, no especificadas	b299	22	\N	\N
227	Funciones de la voz	b310	16	\N	\N
228	Producción de la voz	b3100	16	\N	\N
229	Calidad de la voz	b3101	16	\N	\N
230	Funciones de la voz, otras especificadas	b3108	16	\N	\N
231	Funciones de la voz, no especificadas	b3109	16	\N	\N
232	Funciones de articulación	b320	16	\N	\N
233	Funciones relacionadas con la fluidez y el ritmo del habla	b330	16	\N	\N
234	Fluidez del habla	b3300	16	\N	\N
235	Ritmo del habla	b3301	16	\N	\N
236	Velocidad del habla	b3302	16	\N	\N
237	Melodía del habla	b3303	16	\N	\N
238	Funciones relacionadas con la fluidez y el ritmo del habla, otras especificadas	b3308	16	\N	\N
239	Funciones relacionadas con la fluidez y el ritmo del habla, no especificadas	b3309	16	\N	\N
240	Funciones alternativas de vocalización	b340	16	\N	\N
241	Producción de notas	b3400	16	\N	\N
242	Producción de un rango de sonidos	b3401	16	\N	\N
243	Funciones alternativas de vocalización, otras especificadas	b3408	16	\N	\N
244	Funciones alternativas de vocalización, no especificadas	b3409	16	\N	\N
245	Funciones de la voz y el habla, otras especificadas	b398	16	\N	\N
246	Funciones de la voz y el habla, no especificadas	b399	16	\N	\N
247	Funciones del corazón	b410	17	\N	\N
248	Frecuencia cardiaca	b4100	17	\N	\N
249	Ritmo cardiaco	b4101	17	\N	\N
250	Fuerza de contracción de los músculos ventriculares	b4102	17	\N	\N
251	Volumen de sangre que llega al corazón	b4103	17	\N	\N
252	Funciones del corazón, otras especificadas	b4108	17	\N	\N
253	Funciones del corazón, no especificadas	b4109	17	\N	\N
254	Funciones de los vasos sanguíneos	b415	17	\N	\N
255	Funciones de las arterias	b4150	17	\N	\N
256	Funciones de los capilares	b4151	17	\N	\N
257	Funciones de las venas	b4152	17	\N	\N
258	Funciones de los vasos sanguíneos, otras especificadas	b4158	17	\N	\N
259	Funciones de los vasos sanguíneos, no  especificadas	b4159	17	\N	\N
260	Funciones de la presión arterial	b420	17	\N	\N
261	Aumento de la presión arterial	b4200	17	\N	\N
262	Descenso de la presión arterial	b4201	17	\N	\N
263	Mantenimiento de la presión arterial	b4202	17	\N	\N
264	Funciones de la presión arterial, otras especificadas	b4208	17	\N	\N
265	Funciones de la presión arterial, no  especificadas	b4209	17	\N	\N
266	Funciones del sistema cardiovascular, otras especificadas y no especificadas	b429	17	\N	\N
267	Funciones del sistema hematológico	b430	17	\N	\N
268	Producción de sangre	b4300	17	\N	\N
269	Funciones sanguíneas relacionadas con el transporte de oxígeno	b4301	17	\N	\N
270	Funciones sanguíneas relacionadas con el transporte metabólico	b4302	17	\N	\N
271	Funciones relacionadas con la coagulación	b4303	17	\N	\N
272	Funciones del sistema hematológico, otras especificadas	b4308	17	\N	\N
273	Funciones del sistema hematológico, no especificadas	b4309	17	\N	\N
274	Funciones del sistena inmunológico	b435	17	\N	\N
275	Respuesta inmune	b4350	17	\N	\N
276	Respuesta inmune específica	b43500	17	\N	\N
277	Respuesta inmune no específica	b43501	17	\N	\N
278	Respuesta inmune, otra especificada	b43508	17	\N	\N
279	Respuesta inmune, no especificada	b43509	17	\N	\N
280	Reacciones de hipersensibilidad	b4351	17	\N	\N
281	Funciones de los vasos linfáticos	b4352	17	\N	\N
282	Funciones de los nódulos linfáticos	b4353	17	\N	\N
283	Funciones del sistema inmunológico, otras especificadas	b4358	17	\N	\N
284	Funciones del sistema inmunológico, no especificadas	b4359	17	\N	\N
285	Funciones de los sistemas hematológico e inmunológico, otras especificadas y no especificadas	b439	17	\N	\N
286	Funciones respiratorias	b440	17	\N	\N
287	Frecuencia respiratoria	b4400	17	\N	\N
288	Ritmo respiratorio	b4401	17	\N	\N
289	Profundidad de la respiración	b4402	17	\N	\N
290	Funciones respiratorias, otras especificadas	b4408	17	\N	\N
291	Funciones respiratorias, no especificadas	b4409	17	\N	\N
292	Funciones de los músculos respiratorios	b445	17	\N	\N
293	Funciones de los músculos torácicos respiratorios	b4450	17	\N	\N
294	Funciones del diafragma	b4451	17	\N	\N
295	Funciones de los músculos respiratorios accesorios	b4452	17	\N	\N
296	Funciones de los músculos respiratorios, otras especificadas	b4458	17	\N	\N
297	Funciones de los músculos respiratorios, no  especificadas	b4459	17	\N	\N
298	Funciones del sistema respiratorio, otras especificadas y no especificadas	b449	17	\N	\N
299	Funciones respiratorias adicionales	b450	17	\N	\N
300	Producción de moco en vías aereas	b4500	17	\N	\N
301	Transporte de moco de vías areas	b4501	17	\N	\N
302	Funciones respiratorias adicionales, otras especificadas	b4508	17	\N	\N
303	Funciones respiratorias adicionales, no especificadas	b4509	17	\N	\N
304	Funciones relacionadas con la tolerancia al ejercicio	b455	17	\N	\N
305	Resistencia física general	b4550	17	\N	\N
306	Capacidad aeróbica	b4551	17	\N	\N
307	Fatigabilidad	b4552	17	\N	\N
308	Funciones relacionadas con la tolerancia al ejercicio, otras especificadas	b4558	17	\N	\N
309	Funciones relacionadas con la tolerancia al ejercicio, no  especificadas	b4559	17	\N	\N
310	Sensaciones asociadas con las funciones cardiovasculares y respiratorias	b460	17	\N	\N
311	Funciones adicionales y sensaciones de los sistemas cardiovascular y respiratorio, otras especificadas y no especificadas	b469	17	\N	\N
312	Funciones de los sistemas cardiovascular, hematológico e inmunológico y respiratorio, otras especificadas	b498	17	\N	\N
313	Funciones de los sistemas cardiovascular, hematológico e inmunológico y respiratorio, no especificadas	b499	17	\N	\N
314	Funciones relacionadas con la ingestión	b510	18	\N	\N
315	Succión	b5100	18	\N	\N
316	Morder	b5101	18	\N	\N
317	Masticación	b5102	18	\N	\N
318	Manipulación de la comida en la boca	b5103	18	\N	\N
319	Salivación	b5104	18	\N	\N
320	Tragar	b5105	18	\N	\N
321	Deglución oral	b51050	18	\N	\N
322	Deglución faríngea	b51051	18	\N	\N
323	Deglución esofágica	b51052	18	\N	\N
324	Tragar, otras especificadas	b51058	18	\N	\N
325	Tragar, no especificadas	b51059	18	\N	\N
326	Vómito	b5106	18	\N	\N
327	Regurgitación	b51060	18	\N	\N
328	Rumiación	b5107	18	\N	\N
329	Funciones relacionadas con la ingestión, otras especificadas	b5108	18	\N	\N
330	Funciones relacionadas con la ingestión, no  especificadas	b5109	18	\N	\N
331	Funciones relacionadas con la digestión	b515	18	\N	\N
332	Transporte de comida a través del estómago y los intestinos	b5150	18	\N	\N
333	Degradación de la comida	b5151	18	\N	\N
334	Absorción de nutrientes	b5152	18	\N	\N
335	Tolerancia a la comida	b5153	18	\N	\N
336	Funciones relacionadas con la digestión, otras especificadas	b5158	18	\N	\N
337	Funciones relacionadas con la digestión, no especificadas	b5159	18	\N	\N
338	Funciones relacionadas con la asimilación	b520	18	\N	\N
339	Funciones relacionadas con la defecación	b525	18	\N	\N
340	Eliminación de heces	b5250	18	\N	\N
341	Consistencia fecal	b5251	18	\N	\N
342	Frecuencia de la defecación	b5252	18	\N	\N
343	Continencia fecal	b5253	18	\N	\N
344	Flatulencia	b5254	18	\N	\N
345	Funciones relacionadas con la defecación, otras especificadas	b5258	18	\N	\N
346	Funciones relacionadas con la defecación, no especificadas	b5259	18	\N	\N
347	Funciones relacionadas con el mantenimiento del peso	b530	18	\N	\N
348	Fuerza de los músculos del tronco	b5305	18	\N	\N
349	Sensaciones asociadas con el sistema digestivo	b535	18	\N	\N
350	Sensación de náusea	b5350	18	\N	\N
351	Sensación de estar hinchado	b5351	18	\N	\N
352	Sensación de calambres abdominales	b5352	18	\N	\N
353	Sensaciones asociadas con el sistema digestivo, otras especificadas	b5358	18	\N	\N
354	Sensaciones asociadas con el sistema digestivo, no especificadas	b5359	18	\N	\N
355	Funciones relacionadas con el sistema digestivo, otras especificadas y no especificadas	b539	18	\N	\N
356	Funciones metabólicas generales	b540	18	\N	\N
357	Tasa de metabolismo basal	b5400	18	\N	\N
358	Metabolismo de los carbohidratos	b5401	18	\N	\N
359	Metabolismo de las proteínas	b5402	18	\N	\N
360	Metabolismo de las grasas	b5403	18	\N	\N
361	Funciones metabólicas generales, otras especificadas	b5408	18	\N	\N
362	Funciones metabólicas generales, no especificadas	b5409	18	\N	\N
363	Funciones relacionadas con el balance hídrico, mineral y electrolítico	b545	18	\N	\N
364	Balance hídrico	b5450	18	\N	\N
365	Retención de agua	b54500	18	\N	\N
366	Mantenimiento del balance hídrico	b54501	18	\N	\N
367	Funciones relacionadas con el balance hídrico, otras especificadas	b54508	18	\N	\N
368	Funciones relacionadas con el balance hídrico, no especificadas	b54509	18	\N	\N
369	Balance mineral	b5451	18	\N	\N
370	Balance electrolítico	b5452	18	\N	\N
371	Funciones relacionadas con el balance hídrico, mineral y electrolítico, otras especificadas	b5458	18	\N	\N
372	Funciones relacionadas con el balance hídrico, mineral y electrolítico, no especificadas	b5459	18	\N	\N
373	Funciones termorreguladoras	b550	18	\N	\N
374	Temperatura corporal	b5500	18	\N	\N
375	Mantenimiento de la temperatura corporal	b5501	18	\N	\N
376	Funciones termorreguladoras, otras especificadas	b5508	18	\N	\N
377	Funciones termorreguladoras, no especificadas	b5509	18	\N	\N
378	Funciones de las glándulas endocrinas	b555	18	\N	\N
379	Funciones relacionadas con la pubertad	b5550	18	\N	\N
380	Desarrollo del vello corporal y púbico	b55500	18	\N	\N
381	Desarrollo de las mamas y los pezones	b55501	18	\N	\N
382	Desarrollo del pene, los testiculos y el escroto	b55502	18	\N	\N
383	Funciones puberales, otras especificadas	b55508	18	\N	\N
384	Funciones puberales, no especificadas	b55509	18	\N	\N
385	Funciones relacionadas con el crecimiento	b560	18	\N	\N
386	Funciones relacionadas con el metabolismo y el sistema endocrino, otras especificadas y no especificadas	b569	18	\N	\N
387	Funciones de los sistema digestivo,  metabólico y el sistema endocrino, otras especificadas	b598	18	\N	\N
475	Resistencia de todos los músculos del cuerpo	b7402	21	\N	\N
388	Funciones de los sistemas digestivo, metabólico y endocrino, no especificadas	b599	18	\N	\N
389	Funciones relacionadas con la excreción urinaria	b610	19	\N	\N
390	Filtración de orina	b6100	19	\N	\N
391	Recogida de orina	b6101	19	\N	\N
392	Funciones relacionadas con la excreción urinaria, otras especificadas	b6108	19	\N	\N
393	Funciones relacionadas con la excreción urinaria, no especificadas	b6109	19	\N	\N
394	Funciones urinarias	b620	19	\N	\N
395	Orinar	b6200	19	\N	\N
396	Frecuencia de micción	b6201	19	\N	\N
397	Continencia urinaria	b6202	19	\N	\N
398	Funciones urinarias, otras especificadas	b6208	19	\N	\N
399	Funciones urinarias, no  especificadas	b6209	19	\N	\N
400	Sensaciones  asociadas con las funciones urinarias	b630	19	\N	\N
401	Funciones urinarias, otras especificadas y no especificadas	b639	19	\N	\N
402	Funciones sexuales	b640	19	\N	\N
403	Funciones de la fase de excitación sexual	b6400	19	\N	\N
404	Funciones de la fase de preparación  sexual	b6401	19	\N	\N
405	Funciones de la fase orgásmica	b6402	19	\N	\N
406	Funciones de la fase de resolución sexual	b6403	19	\N	\N
407	Funciones sexuales, otras especificadas	b6408	19	\N	\N
408	Funciones sexuales, no especificadas	b6409	19	\N	\N
409	Funciones relacionadas con la menstruación	b650	19	\N	\N
410	Regularidad del ciclo menstrual	b6500	19	\N	\N
411	Intervalo entre menstruaciones	b6501	19	\N	\N
412	Cantidad de sangrado menstrual	b6502	19	\N	\N
413	Inicio de la menstruación	b6503	19	\N	\N
414	Funciones relacionadas con la menstruación, otras especificadas	b6508	19	\N	\N
415	Funciones relacionadas con la menstruación, no especificadas	b6509	19	\N	\N
416	Funciones relacionadas con la procreación	b660	19	\N	\N
417	Funciones relacionadas con la fertilidad	b6600	19	\N	\N
418	Funciones relacionadas con el embarazo	b6601	19	\N	\N
419	Funciones relacionadas con el parto	b6602	19	\N	\N
420	Lactancia	b6603	19	\N	\N
421	Funciones relacionadas con la procreación, otras especificadas	b6608	19	\N	\N
422	Funciones relacionadas con la procreación, no especificadas	b6609	19	\N	\N
423	Sensaciones asociadas con las funciones genitales y reproductoras	b670	19	\N	\N
424	Malestar asociado con el acto sexual	b6700	19	\N	\N
425	Malestar asociado con el ciclo menstrual	b6701	19	\N	\N
426	Malestar asociado con la menopausia	b6702	19	\N	\N
427	Funciones genitales	b6703	19	\N	\N
428	Sensaciones relacionadas con las funciones genitales y reproductoras, otras especificadas	b6708	19	\N	\N
429	Sensaciones relacionadas con las funciones genitales y reproductoras, no especificadas	b6709	19	\N	\N
430	Funciones genitales y reproductoras, otras especificadas y no especificadas	b679	19	\N	\N
431	Funciones genitourinarias y reproductoras, otras especificadas	b698	19	\N	\N
432	Funciones genitourinarias y reproductoras, no especificadas	b699	19	\N	\N
433	Funciones relacionadas con la movilidad de las articulaciones	b710	21	\N	\N
434	Movilidad de una sola articulación	b7100	21	\N	\N
435	Movilidad de varias articulaciones	b7101	21	\N	\N
436	Movilidad generalizada de las articulaciones	b7102	21	\N	\N
437	Funciones relacionadas con la movilidad de las articulaciones, otras especificadas	b7108	21	\N	\N
438	Funciones relacionadas con la movilidad de las articulaciones, no especificadas	b7109	21	\N	\N
439	Funciones relacionadas con la estabilidad de las articulaciones	b715	21	\N	\N
440	Estabilidad de una sola articulación	b7150	21	\N	\N
441	Estabilidad de varias articulaciones	b7151	21	\N	\N
442	Estabilidad generalizada de las articulaciones	b7152	21	\N	\N
443	Funciones relacionadas con la estabilidad de las articulaciones, otras especificadas	b7158	21	\N	\N
444	Funciones relacionadas con la estabilidad de las articulaciones, no especificadas	b7159	21	\N	\N
445	Funciones relacionadas con la movilidad de los huesos	b720	21	\N	\N
446	Movilidad de la escápula	b7200	21	\N	\N
447	Movilidad de la pelvis	b7201	21	\N	\N
448	Movilidad de los huesos carpianos	b7202	21	\N	\N
449	Movilidad de los huesos tarsianos	b7203	21	\N	\N
450	Funciones relacionadas con la movilidad de los huesos, otras especificadas	b7208	21	\N	\N
451	Funciones relacionadas con la movilidad de los huesos, no especificadas	b7209	21	\N	\N
452	Funciones de las articulaciones y los huesos, otras especificadas y no especificadas	b729	21	\N	\N
453	Funciones relacionadas con la fuerza muscular	b730	21	\N	\N
454	Fuerza de músculos aislados o de grupos de músculos	b7300	21	\N	\N
455	Fuerza de los músculos de una extremidad	b7301	21	\N	\N
456	Fuerza de los músculos de un lado del cuerpo	b7302	21	\N	\N
457	Fuerza de los músculos de la mitad inferior del cuerpo	b7303	21	\N	\N
458	Fuerza de los músculos de todas las extremidades	b7304	21	\N	\N
459	Fuerza de los músculos de todo el cuerpo	b7306	21	\N	\N
460	Funciones relacionadas con la fuerza muscular, otras especificadas	b7308	21	\N	\N
461	Funciones relacionadas con la fuerza muscular, no especificadas	b7309	21	\N	\N
462	Funciones relacionadas con el tono muscular	b735	21	\N	\N
463	Tono de músculos aislados y grupos de músculos	b7350	21	\N	\N
464	Tono de los músculos de una extremidad	b7351	21	\N	\N
465	Tono de los músculos de un lado del cuerpo	b7352	21	\N	\N
466	Tono de los músculos de la mitad inferior del cuerpo	b7353	21	\N	\N
467	Tono de los músculos de todas las extremidades	b7354	21	\N	\N
468	Tono de los músculos del tronco	b7355	21	\N	\N
469	Tono de todos los músculos del cuerpo	b7356	21	\N	\N
470	Funciones relacionadas con el tono muscular, otras especificadas	b7358	21	\N	\N
471	Funciones relacionadas con el tono muscular, no especificadas	b7359	21	\N	\N
472	Funciones relacionadas con la resistencia muscular	b740	21	\N	\N
473	Resistencia de músculos aislados	b7400	21	\N	\N
474	Resistencia de grupos de músculos	b7401	21	\N	\N
661	Respuesta a la voz humana	d3100	6	\N	\N
476	Funciones relacionadas con la resistencia muscular, otras especificadas	b7408	21	\N	\N
477	Funciones relacionadas con la resistencia muscular, no especificadas	b7409	21	\N	\N
478	Funciones musculares, otras especificadas y no especificadas	b749	21	\N	\N
479	Funciones relacionadas con los reflejos motores	b750	21	\N	\N
480	Reflejo de extensión motora	b7500	21	\N	\N
481	Reflejos generados por estímulos nocivos	b7501	21	\N	\N
482	Reflejos generados por otros estímulos exteroceptivos	b7502	21	\N	\N
483	Funciones relacionadas con los reflejos motores, otras especificadas	b7508	21	\N	\N
484	Funciones relacionadas con los reflejos motores, no especificadas	b7509	21	\N	\N
485	Funciones relacionadas con los reflejos de movimiento involuntario	b755	21	\N	\N
486	Funciones relacionadas con el control de los movimientos voluntarios	b760	21	\N	\N
487	Control de movimientos voluntarios simples	b7600	21	\N	\N
488	Control de movimientos voluntarios complejos	b7601	21	\N	\N
489	Coordinación de movimientos voluntarios	b7602	21	\N	\N
490	Funciones de apoyo del brazo o la pierna	b7603	21	\N	\N
491	Funciones relacionadas con el control de los movimientos voluntarios, otras especificadas	b7608	21	\N	\N
492	Funciones relacionadas con el control de los movimientos voluntarios, no especificadas	b7609	21	\N	\N
493	Funciones relacionadas con los movimientos espontáneos	b761	21	\N	\N
494	Movimientos generales	b7610	21	\N	\N
495	Movimientos espontáneos especificos	b7611	21	\N	\N
496	Funciones relacionadas con los movimientos espontáneos,otras especificadas	b7618	21	\N	\N
497	Funciones relacionadas con los movimientos espontáneos, no especificadas	b7619	21	\N	\N
498	Funciones relacionadas con los movimientos involuntarios	b765	21	\N	\N
499	Contracciones involuntarias de los músculos	b7650	21	\N	\N
500	Temblor	b7651	21	\N	\N
501	Tics y manierismos	b7652	21	\N	\N
502	Estereotipos y perseverancia motora	b7653	21	\N	\N
503	Funciones relacionadas con los movimientos involuntarios, otras especificadas	b7658	21	\N	\N
504	Funciones relacionadas con los movimientos involuntarios, no especificadas	b7659	21	\N	\N
505	Funciones relacionadas con el patrón de la marcha	b770	21	\N	\N
506	Sensaciones relacionadas con los músculos y las funciones del movimiento	b780	21	\N	\N
507	Sensación de rigidez muscular	b7800	21	\N	\N
508	Sensación de espasmo muscular	b7801	21	\N	\N
509	Sensaciones relacionadas con los músculos y las funciones del movimiento, otras especificadas	b7808	21	\N	\N
510	Sensaciones relacionadas con los músculos y las funciones del movimiento, no especificadas	b7809	21	\N	\N
511	Funciones relacionadas con el movimiento, otras especificadas y no especificadas	b789	21	\N	\N
512	Funciones neuromusculoesqueléticas y relacionadas con el movimiento, otras especificadas	b798	21	\N	\N
513	Funciones neuromusculoesqueléticas y relacionadas con el movimiento, no especificadas	b799	21	\N	\N
514	Funciones protectoras de la piel	b810	15	\N	\N
515	Funciones reparadoras de la piel	b820	15	\N	\N
516	Otras funciones de la piel	b830	15	\N	\N
517	Sensaciones relacionadas con la piel	b840	15	\N	\N
518	Funciones de la piel, otras especificadas y no especificadas	b849	15	\N	\N
519	Funciones del pelo	b850	15	\N	\N
520	Funciones de las uñas	b860	15	\N	\N
521	Funciones del pelo y las uñas, otras especificadas y no especificadas	b869	15	\N	\N
522	Funciones de la piel y estructuras relacionadas, otras especificadas	b898	15	\N	\N
523	Funciones de la piel y estructuras relacionadas, no especificadas	b899	15	\N	\N
524	Mirar	d110	3	\N	\N
525	Escuchar	d115	3	\N	\N
526	Otras experiencias sensoriales intencionadas	d120	3	\N	\N
527	Chupar	d1200	3	\N	\N
528	Tocar	d1201	3	\N	\N
529	Oler	d1202	3	\N	\N
530	Saborear	d1203	3	\N	\N
531	Experiencias sensoriales intencionadas, otras especificadas y no especificadas	d129	3	\N	\N
532	Copiar	d130	3	\N	\N
533	Aprender mediante acciones con objetos	d131	3	\N	\N
534	Aprender mediante acciones simples con objetos sencillos	d1310	3	\N	\N
535	Aprender mediante acciones que relacionan dos o más objetos	d1311	3	\N	\N
536	Aprender mediante acciones con dos o más objetos teniendo en cuenta sus características especificas	d1312	3	\N	\N
537	Aprendizaje mediante el juego simbolico	d1313	3	\N	\N
538	Aprendizaje mediante juegos simulados	d1314	3	\N	\N
539	Aprendizaje mediante acciones con objetos, otro especificado	d1318	3	\N	\N
540	Aprendizaje mediante acciones con objetos, no especificado	d1319	3	\N	\N
541	Adquirir información	d132	3	\N	\N
542	Adquirir el lenguaje	d133	3	\N	\N
543	Adquirir palabras simples o significados simbolicos	d1330	3	\N	\N
544	Combinar palabras para crear frases	d1331	3	\N	\N
545	Adquirir la sintaxis	d1332	3	\N	\N
546	Adquirir el lenguaje, otro especificado	d1338	3	\N	\N
547	Adquirir el lenguaje, no especificado	d1339	3	\N	\N
548	Adquirir el lenguaje adicional	d134	3	\N	\N
549	Repetir	d135	3	\N	\N
550	Adquirir conceptos	d137	3	\N	\N
551	Adquirir conceptos básicos	d1370	3	\N	\N
552	Adquirir conceptos complejos	d1371	3	\N	\N
553	Adquisición de conceptos, otros especificados	d1378	3	\N	\N
554	Adquisición de conceptos, no especificados	d1379	3	\N	\N
555	Aprender a leer	d140	3	\N	\N
556	Adquisición de habilidades para reconocer símbolos incluidas figuras, iconos, caracteres y letras y palabras	d1400	3	\N	\N
557	Adquisición de habilidades para pronunciar palabras escritas	d1401	3	\N	\N
558	Adquisisción de habilidades para entender palabras y frases escritas	d1402	3	\N	\N
559	Aprender a leer, otro especificado	d1408	3	\N	\N
560	Aprender a leer, no especificado	d1409	3	\N	\N
561	Aprender a escribir	d145	3	\N	\N
562	Adquirir habilidades para utilizar utensilios de escritura	d1450	3	\N	\N
563	Adquirir habilidades para escribir símbolos, caracteres y letras	d1451	3	\N	\N
564	Adquirir habilidades para escribir palabras y frases	d1452	3	\N	\N
565	Aprender a escribir, otro especificado	d1458	3	\N	\N
566	Aprender a escribir, otro no especificado	d1459	3	\N	\N
567	Aprender a calcular	d150	3	\N	\N
568	Adquirir habilidades para utilizar reconocer números, y signos y símbolos aritméticos	d1500	3	\N	\N
569	Adquirir de habilidades numéricas tales como contar u ordenar	d1501	3	\N	\N
570	Adquirir habilidades para la realización de operaciones básicas	d1502	3	\N	\N
571	Aprender a calcular, otro especificado	d1508	3	\N	\N
572	Aprender a calcular, otro no especificado	d1509	3	\N	\N
573	Adquisición de habilidades	d155	3	\N	\N
574	Adquisición de habilidades básicas	d1550	3	\N	\N
575	Adquisición de habilidades complejas	d1551	3	\N	\N
576	Adquisición de habilidades, otras especificadas	d1558	3	\N	\N
577	Adquisición de habilidades, no especificadas	d1559	3	\N	\N
578	Aprendizaje básico, otro especificado y no especificado	d159	3	\N	\N
579	Centrar la atención	d160	3	\N	\N
580	Centrar la atención hacia el tacto, la cara o la voz humana	d1600	3	\N	\N
581	Centrar la atención hacia cambios en el entorno	d1601	3	\N	\N
582	Centrar la atención, otra especificada	d1608	3	\N	\N
583	Centrar la atención, no especificada	d1609	3	\N	\N
584	Dirigir la atención	d161	3	\N	\N
585	Pensar	d163	3	\N	\N
586	Imitar	d1630	3	\N	\N
587	Especular	d1631	3	\N	\N
588	Hipotetizar	d1632	3	\N	\N
589	Pensar, otro especificado	d1638	3	\N	\N
590	Pensar, otro no especificado	d1639	3	\N	\N
591	Leer	d166	3	\N	\N
592	Utilizar habilidades generales y estrategias propias del proceso de lectura	d1660	3	\N	\N
593	Comprensión del lenguaje escrito	d1661	3	\N	\N
594	Leer, otro especificado	d1668	3	\N	\N
595	Leer, otro no especificado	d1669	3	\N	\N
596	Escribir	d170	3	\N	\N
597	Utilizar habilidades generales y estrategias propias del proceso de escritura	d1700	3	\N	\N
598	Utilizar convenciones gramaticales en las composiciones escritas	d1701	3	\N	\N
599	Utilizar habilidades generales y estrategias para completar composiciones	d1702	3	\N	\N
600	Escribir, otro especificado	d1708	3	\N	\N
601	Escribir, otro no especificado	d1709	3	\N	\N
602	Calcular	d172	3	\N	\N
603	Utilizar habilidades y estrategias simples propias del proceso del cálculo	d1720	3	\N	\N
604	Utilizar habilidades y estrategias complejas propias del proceso del cálculo	d1721	3	\N	\N
605	Calcular, otro especificado	d1728	3	\N	\N
606	Calcular, otro no especificado	d1729	3	\N	\N
607	Resolver problemas	d175	3	\N	\N
608	Resolver problemas simples	d1750	3	\N	\N
609	Resolver problemas complejos	d1751	3	\N	\N
610	Resolver problemas, otro especificado	d1758	3	\N	\N
611	Resolver problemas, no especificado	d1759	3	\N	\N
612	Tomar decisiones	d177	3	\N	\N
613	Aplicación del conocimiento, otra especificada y no especificada	d179	3	\N	\N
614	Aprendizaje y aplicación del conocimiento, otro especificado	d198	3	\N	\N
615	Aprendizaje y aplicación del conocimiento, no especificado	d199	3	\N	\N
616	Llevar a cabo una única tarea	d210	28	\N	\N
617	Llevar a cabo una tarea sencilla	d2100	28	\N	\N
618	Llevar a cabo una tarea compleja	d2101	28	\N	\N
619	Llevar a cabo una única tarea independientemente	d2102	28	\N	\N
620	Llevar a cabo una única tarea en grupo	d2103	28	\N	\N
621	Completar una tarea sencilla	d2104	28	\N	\N
622	Completar una tarea compleja	d2105	28	\N	\N
623	Llevar a cabo una única tarea, otra especificada	d2108	28	\N	\N
624	Llevar a cabo una única tarea, no especificada	d2109	28	\N	\N
625	Llevar a cabo múltiples tareas	d220	28	\N	\N
626	Realizar múltiples tareas	d2200	28	\N	\N
627	Completar múltiples tareas	d2201	28	\N	\N
628	Llevar a cabo múltiples tareas independientemente	d2202	28	\N	\N
629	Llevar a cabo múltiples tareas en un grupo	d2203	28	\N	\N
630	Completar multiples tareas independientemente	d2204	28	\N	\N
631	Completar múltiples tareas en grupo	d2205	28	\N	\N
632	Llevar a cabo múltiples tareas, otro especificado	d2208	28	\N	\N
633	Llevar a cabo múltiples tareas,  otro no especificado	d2209	28	\N	\N
634	Llevar a cabo rutinas diarias	d230	28	\N	\N
635	Seguir rutinas	d2300	28	\N	\N
636	Dirigir la rutina diaria	d2301	28	\N	\N
637	Completar la rutina diaria	d2302	28	\N	\N
638	Dirigir el propio nivel de actividad	d2303	28	\N	\N
639	Dirigir cambios en la rutina diaria	d2304	28	\N	\N
640	Dirigir el propio tiempo	d2305	28	\N	\N
641	Adaptarse a las demandas horarias	d2306	28	\N	\N
642	Llevar a cabo rutinas diarias, otro especificado	d2308	28	\N	\N
643	Llevar a cabo rutinas diarias, otro no especificado	d2309	28	\N	\N
644	Manejo del estrés y otras demandas psicológicas	d240	28	\N	\N
645	Manejo de responsabilidades	d2400	28	\N	\N
646	Manejo del estrés	d2401	28	\N	\N
647	Manejo de crisis	d2402	28	\N	\N
648	Manejo del estrés y otras demandas psicológicas, otra especificada	d2408	28	\N	\N
649	Manejo del estrés y otras demandas psicológicas, no especificada	d2409	28	\N	\N
650	Manejo del comportamiento propio	d250	28	\N	\N
651	Aceptar novedades	d2500	28	\N	\N
652	Responder a las demandas	d2501	28	\N	\N
653	Abordabilidad hacia personas o situaciones	d2502	28	\N	\N
654	Actuar de modo previsible	d2503	28	\N	\N
655	Adaptar el nivel de actividad	d2504	28	\N	\N
656	Manejo del comportamiento propio, otra especificada	d2508	28	\N	\N
657	Manejo del comportamiento propio, no especificada	d2809	28	\N	\N
658	Tareas y demandas generales, otras especificadas	d298	28	\N	\N
659	Tareas y demandas generales, no especificadas	d299	28	\N	\N
660	Comunicación-recepción de mensajes hablados	d310	6	\N	\N
662	Comprensión de mensajes hablados simples	d3101	6	\N	\N
663	Comprensión de mensajes hablados complejos	d3102	6	\N	\N
664	Comunicación-recepción de mensajes hablados, otro especificada	d3108	6	\N	\N
665	Comunicación-recepción de mensajes hablados, no especificada	d3109	6	\N	\N
666	Comunicación-recepción de mensajes no verbales	d315	6	\N	\N
667	Comunicación-recepción de gestos corporales	d3150	6	\N	\N
668	Comunicación-recepción de señales y símbolos	d3151	6	\N	\N
669	Comunicación-recepción de dibujos y fotografías	d3152	6	\N	\N
670	Comunicación-recepción de mensajes no verbales, otro especificado	d3158	6	\N	\N
671	Comunicación-recepción de mensajes no verbales, no especificado	d3159	6	\N	\N
672	Comunicación-recepción de mensajes en lenguaje de signos convencional	d320	6	\N	\N
673	Comunicación-recepción de mensajes escritos	d325	6	\N	\N
674	Comunicación-recepción, otra especificada y no especificada	d329	6	\N	\N
675	Hablar	d330	6	\N	\N
676	Pre-lenguaje	d331	6	\N	\N
677	Cantar	d332	6	\N	\N
678	Producción de mensajes no verbales	d335	6	\N	\N
679	Producción de lenguaje corporal	d3350	6	\N	\N
680	Producción de señales y símbolos	d3351	6	\N	\N
681	Producción de dibujos y fotografías	d3352	6	\N	\N
682	Producción de mensajes no verbales, otro especificado	d3358	6	\N	\N
683	Producción de mensajes no verbales, no especificado	d3359	6	\N	\N
684	Producción de mensajes en lenguaje de signos convencional	d340	6	\N	\N
685	Mensajes escritos	d345	6	\N	\N
686	Comunicación-producción, otra especificada y no especificada	d349	6	\N	\N
687	Conversación	d350	6	\N	\N
688	Iniciar una conversación	d3500	6	\N	\N
689	Mantener una conversación	d3501	6	\N	\N
690	Finalizar una conversación	d3502	6	\N	\N
691	Conversar con una sola persona	d3503	6	\N	\N
692	Conversar con muchas personas	d3504	6	\N	\N
693	Conversación, otro especificado	d3508	6	\N	\N
694	Conversación, no especificado	d3509	6	\N	\N
695	Discusión	d355	6	\N	\N
696	Discusión con una sola persona	d3550	6	\N	\N
697	Discusión con muchas personas	d3551	6	\N	\N
698	Discusión, otro especificado	d3558	6	\N	\N
699	Discusión, no especificado	d3559	6	\N	\N
700	Utilización de dispositivos y técnicas de comunicación	d360	6	\N	\N
701	Utilización de dispositivos de telecomunicación	d3600	6	\N	\N
702	Utilización de dispositivos para escribir	d3601	6	\N	\N
703	Utilización de técnicas de comunicación	d3602	6	\N	\N
704	Utilización de técnicas de comunicación, otros especificados	d3608	6	\N	\N
705	Utilización de técnicas de comunicación, otros no especificados	d3609	6	\N	\N
706	Conversación y utilización de dispositivos y técnicas de comunicación, otros especificados y no especificados	d369	6	\N	\N
707	Comunicación, otra especificada	d398	6	\N	\N
708	Comunicación, no especificada	d399	6	\N	\N
709	Cambiar las posturas corporales básicas	d410	24	\N	\N
710	Tumbarse	d4100	24	\N	\N
711	Ponerse en cuclillas	d4101	24	\N	\N
712	Ponerse de rodillas	d4102	24	\N	\N
713	Sentarse	d4103	24	\N	\N
714	Ponerse de pie	d4104	24	\N	\N
715	Inclinarse	d4105	24	\N	\N
716	Cambiar el centro de gravedad del cuerpo	d4106	24	\N	\N
717	Rodar	d4107	24	\N	\N
718	Cambiar las posturas corporales básicas, otras especificadas	d4108	24	\N	\N
719	Cambiar las posturas corporales básicas, no especificadas	d4109	24	\N	\N
720	Mantener la posición del cuerpo	d415	24	\N	\N
721	Permanecer acostado	d4150	24	\N	\N
722	Permanecer en cuclillas	d4151	24	\N	\N
723	Permanecer de rodillas	d4152	24	\N	\N
724	Permanecer sentado	d4153	24	\N	\N
725	Permanecer de pie	d4154	24	\N	\N
726	Mantener la posición de la cabeza	d4155	24	\N	\N
727	Mantener la posición del cuerpo, otra especificada	d4158	24	\N	\N
728	Mantener la posición del cuerpo, no especificada	d4159	24	\N	\N
729	Transferir el propio cuerpo	d420	24	\N	\N
730	Transferir el propio cuerpo mientras se está sentado	d4200	24	\N	\N
731	Transferir el propio cuerpo mientras se está acostado	d4201	24	\N	\N
732	Transferir el propio cuerpo, otro especificado	d4208	24	\N	\N
733	Transferir el propio cuerpo, no especificado	d4209	24	\N	\N
734	Cambiar y mantener la posición del cuerpo, otra especificada y no especificada	d429	24	\N	\N
735	Levantar y llevar objetos	d430	24	\N	\N
736	Levantar objetos	d4300	24	\N	\N
737	Llevar objetos en las manos	d4301	24	\N	\N
738	Llevar objetos en los brazos	d4302	24	\N	\N
739	Llevar objetos en los hombros, cadera y espalda	d4303	24	\N	\N
740	Llevar objetos en la cabeza	d4304	24	\N	\N
741	Posar objetos	d4305	24	\N	\N
742	Levantar y llevar objetos, otras especificadas	d4308	24	\N	\N
743	Levantar y llevar objetos, no especificadas	d4309	24	\N	\N
744	Mover objetos con las extremidades inferiores	d435	24	\N	\N
745	Empujar con las extremidades inferiores	d4350	24	\N	\N
746	Dar patadas/patear	d4351	24	\N	\N
747	Mover objetos con las extremidades inferiores, otras especificadas	d4358	24	\N	\N
748	Mover objetos con las extremidades inferiores, no especificadas	d4359	24	\N	\N
749	Uso fino de la mano	d440	24	\N	\N
750	Recoger objetos	d4400	24	\N	\N
751	Agarrar	d4401	24	\N	\N
752	Manipular	d4402	24	\N	\N
753	Soltar	d4403	24	\N	\N
754	Uso fino de la mano, otro especificado	d4408	24	\N	\N
755	Uso fino de la mano, no especificado	d4409	24	\N	\N
756	Uso de la mano y el brazo	d445	24	\N	\N
757	Tirar/halar	d4450	24	\N	\N
758	Empujar	d4451	24	\N	\N
759	Alcanzar	d4452	24	\N	\N
760	Girar o torcer las manos o los brazos	d4453	24	\N	\N
761	Lanzar	d4454	24	\N	\N
763	Uso de la mano y el brazo, otro especificado	d4458	24	\N	\N
764	Uso de la mano y el brazo, no especificado	d4459	24	\N	\N
765	Uso fino del pie	d446	24	\N	\N
766	Llevar, mover y usar objetos, otro especificado y no especificado	d449	24	\N	\N
767	Andar	d450	24	\N	\N
768	Andar distancias cortas	d4500	24	\N	\N
769	Andar distancias largas	d4501	24	\N	\N
770	Andar sobre diferentes superficies	d4502	24	\N	\N
771	Andar sorteando obstáculos	d4503	24	\N	\N
772	Andar, otro especificado	d4508	24	\N	\N
773	Andar, no especificado	d4509	24	\N	\N
774	Desplazarse por el entorno	d455	24	\N	\N
775	Arrastrarse	d4550	24	\N	\N
776	Trepar	d4551	24	\N	\N
777	Correr	d4552	24	\N	\N
778	Saltar	d4553	24	\N	\N
779	Nadar	d4554	24	\N	\N
780	Escabullirse y rodar	d4555	24	\N	\N
781	Caminar arrastrando los pies	d4556	24	\N	\N
782	Desplazarse por el entorno, otra especificada	d4558	24	\N	\N
783	Desplazarse por el entorno, no especificada	d4559	24	\N	\N
784	Desplazarse por distintos lugares	d460	24	\N	\N
785	Desplazarse dentro de la casa	d4600	24	\N	\N
786	Desplazarse dentro de edificios que no son la propia vivienda	d4601	24	\N	\N
787	Desplazarse fuera del hogar y de otros edificios	d4602	24	\N	\N
788	Desplazarse por distintos lugares, otro especificado	d4608	24	\N	\N
789	Desplazarse por distintos lugares, no especificado	d4609	24	\N	\N
790	Desplazarse utilizando algún tipo de equipamiento	d465	24	\N	\N
791	Andar y moverse, otro especificado y no especificado	d469	24	\N	\N
792	Utilización de medios de transporte	d470	24	\N	\N
793	Utilización de vehículos de tracción humana	d4700	24	\N	\N
794	Utilización de un medio de transporte con motor	d4701	24	\N	\N
795	Utilización de transporte público con motor	d4702	24	\N	\N
796	Utilización de humanos para el transporte	d4703	24	\N	\N
797	Utilización de medios de transporte, otro especificado	d4708	24	\N	\N
798	Utilización de medios de transporte, no especificado	d4709	24	\N	\N
799	Conducción	d475	24	\N	\N
800	Medios de transporte de tracción humana	d4750	24	\N	\N
801	Vehículos con motor	d4751	24	\N	\N
802	Vehículos de tracción animal	d4752	24	\N	\N
803	Conducción, otro especificado	d4758	24	\N	\N
804	Conducción, no especificado	d4759	24	\N	\N
805	Montar en animales como medio de transporte	d480	24	\N	\N
806	Desplazarse utilizando medios de transporte, otro especificado y no especificado	d489	24	\N	\N
807	Movilidad, otro especificado	d498	24	\N	\N
808	Movilidad, no especificado	d499	24	\N	\N
809	Lavarse	d510	5	\N	\N
810	Lavar partes individuales del cuerpo	d5100	5	\N	\N
811	Lavar todo el cuerpo	d5101	5	\N	\N
812	Secarse	d5102	5	\N	\N
813	Lavarse, otro especificado	d5108	5	\N	\N
814	Lavarse, no especificado	d5109	5	\N	\N
815	Cuidado de partes del cuerpo	d520	5	\N	\N
816	Cuidado de la piel	d5200	5	\N	\N
817	Cuidado de los dientes	d5201	5	\N	\N
818	Cuidado del pelo	d5202	5	\N	\N
819	Cuidado de las uñas de las manos	d5203	5	\N	\N
820	Cuidado de las uñas de los pies	d5204	5	\N	\N
821	Cuidado de la naríz	d5205	5	\N	\N
822	Cuidado de partes del cuerpo, otro especificado	d5208	5	\N	\N
823	Cuidado de partes del cuerpo, no especificado	d5209	5	\N	\N
824	Higiene personal relacionada con los procesos de excreción	d530	5	\N	\N
825	Regulación de la micción	d5300	5	\N	\N
826	Indicar la necesidad de micción	d53000	5	\N	\N
827	Indicar la necesidad de micción de manera apropiada	d53001	5	\N	\N
828	Indicar la necesidad de micción, otra especificada	d53008	5	\N	\N
829	Indicar la necesidad de micción, no especificada	d53009	5	\N	\N
830	Regulación de la defecación	d5301	5	\N	\N
831	Indicar la necesidad de defecación	d53010	5	\N	\N
832	Indicar la necesidad de defecación de manera aporpiada	d53011	5	\N	\N
833	Indicar la necesidad de defecación, otra especificada	d53018	5	\N	\N
834	Indicar la necesidad de defecación, no especificada	d53019	5	\N	\N
835	Cuidado menstrual	d5302	5	\N	\N
836	Higiene personal relacionada con los procesos de excreción, otro especificado	d5308	5	\N	\N
837	Higiene personal relacionada con los procesos de excreción, no especificado	d5309	5	\N	\N
838	Vestirse	d540	5	\N	\N
839	Ponerse la ropa	d5400	5	\N	\N
840	Quitarse la ropa	d5401	5	\N	\N
841	Ponerse calzado	d5402	5	\N	\N
842	Quitarse calzado	d5403	5	\N	\N
843	Elección de vestimenta adecuada	d5404	5	\N	\N
844	Vestirse, otro especificado	d5408	5	\N	\N
845	Vestirse, no especificado	d5409	5	\N	\N
846	Comer	d550	5	\N	\N
847	Indicar la necesidad de comer	d5500	5	\N	\N
848	Llevar a cabo adecuadamente las tareas relacionadas con comer	d5501	5	\N	\N
849	Comer, otro especificado	d5508	5	\N	\N
850	Comer, no especificado	d5509	5	\N	\N
851	Beber	d560	5	\N	\N
852	Indicar necesidad de beber	d5600	5	\N	\N
853	Llevar a cabo el amamantamiento	d5601	5	\N	\N
854	Llevar a cabo la toma de biberones	d5602	5	\N	\N
855	Beber, otro especificado	d5608	5	\N	\N
856	Beber, no especificado	d5609	5	\N	\N
857	Cuidado de la propia salud	d570	5	\N	\N
858	Asegurar el propio bienestar físico	d5700	5	\N	\N
859	Control de la dieta y la forma física	d5701	5	\N	\N
860	Mantenimiento de la salud	d5702	5	\N	\N
861	Control de medicaciones y seguimiento de consejos saludables	d57020	5	\N	\N
862	Búsqueda de consejo asistencia de cuidadores o profesionales	d57021	5	\N	\N
863	Evitar riesgos del abuso de drogas o alcohol	d57022	5	\N	\N
864	Mantenimiento de la salud, otra especificada	d57028	5	\N	\N
865	Mantenimiento de la salud, no especificada	d57029	5	\N	\N
866	Cuidado de la propia salud, otro especificado	d5708	5	\N	\N
867	Cuidado de la propia salud, no especificado	d5709	5	\N	\N
868	Cuidado de la propia seguridad	d571	5	\N	\N
869	Autocuidado, otro especificado	d598	5	\N	\N
870	Autocuidado, no especificado	d599	5	\N	\N
871	Adquisición de un lugar para vivir	d610	30	\N	\N
872	Comprar un lugar para vivir	d6100	30	\N	\N
873	Alquilar un lugar para vivir	d6101	30	\N	\N
874	Amueblar un lugar para vivir	d6102	30	\N	\N
875	Adquisición de un lugar para vivir, otro especificado	d6108	30	\N	\N
876	Adquisición de un lugar para vivir, otro no especificado	d6109	30	\N	\N
877	Adquisición de bienes y servicios	d620	30	\N	\N
878	Comprar	d6200	30	\N	\N
879	Recolectar bienes para satisfacer las necesidades diarias	d6201	30	\N	\N
880	Adquisición de bienes y servicios, otro especificado	d6208	30	\N	\N
881	Adquisición de bienes y servicios, no  especificado	d6209	30	\N	\N
882	Adquisición de lo necesario para vivir, otra especificada y no especificada	d629	30	\N	\N
883	Preparar comidas	d630	30	\N	\N
884	Preparar comidas sencillas	d6300	30	\N	\N
885	Preparar comidas complicadas	d6301	30	\N	\N
886	Ayudar a prepara comidas	d6302	30	\N	\N
887	Preparar comidas, otro especificado	d6308	30	\N	\N
888	Preparar comidas, no especificado	d6309	30	\N	\N
889	Realizar los quehaceres de la casa	d640	30	\N	\N
890	Lavar y secar ropa	d6400	30	\N	\N
891	Limpiar la zona de cocina y los utensilios	d6401	30	\N	\N
892	Limpieza de la vivienda	d6402	30	\N	\N
893	Utilización de aparatos domésticos	d6403	30	\N	\N
894	Almacenado de productos para satisfacer las necesidades diarias	d6404	30	\N	\N
895	Eliminación de la basura	d6405	30	\N	\N
896	Ayudar con los quehaceres de la casa	d6406	30	\N	\N
897	Realizar  los quehaceres de la casa, otro especificado	d6408	30	\N	\N
898	Realizar  los quehaceres de la casa, no especificado	d6409	30	\N	\N
899	Tareas del hogar, otras especificadas y no especificadas	d649	30	\N	\N
900	Cuidado de los objetos del hogar	d650	30	\N	\N
901	Hacer y remendar ropas	d6500	30	\N	\N
902	Mantenimiento de la vivienda y de los muebles	d6501	30	\N	\N
903	Mantenimiento de los aparatos domésticos	d6502	30	\N	\N
904	Mantenimiento de vehículos	d6503	30	\N	\N
905	Mantenimiento de los dispositivos de ayuda	d6504	30	\N	\N
906	Cuidado de las plantas, interiores y exteriores	d6505	30	\N	\N
907	Cuidado de los animales	d6506	30	\N	\N
908	Ayudar en el cuidado de los objetos del hogar	d6507	30	\N	\N
909	Cuidado de los objetos del hogar, otro especificado	d6508	30	\N	\N
910	Cuidado de los objetos del hogar, no especificado	d6509	30	\N	\N
911	Ayudar a los demás	d660	30	\N	\N
912	Ayudar a los demás en el autocuidado	d6600	30	\N	\N
913	Ayudar a los demás a desplazarse	d6601	30	\N	\N
914	Ayudar a los demás en la comunicación	d6602	30	\N	\N
915	Ayudar a los demás  en las relaciones interpersonales	d6603	30	\N	\N
916	Ayudar a los demás en la nutrición	d6604	30	\N	\N
917	Ayudar a los demás en el mantenimiento de la salud	d6605	30	\N	\N
918	Ayudar en asistir a otros	d6606	30	\N	\N
919	Ayudar a los demás, otro especificado	d6608	30	\N	\N
920	Ayudar a los demás, no especificado	d6609	30	\N	\N
921	Cuidado de los objetos del hogar y ayudar a los demás, otro especificado y no especificado	d669	30	\N	\N
922	Vida doméstica, otras especificadas	d698	30	\N	\N
923	Vida doméstica, no especificadas	d699	30	\N	\N
924	Interacciones interpersonales básicas	d710	23	\N	\N
925	Respeto y afecto en las relaciones	d7100	23	\N	\N
926	Aprecio en las relaciones	d7101	23	\N	\N
927	Tolerancia en las relaciones	d7102	23	\N	\N
928	Actitud crítica en las relaciones	d7103	23	\N	\N
929	Indicios sociales en las relaciones	d7104	23	\N	\N
930	Iniciar interacciones sociales	d71040	23	\N	\N
931	Mantener interacciones sociales	d71041	23	\N	\N
932	Indicios sociales en las relaciones, otra especificada	d71048	23	\N	\N
933	Indicios sociales en las relaciones, no especificada	d71049	23	\N	\N
934	Contacto físico en las relaciones	d7105	23	\N	\N
935	Diferenciación de personas de la familia	d7106	23	\N	\N
936	Interacciones interpersonales básicas, otras especificadas	d7108	23	\N	\N
937	Interacciones interpersonales básicas, no especificadas	d7109	23	\N	\N
938	Interacciones interpersonales complejas	d720	23	\N	\N
939	Establecer relaciones	d7200	23	\N	\N
940	Finalizar relaciones	d7201	23	\N	\N
941	Regulación del comportamiento en las interacciones	d7202	23	\N	\N
942	Interactuar de acuerdo a las reglas sociales	d7203	23	\N	\N
943	Mantener la distancia social	d7204	23	\N	\N
944	Interacciones interpersonales complejas, otras especificadas	d7208	23	\N	\N
945	Interacciones interpersonales complejas, no especificadas	d7209	23	\N	\N
946	Interacciones interpersonales generales, otras especificadas y no especificadas	d729	23	\N	\N
947	Relacionarse con extraños	d730	23	\N	\N
948	Relaciones formales	d740	23	\N	\N
949	Relacionarse con personas en posición de autoridad	d7400	23	\N	\N
950	Relacionarse con subordinados	d7401	23	\N	\N
951	Relaciones entre iguales	d7402	23	\N	\N
952	Relaciones formales, otra especificada	d7408	23	\N	\N
953	Relaciones formales, otra no especificada	d7409	23	\N	\N
954	Relaciones sociales informales	d750	23	\N	\N
955	Relaciones informales con amigos	d7500	23	\N	\N
956	Relaciones informales con vecinos	d7501	23	\N	\N
957	Relaciones informales con conocidos	d7502	23	\N	\N
958	Relaciones informales con compañeros de vivienda	d7503	23	\N	\N
959	Relaciones informales con iguales	d7504	23	\N	\N
1308	Sistemas sanitarios	e5801	27	\N	\N
960	Relaciones sociales informales, otras especificadas	d7508	23	\N	\N
961	Relaciones sociales informales, no especificadas	d7509	23	\N	\N
962	Relaciones familiares	d760	23	\N	\N
963	Relaciones padre-hijo	d7600	23	\N	\N
964	Relaciones hijo-padre	d7601	23	\N	\N
965	Relaciones fraternales	d7602	23	\N	\N
966	Relaciones con otros familiares	d7603	23	\N	\N
967	Relaciones familiares, otras especificadas	d7608	23	\N	\N
968	Relaciones familiares, no especificadas	d7609	23	\N	\N
969	Relaciones íntimas	d770	23	\N	\N
970	Relaciones sentimentales	d7700	23	\N	\N
971	Relaciones conyugales	d7701	23	\N	\N
972	Relaciones sexuales	d7702	23	\N	\N
973	Relaciones íntimas, otras especificadas	d7708	23	\N	\N
974	Relaciones íntimas, no especificadas	d7709	23	\N	\N
975	Relaciones interpersonales particulares, otras especificadas y no especificadas	d779	23	\N	\N
976	Interacciones y relaciones interpersonales, otras especificadas	d798	23	\N	\N
977	Interacciones y relaciones interpersonales, no especificadas	d799	23	\N	\N
978	Educación no reglada	d810	4	\N	\N
979	Educación preescolar	d815	4	\N	\N
980	Incorporarse al programa de educación preescolar o a alguno de sus niveles	d8150	4	\N	\N
981	Mantenerse en el programa de educación preescolar	d8151	4	\N	\N
982	Porgresar en el programa de educación preescolar	d8152	4	\N	\N
983	Finalizar el programa de educación preescolar	d8153	4	\N	\N
984	Educación preescolar, otra especificada	d8158	4	\N	\N
985	Educación preescolar, no especificada	d8159	4	\N	\N
986	Vida preescolar y actividades relacionadas	d816	4	\N	\N
987	Educación escolar	d820	4	\N	\N
988	Incorporarse al programa educativo o a alguno de sus niveles	d8200	4	\N	\N
989	Mantenerse en el programa educativo	d8201	4	\N	\N
990	Progresar en el programa educativo	d8202	4	\N	\N
991	Finalizar el programa educativo o niveles escolares	d8203	4	\N	\N
992	Educación escolar, otra especificada	d8208	4	\N	\N
993	Educación escolar, no especificada	d8209	4	\N	\N
994	Formación profesional	d825	4	\N	\N
995	Incorporarse a los programas de formación profesional o a alguno de sus niveles	d8250	4	\N	\N
996	Mantenerse en el programa de formación profesional	d8251	4	\N	\N
997	Progresar en el programa de formación profesional	d8252	4	\N	\N
998	Finalizar el programa de formación profesional	d8253	4	\N	\N
999	Formación profesional, otra especificada	d8258	4	\N	\N
1000	Formación profesional no especificada	d8259	4	\N	\N
1001	Educación superior	d830	4	\N	\N
1002	Incorporarse al programa de educación superior a alguno de sus niveles	d8300	4	\N	\N
1003	Mantenerse en el programa de educación superior	d8301	4	\N	\N
1004	Progresar en el programa de educación superior	d8302	4	\N	\N
1005	Finalizar el programa de educación superior	d8303	4	\N	\N
1006	Educación superior, otra especificada	d8308	4	\N	\N
1007	Educación superior, no especificada	d8309	4	\N	\N
1008	Vida escolar y actividades relacionadas	d835	4	\N	\N
1009	Educación, otra especificada y no especificada	d839	4	\N	\N
1010	Aprendizaje (preparación para el trabajo)	d840	4	\N	\N
1011	Conseguir, mantener y finalizar un trabajo	d845	4	\N	\N
1012	Buscar trabajo	d8450	4	\N	\N
1013	Mantener un trabajo	d8451	4	\N	\N
1014	Finalizar un trabajo	d8452	4	\N	\N
1015	Conseguir, mantener y finalizar un trabajo, otros especificados	d8458	4	\N	\N
1016	Conseguir, mantener y finalizar un trabajo, no especificados	d8459	4	\N	\N
1017	Trabajo remunerado	d850	4	\N	\N
1018	Trabajo como autónomo	d8500	4	\N	\N
1019	Trabajo a tiempo parcial	d8501	4	\N	\N
1020	Trabajo a jornada completa	d8502	4	\N	\N
1021	Trabajo remunerado, otro especificado	d8508	4	\N	\N
1022	Trabajo remunerado, no especificado	d8509	4	\N	\N
1023	Trabajo no remunerado	d855	4	\N	\N
1024	Trabajo y empleo, otro especificado y no especificado	d859	4	\N	\N
1025	Transacciones económicas básicas	d860	4	\N	\N
1026	Transacciones económicas complejas	d865	4	\N	\N
1027	Autosuficiencia económica	d870	4	\N	\N
1028	Recursos económicos personales	d8700	4	\N	\N
1029	Derechos sobre economía pública	d8701	4	\N	\N
1030	Autosuficiencia económica, otra especificada	d8708	4	\N	\N
1031	Autosuficiencia económica, no especificada	d8709	4	\N	\N
1032	Vida económica, otra especificada y no especificada	d879	4	\N	\N
1033	Participación en el juego	d880	4	\N	\N
1034	Juego en solitario	d8800	4	\N	\N
1035	Espectador del juego	d8801	4	\N	\N
1036	Juego paralelo	d8802	4	\N	\N
1037	Juego cooperativo	d8803	4	\N	\N
1038	Participación en el juego, otra especificada	d8808	4	\N	\N
1039	Participación en el juego, no especificada	d8809	4	\N	\N
1040	Áreas principales de la vida, otras especificadas	d898	4	\N	\N
1041	Áreas principales de la vida, no especificadas	d899	4	\N	\N
1042	Vida comunitaria	d910	29	\N	\N
1043	Asociaciones informales	d9100	29	\N	\N
1044	Asociaciones formales	d9101	29	\N	\N
1045	Ceremonias	d9102	29	\N	\N
1046	Vida comunitaria informal	d9103	29	\N	\N
1047	Vida comunitaria, otra especificada	d9108	29	\N	\N
1048	Vida comunitaria, no especificada	d9109	29	\N	\N
1049	Tiempo libre y ocio	d920	29	\N	\N
1050	Juego	d9200	29	\N	\N
1051	Deportes	d9201	29	\N	\N
1052	Arte y cultura	d9202	29	\N	\N
1053	Manualidades	d9203	29	\N	\N
1054	Aficiones	d9204	29	\N	\N
1055	Socialización	d9205	29	\N	\N
1056	Tiempo libre y ocio, otro especificado	d9208	29	\N	\N
1057	Tiempo libre y ocio, no especificado	d9209	29	\N	\N
1058	Religión y espiritualidad	d930	29	\N	\N
1059	Religión organizada	d9300	29	\N	\N
1060	Espiritualidad	d9301	29	\N	\N
1061	Religión y espiritualidad, otro especificado	d9308	29	\N	\N
1062	Religión y espiritualidad, no especificado	d9309	29	\N	\N
1063	Derechos humanos	d940	29	\N	\N
1064	Vida política y ciudadanía	d950	29	\N	\N
1065	Vida comunitaria, social y cívica, otra especificada	d998	29	\N	\N
1066	Vida comunitaria, social y cívica, no especificada	d999	29	\N	\N
1067	Productos o sustancias para el consumo personal	e110	26	\N	\N
1068	Comida	e1100	26	\N	\N
1069	Medicamentos	e1101	26	\N	\N
1070	Productos o sustancias para el consumo personal, otros especificados	e1108	26	\N	\N
1071	Productos o sustancias para el consumo personal, no especificados	e1109	26	\N	\N
1072	Productos y tecnología para uso personal en la vida diaria	e115	26	\N	\N
1073	Productos y tecnología generales para uso personal en la vida diaria	e1150	26	\N	\N
1074	Productos y tecnología  de ayuda para uso personal en la vida diaria	e1151	26	\N	\N
1075	Productos y tecnología utilizados para el juego	e1152	26	\N	\N
1076	Productos y tecnología utilizados para el juego	e11520	26	\N	\N
1077	Productos y tecnoogía utilizados para el juego	e11521	26	\N	\N
1078	Productos y tecnología utilizados para el juego, otra especificada	e11528	26	\N	\N
1079	Productos y tecnología utilizados para el juego, no especificada	e11529	26	\N	\N
1080	Productos y tecnología para uso personal en la vida diaria, otros especificados	e1158	26	\N	\N
1081	Productos y tecnología para uso personal en la vida diaria, no especificados	e1159	26	\N	\N
1082	Productos y tecnología para la movilidad  y el transporte personal en espacios cerrados y abiertos	e120	26	\N	\N
1083	Productos y tecnología generales para la movilidad  y el transporte personal en espacios cerrados y abiertos	e1200	26	\N	\N
1084	Productos y tecnología  de ayuda para la movilidad y el transporte personal en espacios cerrados y abiertos	e1201	26	\N	\N
1085	Productos y tecnología para la movilidad  y el transporte personal en espacios cerrados y abiertos, otros especificados	e1208	26	\N	\N
1086	Productos y tecnología para la movilidad  y el transporte personal en espacios cerrados y abiertos, no especificados	e1209	26	\N	\N
1087	Productos y tecnología para la comunicación	e125	26	\N	\N
1088	Productos y tecnología generales para la comunicación	e1250	26	\N	\N
1089	Productos y tecnología de ayuda  para la comunicación	e1251	26	\N	\N
1090	Productos y tecnología para la comunicación, otros especificados	e1258	26	\N	\N
1091	Productos y tecnología para la comunicación, no especificados	e1259	26	\N	\N
1092	Productos y tecnología para la educación	e130	26	\N	\N
1093	Productos y tecnología generales para la educación	e1300	26	\N	\N
1094	Productos y tecnología de ayuda  para la educación	e1301	26	\N	\N
1095	Productos y tecnología para la educación, otros especificados	e1308	26	\N	\N
1096	Productos y tecnología para la educación, no especificados	e1309	26	\N	\N
1097	Productos y tecnología para el empleo	e135	26	\N	\N
1098	Productos y tecnología generales para el empleo	e1350	26	\N	\N
1099	Productos y tecnología de ayuda  para el empleo	e1351	26	\N	\N
1100	Productos y tecnología para el empleo, otros especificados	e1358	26	\N	\N
1101	Productos y tecnología para el empleo, no  especificados	e1359	26	\N	\N
1102	Productos y tecnología para las actividades culturales, recreativas y deportivas	e140	26	\N	\N
1103	Productos y tecnología generales para las actividades culturales, recreativas y deportivas	e1400	26	\N	\N
1104	Productos y tecnología de ayuda  para las actividades culturales, recreativas y deportivas	e1401	26	\N	\N
1105	Productos y tecnología para las actividades culturales, recreativas y deportivas, otros especificados	e1408	26	\N	\N
1106	Productos y tecnología para las actividades culturales, recreativas y deportivas, no especificados	e1409	26	\N	\N
1107	Productos y tecnología para la práctica religiosa y la vida espiritual	e145	26	\N	\N
1108	Productos y tecnología generales para la práctica religiosa y la vida espiritual	e1450	26	\N	\N
1109	Productos y tecnología de ayuda para la práctica religiosa y la vida espiritual	e1451	26	\N	\N
1110	Productos y tecnología para la práctica religiosa y la vida espiritual, otros especificados	e1458	26	\N	\N
1111	Productos y tecnología para la práctica religiosa y la vida espiritual, no especificados	e1459	26	\N	\N
1112	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso público	e150	26	\N	\N
1113	Diseño, construcción, materiales de construcción y tecnología arquitectónica para entradas y salidas de edificios de uso público	e1500	26	\N	\N
1114	Diseño, construcción, materiales de construcción y tecnología arquitectónica para conseguir el acceso a las instalaciones dentro de  edificios de uso público	e1501	26	\N	\N
1115	Diseño, construcción, materiales de construcción y tecnología arquitectónica para indicar caminos, rutas y señalar lugares en  edificios de uso público	e1502	26	\N	\N
1116	Diseño, construcción, materiales de construcción y tecnología arquitectónica para garantizar la seguridad física de las personas en ediciios de uso público	e1503	26	\N	\N
1117	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso público, otros especificados	e1508	26	\N	\N
1118	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso público, no especificados	e1509	26	\N	\N
1119	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso privado	e155	26	\N	\N
1120	Diseño, construcción, materiales de construcción y tecnología arquitectónica para entradas y salidas de edificios de uso privado	e1550	26	\N	\N
1121	Diseño, construcción, materiales de construcción y tecnología arquitectónica para conseguir el acceso a las instalaciones dentro de  edificios de uso privado	e1551	26	\N	\N
1122	Diseño, construcción, materiales de construcción y tecnología arquitectónica para indicar caminos, rutas y señalar lugares en  edificios de uso privado	e1552	26	\N	\N
1123	Diseño, contrucción, materiales de construcción y tecnología arquitectónica para garantizar la seguridad física de las personas en edificios de uso privado	e1553	26	\N	\N
1124	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso privado, otros especificados	e1558	26	\N	\N
1125	Diseño, construcción, materiales de construcción y tecnología arquitectónica para edificios de uso privado, no especificados	e1559	26	\N	\N
1126	Productos y tecnología relacionados con el uso/ explotación del suelo	e160	26	\N	\N
1127	Productos y tecnología relacionados con el uso/ explotación de zonas rurales	e1600	26	\N	\N
1128	Productos y tecnología relacionados con el uso/ explotación de zonas suburbanas	e1601	26	\N	\N
1129	Productos y tecnología relacionados con el uso/ explotación de zonas urbanas	e1602	26	\N	\N
1130	Productos y tecnología de parques, zonas protegidas y reservas naturales	e1603	26	\N	\N
1131	Productos y tecnología relacionados con el uso/ explotación del suelo, otros especificados	e1608	26	\N	\N
1132	Productos y tecnología relacionados con el uso/ explotación del suelo, no especificados	e1609	26	\N	\N
1133	Pertenencias	e165	26	\N	\N
1134	Pertenencias financieras	e1650	26	\N	\N
1135	Pertenencias tangibles	e1651	26	\N	\N
1136	Pertenencias intangibles	e1652	26	\N	\N
1137	Pertenencias, otras especificadas	e1658	26	\N	\N
1138	Pertenencias, no especificadas	e1659	26	\N	\N
1139	Productos y tecnología, otros especificados	e198	26	\N	\N
1140	Productos y tecnología, no especificados	e199	26	\N	\N
1141	Geografía física	e210	8	\N	\N
1142	Formaciones geológicas	e2100	8	\N	\N
1143	Configuración hidrológica	e2101	8	\N	\N
1144	Geografía física, otros especificados	e2108	8	\N	\N
1145	Geografía física, no especificados	e2109	8	\N	\N
1146	Población	e215	8	\N	\N
1147	Cambio demográfico	e2150	8	\N	\N
1148	Densidad de población	e2151	8	\N	\N
1149	Población, otros especificados	e2158	8	\N	\N
1150	Población, no especificados	e2159	8	\N	\N
1151	Flora y fauna	e220	8	\N	\N
1152	Plantas	e2200	8	\N	\N
1153	Animales	e2201	8	\N	\N
1154	Flora y fauna, otros especificados	e2208	8	\N	\N
1155	Flora y fauna, no especificados	e2209	8	\N	\N
1156	Clima	e225	8	\N	\N
1157	Temperatura	e2250	8	\N	\N
1158	Humedad	e2251	8	\N	\N
1159	Presión atmosférica	e2252	8	\N	\N
1160	Precipitaciones	e2253	8	\N	\N
1161	Viento	e2254	8	\N	\N
1162	Variaciones estacionales	e2255	8	\N	\N
1163	Clima, otros especificados	e2258	8	\N	\N
1164	Clima, no especificados	e2259	8	\N	\N
1165	Desastres naturales	e230	8	\N	\N
1166	Desastres causado por el hombres	e235	8	\N	\N
1167	Luz	e240	8	\N	\N
1168	Intensidad de la luz	e2400	8	\N	\N
1169	Cualidad de la luz	e2401	8	\N	\N
1170	Luz, otros especificados	e2408	8	\N	\N
1171	Luz, no especificados	e2409	8	\N	\N
1172	Cambios relacionados con el paso del tiempo	e245	8	\N	\N
1173	Ciclos día/noche	e2450	8	\N	\N
1174	Ciclos lunares	e2451	8	\N	\N
1175	Cambios relacionados con el paso del tiempo, otros especificados	e2458	8	\N	\N
1176	Cambios relacionados con el paso del tiempo, no especificados	e2459	8	\N	\N
1177	Sonido	e250	8	\N	\N
1178	Intensidad del sonido	e2500	8	\N	\N
1179	Cualidad del sonido	e2501	8	\N	\N
1180	Sonido, otro especificado	e2508	8	\N	\N
1181	Sonido, no especificado	e2509	8	\N	\N
1182	Vibración	e255	8	\N	\N
1183	Cualidad del aire	e260	8	\N	\N
1184	Cualidad del aire en espacios cerrados	e2600	8	\N	\N
1185	Cualidad del aire en espacios abiertos	e2601	8	\N	\N
1186	Cualidad del aire, otros especificados	e2608	8	\N	\N
1187	Cualidad del aire, no especificados	e2609	8	\N	\N
1188	Entorno natural y cambios en el entorno derivados de la actividad humana, otros especificados	e298	8	\N	\N
1189	Entorno natural y cambios en el entorno derivados de la actividad humana, no especificados	e299	8	\N	\N
1190	Familiares cercanos	e310	2	\N	\N
1191	Otros familiares	e315	2	\N	\N
1192	Amigos	e320	2	\N	\N
1193	Conocidos, compañeros, colegas, vecinos y miembros de la comunidad	e325	2	\N	\N
1194	Personas en cargos de autoridad	e330	2	\N	\N
1195	Personas en cargos subordinados	e335	2	\N	\N
1196	Cuidadores y personal de ayuda	e340	2	\N	\N
1197	Extraños	e345	2	\N	\N
1198	Animales domésticos	e350	2	\N	\N
1199	Profesionales de la salud	e355	2	\N	\N
1200	Otros profesionales	e360	2	\N	\N
1201	Apoyo y relaciones, otros especificados	e398	2	\N	\N
1202	Apoyo y relaciones, no especificados	e399	2	\N	\N
1203	Actitudes individuales de miembros de la familia cercana	e410	1	\N	\N
1204	Actitudes individuales de otros familiares	e415	1	\N	\N
1205	Actitudes individuales de amigos	e420	1	\N	\N
1206	Actitudes individuales de conocidos, compañeros, colegas, vecinos y miembros de la comunidad	e425	1	\N	\N
1207	Actitudes individuales de personas en cargos de autoridad	e430	1	\N	\N
1208	Actitudes individuales de personas en cargos subordinados	e435	1	\N	\N
1209	Actitudes individuales de cuidadores y personal de ayuda	e440	1	\N	\N
1210	Actitudes individuales de extraños	e445	1	\N	\N
1211	Actitudes individuales de profesionales de la salud	e450	1	\N	\N
1212	Actitudes individuales de profesionales "relacionados con la salud"	e455	1	\N	\N
1213	Actitudes sociales	e460	1	\N	\N
1214	Normas, costumbres e ideologías sociales	e465	1	\N	\N
1215	Actitudes, otras especificadas	e498	1	\N	\N
1216	Actitudes, no especificadas	e499	1	\N	\N
1217	Servicios, sistemas y políticas de producción de artículos de consumo	e510	27	\N	\N
1218	Servicios de producción de artículos de consumo	e5100	27	\N	\N
1219	Sistemas de producción de artículos de consumo	e5101	27	\N	\N
1220	Políticas de producción de artículos de consumo	e5102	27	\N	\N
1221	Servicios, sistemas y políticas de producción de artículos de consumo, otros especificados	e5108	27	\N	\N
1222	Servicios, sistemas y políticas de producción de artículos de consumo, no especificados	e5109	27	\N	\N
1223	Servicios, sistemas y políticas de producción de arquitectura y construcción	e515	27	\N	\N
1224	Servicios de arquitectura y construcción	e5150	27	\N	\N
1225	Sistemas de arquitectura y construcción	e5151	27	\N	\N
1226	Políticas de arquitectura y construcción	e5152	27	\N	\N
1227	Servicios, sistemas y políticas de producción de arquitectura y construcción, otros especificados	e5158	27	\N	\N
1228	Servicios, sistemas y políticas de producción de arquitectura y construcción, no especificados	e5159	27	\N	\N
1229	Servicios, sistemas y políticas de planificación de los espacios abiertos	e520	27	\N	\N
1230	Servicios de planificación de los espacios abiertos	e5200	27	\N	\N
1231	Sistemas de planificación de los espacios abiertos	e5201	27	\N	\N
1232	Políticas de planificación de los espacios abiertos	e5202	27	\N	\N
1233	Servicios, sistemas y políticas de planificación de los espacios abiertos, otros especificados	e5208	27	\N	\N
1234	Servicios, sistemas y políticas de planificación de los espacios abiertos, no especificados	e5209	27	\N	\N
1235	Servicios, sistemas y políticas de vivienda	e525	27	\N	\N
1236	Servicios de vivienda	e5250	27	\N	\N
1237	Sistemas de vivienda	e5251	27	\N	\N
1238	Políticas de vivienda	e5252	27	\N	\N
1239	Servicios, sistemas y políticas de vivienda, otros especificados	e5258	27	\N	\N
1240	Servicios, sistemas y políticas de vivienda, no especificados	e5259	27	\N	\N
1241	Servicios, sistemas y políticas de utilidad pública	e530	27	\N	\N
1242	Servicios de utilidad pública	e5300	27	\N	\N
1243	Sistemas de utilidad pública	e5301	27	\N	\N
1244	Políticas de utilidad pública	e5302	27	\N	\N
1245	Servicios, sistemas y políticas de utilidad pública, otros especificados	e5308	27	\N	\N
1246	Servicios, sistemas y políticas de utilidad pública, no especificados	e5309	27	\N	\N
1247	Servicios, sistemas y políticas de comunicación	e535	27	\N	\N
1248	Servicios de comunicación	e5350	27	\N	\N
1249	Sistemas de comunicación	e5351	27	\N	\N
1250	Políticas de comunicación	e5352	27	\N	\N
1251	Servicios, sistemas y políticas de comunicación, otros especificados	e5358	27	\N	\N
1252	Servicios, sistemas y políticas de comunicación, no especificados	e5359	27	\N	\N
1253	Servicios, sistemas y políticas de transporte	e540	27	\N	\N
1254	Servicios de transporte	e5400	27	\N	\N
1255	Sistemas de transporte	e5401	27	\N	\N
1256	Políticas de transporte	e5402	27	\N	\N
1257	Servicios, sistemas y políticas de transporte, otros especificados	e5408	27	\N	\N
1258	Servicios, sistemas y políticas de transporte, no especificados	e5409	27	\N	\N
1259	Servicios, sistemas y políticas de protección civil	e545	27	\N	\N
1260	Servicios de protección civil	e5450	27	\N	\N
1261	Sistemas de protección civil	e5451	27	\N	\N
1262	Políticas de protección civil	e5452	27	\N	\N
1263	Servicios, sistemas y políticas de protección civil, otros especificados	e5458	27	\N	\N
1264	Servicios, sistemas y políticas de protección civil, no especificados	e5459	27	\N	\N
1265	Servicios, sistemas y políticas legales	e550	27	\N	\N
1266	Servicios legales	e5500	27	\N	\N
1267	Sistemas legales	e5501	27	\N	\N
1268	Políticas legales	e5502	27	\N	\N
1269	Servicios, sistemas y políticas legales, otros especificados	e5508	27	\N	\N
1270	Servicios, sistemas y políticas legales, no especificados	e5509	27	\N	\N
1271	Servicios, sistemas y políticas de asociación y organización	e555	27	\N	\N
1272	Servicios de asociación y organización	e5550	27	\N	\N
1273	Sistemas de asociación y organización	e5551	27	\N	\N
1274	Políticas de asociación y organización	e5552	27	\N	\N
1275	Servicios, sistemas y políticas de asociación y organización, otros especificados	e5558	27	\N	\N
1276	Servicios, sistemas y políticas de asociación y organización, no especificados	e5559	27	\N	\N
1277	Servicios, sistemas y políticas de medios de comunicación	e560	27	\N	\N
1278	Servicios de medios de comunicación	e5600	27	\N	\N
1279	Sistemas de comunicación	e5601	27	\N	\N
1280	Políticas de medios de comunicación	e5602	27	\N	\N
1281	Servicios, sistemas y políticas de medios de comunicación	e5608	27	\N	\N
1282	Servicios, sistemas y políticas de medios de comunicación no especificados	e5609	27	\N	\N
1283	Servicios, sistemas y políticas económicas	e565	27	\N	\N
1284	Servicios económicos	e5650	27	\N	\N
1285	Sistemas económicos	e5651	27	\N	\N
1286	Políticas económicas	e5652	27	\N	\N
1287	Servicios, sistemas y políticas económicas, otros especificados	e5658	27	\N	\N
1288	Servicios, sistemas y políticas económicas, no especificados	e5659	27	\N	\N
1289	Servicios, sistemas y políticas de seguridad social	e570	27	\N	\N
1290	Servicios de seguridad social	e5700	27	\N	\N
1291	Sistemas de seguridad social	e5701	27	\N	\N
1292	Políticas de seguridad social	e5702	27	\N	\N
1293	Servicios, sistemas y políticas de seguridad social, otros especificados	e5708	27	\N	\N
1294	Servicios, sistemas y políticas de seguridad social, no especificados	e5709	27	\N	\N
1295	Servicios, sistemas y políticas de apoyo social general	e575	27	\N	\N
1296	Servicios de apoyo social general	e5750	27	\N	\N
1297	Cuidado informal de niños o adultos por parte de la familia o amigos	e57500	27	\N	\N
1298	Cuidado diario de la familia proporcionado en la casa del proveedor del servicio	e57501	27	\N	\N
1299	Centro de servicios para el cuidado de niños o adultos lucrativo o no lucrativo	e57502	27	\N	\N
1300	Servicios de apoyo social general, otra especificada	e57508	27	\N	\N
1301	Servicios de apoyo social general, no especificada	e57509	27	\N	\N
1302	Sistemas de apoyo social general	e5751	27	\N	\N
1303	Políticas de apoyo social general	e5752	27	\N	\N
1304	Servicios, sistemas y políticas de apoyo social general, otros especificados	e5758	27	\N	\N
1305	Servicios, sistemas y políticas de apoyo social general, no  especificados	e5759	27	\N	\N
1306	Servicios, sistemas y políticas sanitarias	e580	27	\N	\N
1307	Servicios sanitarios	e5800	27	\N	\N
1309	Políticas sanitarias	e5802	27	\N	\N
1310	Servicios, sistemas y políticas sanitarias, otros especificados	e5808	27	\N	\N
1311	Servicios, sistemas y políticas sanitarias, otros especificados	e5809	27	\N	\N
1312	Servicios, sistemas y políticas de educación y formación	e585	27	\N	\N
1313	Servicios de educación y formación	e5850	27	\N	\N
1314	Sistemas de educación y formación	e5851	27	\N	\N
1315	Políticas de educación y formación	e5852	27	\N	\N
1316	Servicios de educación y formacion especial	e5853	27	\N	\N
1317	Sistemas de educación y formación especial	e5854	27	\N	\N
1318	Políticas de educación y formación especial	e5855	27	\N	\N
1319	Servicios, sistemas y políticas de educación y formación, otros especificados	e5858	27	\N	\N
1320	Servicios, sistemas y políticas de educación y formación, no especificados	e5859	27	\N	\N
1321	Servicios, sistemas y políticas laborales y de empleo	e590	27	\N	\N
1322	Servicios laborales y de empleo	e5900	27	\N	\N
1323	Sistemas laborales y de empleo	e5901	27	\N	\N
1324	Políticas laborales y de empleo	e5902	27	\N	\N
1325	Servicios, sistemas y políticas laborales y de empleo, otros especificados	e5908	27	\N	\N
1326	Servicios, sistemas y políticas laborales y de empleo, no especificados	e5909	27	\N	\N
1327	Servicios, sistemas y políticas de gobierno	e595	27	\N	\N
1328	Servicios de gobierno	e5950	27	\N	\N
1329	Sistemas de gobierno	e5951	27	\N	\N
1330	Políticas de gobierno	e5952	27	\N	\N
1331	Servicios, sistemas y políticas de gobierno, otras especificadas	e5958	27	\N	\N
1332	Servicios, sistemas y políticas de gobierno, no especificadas	e5959	27	\N	\N
1333	Servicios, sistemas y políticas, otros especificados	e598	27	\N	\N
1334	Servicios, sistemas y políticas, no  especificados	e599	27	\N	\N
1335	Estructura del cerebro	s110	10	\N	\N
1336	Estructura de los lóbulos corticales	s1100	10	\N	\N
1337	Lóbulo frontal	s11000	10	\N	\N
1338	Lóbulo temporal	s11001	10	\N	\N
1339	Lóbulo parietal	s11002	10	\N	\N
1340	Lóbulo occipital	s11003	10	\N	\N
1341	Estructura de los lóbulos corticales, otra especificada	s11008	10	\N	\N
1342	Estructura de los lóbulos corticales, no especificada	s11009	10	\N	\N
1343	Estructura del cerebro medio	s1101	10	\N	\N
1344	Estructura del diencéfalo	s1102	10	\N	\N
1345	Ganglios basales y estructuras relacionadas	s1103	10	\N	\N
1346	Estructura del cerebro	s1104	10	\N	\N
1347	Estructura del tronco cerebral	s1105	10	\N	\N
1348	Bulbo raquídeo	s11050	10	\N	\N
1349	Puente (protuberancia)	s11051	10	\N	\N
1350	Estructura del tronco cerebral, otra especificada	s11058	10	\N	\N
1351	Estructura del tronco cerebral, no especificada	s11059	10	\N	\N
1352	Estructura de los nervios craneales	s1106	10	\N	\N
1353	Estructura de la sustancia blanca	s1107	10	\N	\N
1354	Cuerpo calloso	s11070	10	\N	\N
1355	Estructura de la sustancia blanca, otras especificada	s11078	10	\N	\N
1356	Estructura de la sustancia blanca, no especificada	s11079	10	\N	\N
1357	Estructura del cerebro, otra especificada	s1108	10	\N	\N
1358	Estructura del cerebro, no especificada	s1109	10	\N	\N
1359	Médula espinal y estructuras relacionadas	s120	10	\N	\N
1360	Estructura de la médula espinal	s1200	10	\N	\N
1361	Médula espinal cervical	s12000	10	\N	\N
1362	Médula espinal torácica	s12001	10	\N	\N
1363	Médula espinal lumbosacra	s12002	10	\N	\N
1364	Médula Cola de caballo	s12003	10	\N	\N
1365	Estructura de la médula espinal, otra especificada	s12008	10	\N	\N
1366	Estructura de la médula espinal, no especificada	s12009	10	\N	\N
1367	Nervios espinales	s1201	10	\N	\N
1368	Estructura de la médula espinal y estructuras relacionadas, otra especificada	s1208	10	\N	\N
1369	Estructura de la médula espinal y estructuras relacionadas, no especificada	s1209	10	\N	\N
1370	Estructura de las meninges	s130	10	\N	\N
1371	Estructura del sistema nervioso simpático	s140	10	\N	\N
1372	Estructura del sistema nervioso parasimpático	s150	10	\N	\N
1373	Estructura del sistema nervioso, otra especificada	s198	10	\N	\N
1374	Estructura del sistema nervioso, no especificada	s199	10	\N	\N
1375	Estructura de la órbita ocular	s210	7	\N	\N
1376	Estructura del globo ocular	s220	7	\N	\N
1377	Conjuntiva, esclerótica, coroides	s2200	7	\N	\N
1378	Cornea	s2201	7	\N	\N
1379	Iris	s2202	7	\N	\N
1380	Retina	s2203	7	\N	\N
1381	Cristalino	s2204	7	\N	\N
1382	Humor vítreo	s2205	7	\N	\N
1383	Estructura del globo ocular, otra especificada	s2208	7	\N	\N
1384	Estructura del globo ocular, no especificada	s2209	7	\N	\N
1385	Estructura periféricas oculares	s230	7	\N	\N
1386	Glándulas lacrimales y estructuras relacionadas	s2300	7	\N	\N
1387	Pestañas	s2301	7	\N	\N
1388	Cejas	s2302	7	\N	\N
1389	Músculos oculares externos	s2303	7	\N	\N
1390	Estructuras alrededor del ojo, otras especificadas	s2308	7	\N	\N
1391	Estructuras alrededor del ojo, no especificadas	s2309	7	\N	\N
1392	Estructura del oído externo	s240	7	\N	\N
1393	Estructura del oído medio	s250	7	\N	\N
1394	Membrana timpánica	s2500	7	\N	\N
1395	Trompa de Eustaquio	s2501	7	\N	\N
1396	Huesecillos	s2502	7	\N	\N
1397	Estructura del oído medio, otra especificada	s2508	7	\N	\N
1398	Estructura del oído medio, no especificada	s2509	7	\N	\N
1399	Estructura del oído interno	s260	7	\N	\N
1400	Cóclea	s2600	7	\N	\N
1401	Laberinto vestibular	s2601	7	\N	\N
1402	Conductos semicirculares	s2602	7	\N	\N
1403	Conducto auditivo interno	s2603	7	\N	\N
1404	Estructura del oído interno, otra especificada	s2608	7	\N	\N
1405	Estructura del oído interno, no especificada	s2609	7	\N	\N
1406	Estructuras del ojo, el oído y sus estructuras relacionadas, otras especificadas	s298	7	\N	\N
1407	Estructuras del ojo, el oído y sus estructuras relacionadas, no especificadas	s299	7	\N	\N
1408	Estructura de la nariz	s310	11	\N	\N
1409	Nariz externa	s3100	11	\N	\N
1410	Tabique nasal	s3101	11	\N	\N
1411	Fosas nasales	s3102	11	\N	\N
1412	Estructura de la nariz, otra especificada	s3108	11	\N	\N
1413	Estructura de la nariz, no especificada	s3109	11	\N	\N
1414	Estructura de la boca	s320	11	\N	\N
1415	Dientes	s3200	11	\N	\N
1416	Dentición primaria	s32000	11	\N	\N
1417	Dentición permanente	s32001	11	\N	\N
1418	Estructura de los dientes, otra especificada	s32008	11	\N	\N
1419	Estructura de los dientes, no especificada	s32009	11	\N	\N
1420	Encías	s3201	11	\N	\N
1421	Estructura del paladar	s3202	11	\N	\N
1422	Paladar duro	s32020	11	\N	\N
1423	Paladar blando	s32021	11	\N	\N
1424	Lengua	s3203	11	\N	\N
1425	Estructura de los labios	s3204	11	\N	\N
1426	Labio superior	s32040	11	\N	\N
1427	Labio inferior	s32041	11	\N	\N
1428	Surco subnasal (Philtrum)	s3205	11	\N	\N
1429	Estructura de la boca, otra especificada	s3208	11	\N	\N
1430	Estructura de la boca, no especificada	s3209	11	\N	\N
1431	Estructura de la faringe	s330	11	\N	\N
1432	Nasofaringe	s3300	11	\N	\N
1433	Orofaringe	s3301	11	\N	\N
1434	Estructura de la faringe, otra especificada	s3308	11	\N	\N
1435	Estructura de la faringe, no especificada	s3309	11	\N	\N
1436	Estructura de la laringe	s340	11	\N	\N
1437	Cuerdas vocales	s3400	11	\N	\N
1438	Estructura de la laringe, otra especificada	s3408	11	\N	\N
1439	Estructura de la laringe, no especificada	s3409	11	\N	\N
1440	Estructuras involucradas en la voz y el habla, otras especificadas	s398	11	\N	\N
1441	Estructuras involucradas en la voz y el habla, no especificadas	s399	11	\N	\N
1442	Estructura del sistema cardiovascular	s410	9	\N	\N
1443	Corazón	s4100	9	\N	\N
1444	Aurículas	s41000	9	\N	\N
1445	Ventrículos	s41001	9	\N	\N
1446	Estructura del corazón, otra especificada	s41008	9	\N	\N
1447	Estructura del corazón, no especificada	s41009	9	\N	\N
1448	Arterias	s4101	9	\N	\N
1449	Venas	s4102	9	\N	\N
1450	Capilares	s4103	9	\N	\N
1451	Estructuras del sistema cardiovascular, otras especificadas	s4108	9	\N	\N
1452	Estructuras del sistema cardiovascular, no especificadas	s4109	9	\N	\N
1453	Estructura del sistema inmunológico	s420	9	\N	\N
1454	Vasos linfáticos	s4200	9	\N	\N
1455	Nódulos linfáticos	s4201	9	\N	\N
1456	Timo	s4202	9	\N	\N
1457	Bazo	s4203	9	\N	\N
1458	Médula ósea	s4204	9	\N	\N
1459	Estructura del sistema inmunológico, otra especificada	s4208	9	\N	\N
1460	Estructura del sistema inmunológico, no especificada	s4209	9	\N	\N
1461	Estructura del sistema respiratorio	s430	9	\N	\N
1462	Tráquea	s4300	9	\N	\N
1463	Pulmones	s4301	9	\N	\N
1464	Árbol bronquial	s43010	9	\N	\N
1465	Alvéolos	s43011	9	\N	\N
1466	Estructura de los pulmones, otra especificada	s43018	9	\N	\N
1467	Estructura de los pulmones, no especificada	s43019	9	\N	\N
1468	Caja torácica	s4302	9	\N	\N
1469	Músculos de la respiración	s4303	9	\N	\N
1470	Músculos intercostales	s43030	9	\N	\N
1471	Diafragma	s43031	9	\N	\N
1472	Músculos de la respiración, otro especificado	s43038	9	\N	\N
1473	Músculos de la respiración, no especificado	s43039	9	\N	\N
1474	Estructura del sistema respiratorio, otra especificada	s4308	9	\N	\N
1475	Estructura del sistema respiratorio, no  especificada	s4309	9	\N	\N
1476	Estructuras de los sistemas cardiovascular, inmunológico y respiratorio, otras especificadas	s498	9	\N	\N
1477	Estructuras de los sistemas cardiovascular, inmunológico y respiratorio, no especificadas	s499	9	\N	\N
1478	Estructura de las glándulas salivales	s510	14	\N	\N
1479	Estructura del esófago	s520	14	\N	\N
1480	Estructura del estómago	s530	14	\N	\N
1481	Estructura del intestino	s540	14	\N	\N
1482	Intestino delgado	s5400	14	\N	\N
1483	Intestino grueso	s5401	14	\N	\N
1484	Estructura del intestino, otra especificada	s5408	14	\N	\N
1485	Estructura del intestino, no especificada	s5409	14	\N	\N
1486	Estructura del páncreas	s550	14	\N	\N
1487	Estructura del hígado	s560	14	\N	\N
1488	Estructura de la vesícula y los conductos biliares	s570	14	\N	\N
1489	Estructura de las glándulas endocrinas	s580	14	\N	\N
1490	Glándula hipófisis	s5800	14	\N	\N
1491	Glándula tiroides	s5801	14	\N	\N
1492	Glándula paratiroides	s5802	14	\N	\N
1493	Glándula adrenal	s5803	14	\N	\N
1494	Estructura de las glándulas endocrinas, otra especificada	s5808	14	\N	\N
1495	Estructura de las glándulas endocrinas, no especificada	s5809	14	\N	\N
1496	Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino, otras especificadas	s598	14	\N	\N
1497	Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino, no especificadas	s599	14	\N	\N
1498	Estructura del sistema urinario	s610	13	\N	\N
1499	Riñones	s6100	13	\N	\N
1500	Uréteres	s6101	13	\N	\N
1501	Vejiga urinaria	s6102	13	\N	\N
1502	Uretra	s6103	13	\N	\N
1503	Estructura del sistema urinario, otra especificada	s6108	13	\N	\N
1504	Estructura del sistema urinario, no especificada	s6109	13	\N	\N
1505	Estructura del suelo pélvico	s620	13	\N	\N
1506	Estructura del sistema reproductor	s630	13	\N	\N
1507	Ovarios	s6300	13	\N	\N
1508	Estructura del útero	s6301	13	\N	\N
1509	Cuerpo del útero	s63010	13	\N	\N
1510	Cuello del útero	s63011	13	\N	\N
1511	Trompas de Falopio	s63012	13	\N	\N
1512	Estructura del útero, otra especificada	s63018	13	\N	\N
1513	Estructura del útero, no especificada	s63019	13	\N	\N
1514	Mama y pezón	s6302	13	\N	\N
1515	Estructura de la vagina y genitales externos	s6303	13	\N	\N
1516	Clítoris	s63030	13	\N	\N
1517	Labios mayores	s63031	13	\N	\N
1518	Labios menores	s63032	13	\N	\N
1519	Canal vaginal	s63033	13	\N	\N
1520	Testículos	s6304	13	\N	\N
1521	Estructura del pene	s6305	13	\N	\N
1522	Glande del pene	s63050	13	\N	\N
1523	Cuerpo esponjoso del pene	s63051	13	\N	\N
1524	Estructura del pene, otra especificada	s63058	13	\N	\N
1525	Estructura del pene, no especificada	s63059	13	\N	\N
1526	Próstata	s6306	13	\N	\N
1527	Estructuras del sistema reproductor, otras especificadas	s6308	13	\N	\N
1528	Estructuras del sistema reproductor, no  especificadas	s6309	13	\N	\N
1529	Estructuras relacionadas con el sistema genitourinario y sistema reproductor, otras especificadas	s698	13	\N	\N
1530	Estructuras relacionadas con el sistema genitourinario y sistema reproductor, no especificadas	s699	13	\N	\N
1531	Estructuras de la cabeza y de la región del cuello	s710	12	\N	\N
1532	Huesos del cráneo	s7100	12	\N	\N
1533	Suturas	s71000	12	\N	\N
1534	Fontanelas	s71001	12	\N	\N
1535	Estructura de los huesos del craneo, otra especificada	s71002	12	\N	\N
1536	Estructura de los huesos del craneo, no especificada	s71003	12	\N	\N
1537	Huesos de la cara	s7101	12	\N	\N
1538	Huesos de la región del cuello	s7102	12	\N	\N
1539	Articulaciones de la cabeza y de la región del cuello	s7103	12	\N	\N
1540	Músculos de la cabeza y de la región del cuello	s7104	12	\N	\N
1541	Ligamentos y fascias de la cabeza y de la región del cuello	s7105	12	\N	\N
1542	Estructura de la cabeza y de la región del cuello, otra especificada	s7108	12	\N	\N
1543	Estructura de la cabeza y de la región del cuello, no especificada	s7109	12	\N	\N
1544	Estructura de la región del hombro	s720	12	\N	\N
1545	Huesos de la región del hombro	s7200	12	\N	\N
1546	Articulaciones de la región del hombro	s7201	12	\N	\N
1547	Músculos de la región del hombro	s7202	12	\N	\N
1548	Ligamentos y fascias de la región del hombro	s7203	12	\N	\N
1549	Estructura de la región del hombro, otra especificada	s7208	12	\N	\N
1550	Estructura de la región del hombro, no especificada	s7209	12	\N	\N
1551	Estructura de la extremidad superior	s730	12	\N	\N
1552	Estructura del brazo	s7300	12	\N	\N
1553	Huesos del brazo	s73000	12	\N	\N
1554	Articulación del codo	s73001	12	\N	\N
1555	Músculos del brazo	s73002	12	\N	\N
1556	Ligamentos y fascias del brazo	s73003	12	\N	\N
1557	Estructuras del brazo, otra especificada	s73008	12	\N	\N
1558	Estructuras del brazo, no especificada	s73009	12	\N	\N
1559	Estructura del antebrazo	s7301	12	\N	\N
1560	Huesos del antebrazo	s73010	12	\N	\N
1561	Articulación de la muñeca	s73011	12	\N	\N
1562	Músculos del antebrazo	s73012	12	\N	\N
1563	Ligamentos y fascias del antebrazo	s73013	12	\N	\N
1564	Estructura del antebrazo, otra especificada	s73018	12	\N	\N
1565	Estructura del antebrazo, no especificada	s73019	12	\N	\N
1566	Estructura de la mano	s7302	12	\N	\N
1567	Huesos de la mano	s73020	12	\N	\N
1568	Articulaciones de la mano y de los dedos	s73021	12	\N	\N
1569	Músculos de la mano	s73022	12	\N	\N
1570	Ligamento  y fascias de la mano	s73023	12	\N	\N
1571	Estructura de la mano, otra especificada	s73028	12	\N	\N
1572	Estructura de la mano, no especificada	s73029	12	\N	\N
1573	Estructura de la extremidad superior, otra especificada	s7308	12	\N	\N
1574	Estructura de la extremidad superior, no especificada	s7309	12	\N	\N
1575	Estructura de la región pélvica	s740	12	\N	\N
1576	Huesos de la región pélvica	s7400	12	\N	\N
1577	Articulaciones de la región pélvica	s7401	12	\N	\N
1578	Músculos de la región pélvica	s7402	12	\N	\N
1579	Ligamentos y fascias de la región pélvica	s7403	12	\N	\N
1580	Estructura de la región pélvica, otra especificada	s7408	12	\N	\N
1581	Estructura de la región pélvica, no especificada	s7409	12	\N	\N
1582	Estructura de la extremidad inferior	s750	12	\N	\N
1583	Estructura del muslo	s7500	12	\N	\N
1584	Huesos del muslo	s75000	12	\N	\N
1585	Articulación de la cadera	s75001	12	\N	\N
1586	Músculos del muslo	s75002	12	\N	\N
1587	Ligamentos y fascias del muslo	s75003	12	\N	\N
1588	Estructura del muslo, otra especificada	s75008	12	\N	\N
1589	Estructura del muslo, no especificada	s75009	12	\N	\N
1590	Estructura de la pierna	s7501	12	\N	\N
1591	Huesos de la pierna	s75010	12	\N	\N
1592	Articulación de la rodilla	s75011	12	\N	\N
1593	Músculos de la pierna	s75012	12	\N	\N
1594	Ligamentos y fascias de la pierna	s75013	12	\N	\N
1595	Estructura de la pierna, otra especificada	s75018	12	\N	\N
1596	Estructura de la pierna, no especificada	s75019	12	\N	\N
1597	Estructura del tobillo y pie	s7502	12	\N	\N
1598	Huesos del tobillo y pie	s75020	12	\N	\N
1599	Articulaciones del tobillo y del dedo del pie	s75021	12	\N	\N
1600	Músculos del tobillo y del pie	s75022	12	\N	\N
1601	Ligamentos y fascias del tobillo y del pie	s75023	12	\N	\N
1602	Estructura del tobillo y pie, otra especificada	s75028	12	\N	\N
1603	Estructura del tobillo y pie, no especificada	s75029	12	\N	\N
1604	Estructura de la extremidad inferior, otra especificada	s7508	12	\N	\N
1605	Estructura de la extremidad inferior, no especificada	s7509	12	\N	\N
1606	Estructura del tronco	s760	12	\N	\N
1607	Estructura de la columna vertebral	s7600	12	\N	\N
1608	Columna vertebral cervical	s76000	12	\N	\N
1609	Columna vertebral torácica	s76001	12	\N	\N
1610	Columna vertebral lumbar	s76002	12	\N	\N
1611	Columna vertebral sacra	s76003	12	\N	\N
1612	Coxis	s76004	12	\N	\N
1613	Estructura de la columna vertebral, otra especificada	s76008	12	\N	\N
1614	Estructura de la columna vertebral, no especificada	s76009	12	\N	\N
1615	Músculos del tronco	s7601	12	\N	\N
1616	Ligamentos y fascias del tronco	s7602	12	\N	\N
1617	Estructura del tronco, otra especificada	s7608	12	\N	\N
1618	Estructura del tronco, no especificada	s7609	12	\N	\N
1619	Estructuras musculoesqueléticas adicionales relacionadas con el movimiento	s770	12	\N	\N
1620	Huesos	s7700	12	\N	\N
1621	Articulaciones	s7701	12	\N	\N
1622	Músculos	s7702	12	\N	\N
1623	Ligamentos extra-articulares, fascias, aponeurosis extramuscular, septums, bursas, no especificado	s7703	12	\N	\N
1624	Estructuras musculoesqueléticas adicionales relacionadas con el movimiento, otras especificadas	s7708	12	\N	\N
1625	Estructuras musculoesqueléticas adicionales relacionadas con el movimiento, no especificadas	s7709	12	\N	\N
1626	Estructuras relacionadas con el movimiento, otras especificadas	s798	12	\N	\N
1627	Estructuras relacionadas con el movimiento, no especificadas	s799	12	\N	\N
1628	Estructura de las áreas de la piel	s810	25	\N	\N
1629	Piel de la cabeza y de la región del cuello	s8100	25	\N	\N
1630	Piel de la región del hombro	s8101	25	\N	\N
1631	Piel de la extremidad superior	s8102	25	\N	\N
1632	Piel de la región pélvica	s8103	25	\N	\N
1633	Piel de la extremidad inferior	s8104	25	\N	\N
1634	Piel del tronco y espalda	s8105	25	\N	\N
1635	Estructura de áreas de la piel , otra especificada	s8108	25	\N	\N
1636	Estructura de áreas de la piel, no especificada	s8109	25	\N	\N
1637	Estructura de las glándulas de la piel	s820	25	\N	\N
1638	Glándulas sudoríparas	s8200	25	\N	\N
1639	Glándulas sebáceas	s8201	25	\N	\N
1640	Estructura de las glándulas de la piel, otra especificada	s8208	25	\N	\N
1641	Estructura de las glándulas de la piel, no especificada	s8209	25	\N	\N
1642	Estructura de las uñas	s830	25	\N	\N
1643	Uña de los dedos de las manos	s8300	25	\N	\N
1644	Uñas de los dedos de los pies	s8301	25	\N	\N
1645	Estructuras de las uñas, otras especificadas	s8308	25	\N	\N
1646	Estructuras de las uñas, no especificadas	s8309	25	\N	\N
1647	Estructura del pelo	s840	25	\N	\N
1648	Vello corporal	s8400	25	\N	\N
1649	Vello facial	s8401	25	\N	\N
1650	Vello axilar	s8402	25	\N	\N
1651	Vello púbico	s8403	25	\N	\N
1652	Estructura de pelo, otra especificada	s8408	25	\N	\N
1653	Estructura del pelo, no esoecificada	s8409	25	\N	\N
1654	Estructuras de la piel y estructuras relacionadas, otras especificadas	s898	25	\N	\N
1655	Estructuras de la piel y estructuras relacionadas, no especificadas	s899	25	\N	\N
\.


--
-- Data for Name: condicion_funcion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.condicion_funcion (id_condicion, id_funcion) FROM stdin;
\.


--
-- Data for Name: condicion_producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.condicion_producto (id_condicion, id_producto) FROM stdin;
\.


--
-- Data for Name: consulta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.consulta (id_consul, id_nna, id_personal, id_tipo_consul, fecha_consul, motivo, notas) FROM stdin;
\.


--
-- Data for Name: contacto_nna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacto_nna (id_contacto, id_nna, id_tipo_con, valor) FROM stdin;
\.


--
-- Data for Name: contacto_personal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacto_personal (id_contacto, id_personal, id_tipo_con, valor) FROM stdin;
\.


--
-- Data for Name: contacto_tutor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contacto_tutor (id_contacto, id_tutor, id_tipo_con, valor) FROM stdin;
\.


--
-- Data for Name: derecho; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.derecho (id_der, nom_der) FROM stdin;
1	Derecho a la vida, a la paz, a la supervivencia y al desarrollo
2	Derecho de prioridad
3	Derecho a la identidad
4	Derecho a vivir en familia
5	Derecho a la igualdad sustantiva
6	Derecho a no ser discriminado
7	Derecho a vivir en condiciones de bienestar y a un sano desarrollo integral
8	Derecho a una vida libre de violencia y a la integridad personal
9	Derecho a la protección de la salud y a la seguridad social
10	Derecho a la inclusión de NNA con discapacidad
11	Derecho a la educación
12	Derecho al descanso y al esparcimiento
13	Derecho a la libertad de convicciones éticas, pensamiento, conciencia, religión y cultura
14	Derecho a la libertad de expresión y de acceso a la información
15	Derecho de participación
16	Derecho de asociación y reunión
17	Derecho a la intimidad
18	Derecho a la seguridad jurídica y al debido proceso
19	Derechos de NNA migrantes
20	Derecho de acceso a las tecnologías de la información y comunicación
\.


--
-- Data for Name: direccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.direccion (id_direccion, calle, numero_ext, numero_int, referencias, id_asen) FROM stdin;
\.


--
-- Data for Name: donacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donacion (id_donacion, id_don, fecha, observacion) FROM stdin;
\.


--
-- Data for Name: donacion_especie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donacion_especie (id_donacion, descripcion, cantidad, valor_est) FROM stdin;
\.


--
-- Data for Name: donacion_monetaria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donacion_monetaria (id_donacion, monto, id_met_pago) FROM stdin;
\.


--
-- Data for Name: donante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donante (id_don, fecha_reg, activo) FROM stdin;
\.


--
-- Data for Name: donante_fisico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donante_fisico (id_don, nombre, apellido_p, apellido_m, rfc) FROM stdin;
\.


--
-- Data for Name: donante_moral; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.donante_moral (id_don, razon_social, rfc, representante) FROM stdin;
\.


--
-- Data for Name: enfermedad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.enfermedad (id_enf, nombre, codigo_cie, id_tipo_enf, cronica) FROM stdin;
1	Diabetes tipo 1	E10	5	t
2	Asma	J45	3	t
3	Epilepsia	G40	7	t
4	Desnutrición	E46	5	f
5	Anemia	D64	5	f
6	Tuberculosis	A15	2	f
7	VIH	B20	2	t
8	Cardiopatía congénita	Q24	4	t
9	Insuficiencia renal	N18	5	t
10	Hepatitis	B19	2	f
11	Cáncer infantil (leucemia)	C91	1	t
12	Bronquitis	J40	3	f
13	Gastritis	K29	8	f
14	Artritis	M13	6	t
15	Hipotiroidismo	E03	5	t
\.


--
-- Data for Name: entidad_federativa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.entidad_federativa (id_ent, nom_ent) FROM stdin;
1	Aguascalientes
2	Baja California
3	Baja California Sur
4	Campeche
5	Chiapas
6	Chihuahua
7	Ciudad de México
8	Coahuila
9	Colima
10	Durango
11	Estado de México
12	Guanajuato
13	Guerrero
14	Hidalgo
15	Jalisco
16	Michoacán
17	Morelos
18	Nayarit
19	Nuevo León
20	Oaxaca
21	Puebla
22	Querétaro
23	Quintana Roo
24	San Luis Potosí
25	Sinaloa
26	Sonora
27	Tabasco
28	Tamaulipas
29	Tlaxcala
30	Veracruz
31	Yucatán
32	Zacatecas
\.


--
-- Data for Name: equipo_miembro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipo_miembro (id_equipo, id_personal, fecha_alta, fecha_baja) FROM stdin;
\.


--
-- Data for Name: equipo_multidisciplinario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipo_multidisciplinario (id_equipo, nom_equipo, fecha_crea) FROM stdin;
1	Equipo de Atención Integral A	2026-06-22
2	Equipo de Atención Integral B	2026-06-22
3	Equipo de Restitución de Derechos	2026-06-22
4	Equipo de Primera Infancia	2026-06-22
\.


--
-- Data for Name: escolaridad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escolaridad (id_esc, nom_esc) FROM stdin;
1	Sin escolaridad
2	Preescolar
3	Primaria
4	Secundaria
5	Preparatoria
6	Bachillerato técnico
7	Educación especial
8	Licenciatura
9	No aplica (lactante)
\.


--
-- Data for Name: estatus_caso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estatus_caso (id_est_caso, nom_est_caso) FROM stdin;
1	Deteccion
2	Diagnostico
3	Plan de restitucion
4	Seguimiento
5	Cerrado
\.


--
-- Data for Name: funcion_corporal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.funcion_corporal (id_funcion, nom_funcion, codigo_cif) FROM stdin;
1	Funciones de la movilidad articular	b710
2	Funciones de la fuerza muscular	b730
3	Funciones del tono muscular	b735
4	Control de movimientos voluntarios	b760
5	Movimientos involuntarios	b765
6	Funciones visuales	b210
7	Funciones auditivas	b230
8	Funciones vestibulares (equilibrio)	b235
9	Funciones del gusto	b250
10	Funciones del olfato	b255
11	Funciones táctiles	b265
12	Funciones intelectuales	b117
13	Funciones de la atención	b140
14	Funciones de la memoria	b144
15	Funciones del lenguaje	b167
16	Funciones del cálculo	b172
17	Funciones emocionales	b152
18	Funciones psicosociales globales	b122
19	Funciones de la voz y el habla	b310
20	Funciones respiratorias	b440
\.


--
-- Data for Name: grado_dependencia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grado_dependencia (id_grado_dep, nom_grado_dep) FROM stdin;
0	Independiente
1	Dependencia Leve
2	Dependencia Moderada
3	Dependencia Severa
4	Dependencia Total
\.


--
-- Data for Name: grado_dificultad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grado_dificultad (id_grado_dif, nom_grado_dif, codigo_cif_dif, desc_cualitativa, rango_porcent) FROM stdin;
0	Ninguna	xxx.0	ninguna, insignificante	0-4%
1	Ligera	xxx.1	poca, escasa	5-24%
2	Moderada	xxx.2	media, regular	25-49%
3	Grave	xxx.3	mucha, extrema	50-95%
4	Completa	xxx.4	total	96-100%
8	No especificado	xxx.8		
9	No aplicable	xxx.9		
\.


--
-- Data for Name: hecho_dano; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hecho_dano (id_caso, id_tipo_dano) FROM stdin;
\.


--
-- Data for Name: hecho_victimizante; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hecho_victimizante (id_caso, id_tipo_vic, fecha_hecho, lugar_hecho, relato, victima_directa_nombre, victima_directa_parentesco, folio_renavi, carpeta_investigacion, autoridad_conoce, fecha_registro) FROM stdin;
\.


--
-- Data for Name: lengua; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lengua (id_len, familia_len, agrupacion_len, variante_len, autodenom_len) FROM stdin;
1	Indoeuropea	Romance	Español	Español
2	Yuto-nahua	Nahua	Náhuatl central	Mexicano
3	Maya	Chol	Chol	Lakty'añ
4	Huave	Huave	Huave	Ikoots
5	Seri	Seri	Seri	Cmiique iitom
6	Yuto-nahua	Nahua	Náhuatl de la Huasteca	Mexicano
7	Oto-mangue	Amuzgo	Amuzgo	Tzjon Noan
8	Yuto-nahua	Huichol	Huichol	Wixárika
9	Oto-mangue	Chatino	Chatino	Cha'cña
10	Oto-mangue	Zapoteco	Zapoteco del Istmo	Diidxazá
11	Yuto-nahua	Yaqui	Yaqui	Yoeme
12	Oto-mangue	Mazahua	Mazahua	Jñatjo
13	Oto-mangue	Chinanteco	Chinanteco	Tsa jujmí
14	Totonaco-tepehua	Totonaco	Totonaco de la Sierra	Tachiwín
15	Mixe-zoque	Zoque	Zoque	O'de püt
16	Oto-mangue	Otomí	Otomí del Valle	Hñähñu
17	Cochimí-yumana	Pápago	Pápago	Tohono O'odham
18	Oto-mangue	Triqui	Triqui	Tinujéi
19	Yuto-nahua	Cora	Cora	Naáyeri
20	Lengua de señas	LSM	Lengua de Señas Mexicana	LSM
21	Maya	Chontal de Tabasco	Chontal	Yoko ochoco
22	Maya	Tzotzil	Tzotzil	Bats'i k'op
23	Maya	Tzeltal	Tzeltal	Bats'il k'op
24	Oto-mangue	Mazateco	Mazateco	Ha shuta enima
25	Maya	Huasteco	Huasteco	Téenek
26	Tarasca	Purépecha	Purépecha	P'urhépecha
27	Yuto-nahua	Tarahumara	Tarahumara	Rarámuri
28	Maya	Tojolabal	Tojolabal	Tojol-ab'al
29	Mixe-zoque	Mixe	Mixe	Ayüük
30	Oto-mangue	Mixteco	Mixteco de la Costa	Tu'un savi
31	Álgica	Kickapoo	Kickapoo	Kikapú
32	Oto-mangue	Popoloca	Popoloca	Ngiwa
33	Maya	Maya peninsular	Maya	Maaya t'aan
\.


--
-- Data for Name: lenguaje_nna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lenguaje_nna (id_nna, id_len, preferente, id_mod_adc, id_niv_com, id_niv_escrito, id_personal_registro) FROM stdin;
\.


--
-- Data for Name: lenguaje_tutor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lenguaje_tutor (id_tutor, id_len, preferente, id_mod_adc, id_niv_com, id_niv_escrito) FROM stdin;
\.


--
-- Data for Name: metodo_pago; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.metodo_pago (id_met_pago, nom_met_pago) FROM stdin;
1	Efectivo
2	Transferencia
3	Tarjeta
4	Cheque
\.


--
-- Data for Name: modo_adquisicion_lengua; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modo_adquisicion_lengua (id_mod_adc, categ_mod_adc, desc_mod_adc) FROM stdin;
1	Lengua materna	Adquirida en el hogar desde el nacimiento
2	Segunda lengua	Aprendida después de la lengua materna
3	Lengua escolar	Aprendida en el entorno educativo
\.


--
-- Data for Name: nacionalidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nacionalidad (id_nac, nom_nac) FROM stdin;
1	Mexicana
2	Guatemalteca
3	Hondureña
4	Salvadoreña
5	Estadounidense
6	Venezolana
7	Colombiana
8	Haitiana
9	Otra
\.


--
-- Data for Name: nacionalidad_nna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nacionalidad_nna (id_nna, id_nac) FROM stdin;
\.


--
-- Data for Name: nivel_competencia_oral; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nivel_competencia_oral (id_niv_com, niv_prac_com, sign_niv_com) FROM stdin;
1	Nativo	Comprende y se expresa con total fluidez
2	Avanzado	Se comunica con fluidez en la mayoría de los contextos
3	Intermedio	Mantiene conversaciones cotidianas con algunas limitaciones
4	Básico	Comprende y usa frases sencillas
\.


--
-- Data for Name: nna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nna (id_nna, folio_nna, nombre, apellido_p, apellido_m, fecha_nacimiento, curp, id_sexo, id_esc, id_direccion, lugar_nacimiento) FROM stdin;
\.


--
-- Data for Name: nna_condicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nna_condicion (id_nna, id_condicion, fecha_diag, diagnosticada, id_grado_dif, id_grado_dep) FROM stdin;
\.


--
-- Data for Name: nna_enfermedad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nna_enfermedad (id_nna, id_enf, fecha_diag, en_tratamiento) FROM stdin;
\.


--
-- Data for Name: nna_tutor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nna_tutor (id_nna, id_tutor, fecha_ini, fecha_fin, id_paren, tutor_legal) FROM stdin;
\.


--
-- Data for Name: parentesco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parentesco (id_paren, nom_paren) FROM stdin;
1	Abuela/o
2	Tia/o
3	Hermana/o mayor
4	Madrina/Padrino
5	Otro
6	Madre
7	Padre
8	Abuela
9	Abuelo
10	Hermana/o
11	Prima/o
12	Tutor designado por DIF
13	Familia de acogida
\.


--
-- Data for Name: personal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal (id, nombre, apellido_p, apellido_m, rfc, curp, fecha_nacimiento, id_sexo, id_direccion, correo, password1, rol_id, es_empleado, esta_activo) FROM stdin;
1	Ian	Director	General	RFC12345	CURP12345	1990-01-01	1	\N	director@datacore.com	admin123	1	t	t
2	Diana	Coordinadora	General	RFCDIANA01	CURPDIANA0123456	1995-01-01	2	\N	coordinador@datacore.com	coord123	2	t	t
\.


--
-- Data for Name: personal_lengua; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal_lengua (id_personal, id_len, id_mod_adc, id_niv_com, id_niv_escrito) FROM stdin;
\.


--
-- Data for Name: producto_apoyo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto_apoyo (id_producto, nom_producto, codigo_cif) FROM stdin;
1	Silla de ruedas manual	e1201
2	Silla de ruedas eléctrica	e1201
3	Bastón / muleta	e1201
4	Andadera	e1201
5	Prótesis	e1151
6	Órtesis / férula	e1151
7	Audífono	e1251
8	Implante coclear	e1251
9	Bastón blanco (visual)	e1201
10	Lentes / ayudas ópticas	e1551
11	Lector de pantalla / software	e1251
12	Tablero de comunicación (CAA)	e1251
13	Sistema braille	e1301
14	Cama / colchón especial	e1151
15	Pañal / producto de continencia	e1151
16	Sonda / equipo de alimentación	e1151
17	Oxígeno / equipo respiratorio	e1151
18	Ninguno	\N
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre_rol, permite_voluntariado) FROM stdin;
1	Director	f
2	Coordinador	f
3	Psicologo	t
4	Doctor	t
5	Abogado	t
6	Trabajador Social	t
7	Analista	f
8	Equipo Multidisciplinario	f
\.


--
-- Data for Name: seguimiento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.seguimiento (id_seg, id_caso, id_personal, fecha_seg, descripcion) FROM stdin;
\.


--
-- Data for Name: sexo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sexo (id_sexo, nom_sexo) FROM stdin;
1	MASCULINO
2	FEMENINO
3	OTRO
4	NO ESPECIFICADO
\.


--
-- Data for Name: subcategoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subcategoria (id_subcategoria, nombre, id_categoria) FROM stdin;
1	Actitudes	3
2	Apoyo y relaciones	3
3	Aprendizaje y aplicación del conocimiento	2
4	Areas principales de la vida	3
5	Autocuidado	1
6	Comunicación	4
7	El ojo, el oído y estructuras relacionadas	4
8	Entorno natural y cambios en el entorno derivados de la actividad humana	3
9	Estructuras de los sistemas cardiovascular, inmunológico y respiratorio	1
10	Estructuras del sistema nervioso	1
11	Estructuras involucradas en la voz y el habla	4
12	Estructuras relacionadas con el movimiento	1
13	Estructuras relacionadas con el sistema genitourinario y el sistema reproductor	1
14	Estructuras relacionadas con los sistemas digestivo, metabólico y endocrino	1
15	Funciones de la piel y estructuras relacionadas	1
16	Funciones de la voz y el habla	4
17	Funciones de los sistemas cardiovascular, hematológico, inmunológico y respiratorio	1
18	Funciones de los sistemas digestivo, metabólico y endocrino	1
19	Funciones genitourinarias y reproductoras	1
20	Funciones mentales	2
21	Funciones neuromusculoesqueléticas y relacionadas con el movimiento	1
22	Funciones sensoriales y dolor	4
23	Interacciones y relaciones interpersonales	3
24	Movilidad	1
25	Piel y estructuras relacionadas	1
26	Productos y tecnología	3
27	Servicios, sistemas y políticas	3
28	Tareas y demandas generales	2
29	Vida comunitaria, social y cívica	3
30	Vida domestica	1
\.


--
-- Data for Name: tipo_apoyo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_apoyo (id_tipo_apo, nom_tipo_apo) FROM stdin;
1	Economico
2	Medico
3	Psicologico
4	Juridico
5	Educativo
6	Alimentario
7	Vivienda
\.


--
-- Data for Name: tipo_consulta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_consulta (id_tipo_consul, nom_tipo_consul) FROM stdin;
1	Medica
2	Psicologica
3	Juridica
4	Trabajo Social
\.


--
-- Data for Name: tipo_contacto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_contacto (id_tipo_con, nom_tipo_con) FROM stdin;
1	Telefono
2	Celular
3	Correo
4	WhatsApp
5	Telefono de recados
6	Red social
\.


--
-- Data for Name: tipo_dano; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_dano (id_tipo_dano, nom_tipo_dano) FROM stdin;
1	Físico
2	Psicológico
3	Sexual
4	Patrimonial
5	Proyecto de vida
6	Otro
\.


--
-- Data for Name: tipo_enfermedad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_enfermedad (id_tipo_enf, nom_tipo_enf) FROM stdin;
1	Crónico-degenerativa
2	Infecciosa
3	Respiratoria
4	Cardiovascular
5	Metabólica
6	Autoinmune
7	Neurológica
8	Gastrointestinal
9	Otra
\.


--
-- Data for Name: tipo_victima; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipo_victima (id_tipo_vic, nom_tipo_vic, descripcion) FROM stdin;
1	Directa	Quien sufre directamente el menoscabo de sus derechos
2	Indirecta	Familiares o personas a cargo de la víctima directa (p. ej. NNA en orfandad)
3	Potencial	Personas en riesgo por auxiliar o impedir la victimización
\.


--
-- Data for Name: tutor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tutor (id_tutor, nombre, apellido_p, apellido_m, fecha_nacimiento, curp, ocupacion, id_sexo, id_direccion) FROM stdin;
\.


--
-- Data for Name: tutor_condicion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tutor_condicion (id_tutor, id_condicion, id_grado_dif, id_grado_dep) FROM stdin;
\.


--
-- Data for Name: ubicacion_lengua; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ubicacion_lengua (id_ent, id_len) FROM stdin;
\.


--
-- Name: apoyo_id_apo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.apoyo_id_apo_seq', 1, false);


--
-- Name: asentamiento_id_asen_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.asentamiento_id_asen_seq', 1, true);


--
-- Name: caso_id_caso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caso_id_caso_seq', 1, false);


--
-- Name: cif_dominio_id_dominio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cif_dominio_id_dominio_seq', 4, true);


--
-- Name: cif_evaluacion_id_evaluacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cif_evaluacion_id_evaluacion_seq', 1, false);


--
-- Name: consulta_id_consul_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.consulta_id_consul_seq', 1, false);


--
-- Name: contacto_nna_id_contacto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contacto_nna_id_contacto_seq', 1, false);


--
-- Name: contacto_personal_id_contacto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contacto_personal_id_contacto_seq', 1, false);


--
-- Name: contacto_tutor_id_contacto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contacto_tutor_id_contacto_seq', 1, false);


--
-- Name: derecho_id_der_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.derecho_id_der_seq', 20, true);


--
-- Name: direccion_id_direccion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.direccion_id_direccion_seq', 1, true);


--
-- Name: donacion_id_donacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.donacion_id_donacion_seq', 1, false);


--
-- Name: donante_id_don_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.donante_id_don_seq', 1, false);


--
-- Name: enfermedad_id_enf_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.enfermedad_id_enf_seq', 15, true);


--
-- Name: entidad_federativa_id_ent_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.entidad_federativa_id_ent_seq', 33, true);


--
-- Name: equipo_multidisciplinario_id_equipo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipo_multidisciplinario_id_equipo_seq', 4, true);


--
-- Name: escolaridad_id_esc_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.escolaridad_id_esc_seq', 9, true);


--
-- Name: estatus_caso_id_est_caso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estatus_caso_id_est_caso_seq', 5, true);


--
-- Name: funcion_corporal_id_funcion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.funcion_corporal_id_funcion_seq', 40, true);


--
-- Name: lengua_id_len_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lengua_id_len_seq', 33, true);


--
-- Name: metodo_pago_id_met_pago_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.metodo_pago_id_met_pago_seq', 4, true);


--
-- Name: modo_adquisicion_lengua_id_mod_adc_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modo_adquisicion_lengua_id_mod_adc_seq', 3, true);


--
-- Name: nacionalidad_id_nac_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.nacionalidad_id_nac_seq', 9, true);


--
-- Name: nivel_competencia_oral_id_niv_com_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.nivel_competencia_oral_id_niv_com_seq', 4, true);


--
-- Name: nna_id_nna_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.nna_id_nna_seq', 1, false);


--
-- Name: parentesco_id_paren_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parentesco_id_paren_seq', 13, true);


--
-- Name: personal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_id_seq', 3, true);


--
-- Name: producto_apoyo_id_producto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producto_apoyo_id_producto_seq', 36, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 8, true);


--
-- Name: seguimiento_id_seg_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seguimiento_id_seg_seq', 1, false);


--
-- Name: sexo_id_sexo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sexo_id_sexo_seq', 4, true);


--
-- Name: tipo_apoyo_id_tipo_apo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_apoyo_id_tipo_apo_seq', 7, true);


--
-- Name: tipo_consulta_id_tipo_consul_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_consulta_id_tipo_consul_seq', 4, true);


--
-- Name: tipo_contacto_id_tipo_con_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_contacto_id_tipo_con_seq', 6, true);


--
-- Name: tipo_dano_id_tipo_dano_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_dano_id_tipo_dano_seq', 6, true);


--
-- Name: tipo_enfermedad_id_tipo_enf_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_enfermedad_id_tipo_enf_seq', 9, true);


--
-- Name: tipo_victima_id_tipo_vic_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_victima_id_tipo_vic_seq', 3, true);


--
-- Name: tutor_id_tutor_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tutor_id_tutor_seq', 1, false);


--
-- Name: apoyo apoyo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.apoyo
    ADD CONSTRAINT apoyo_pkey PRIMARY KEY (id_apo);


--
-- Name: asentamiento asentamiento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asentamiento
    ADD CONSTRAINT asentamiento_pkey PRIMARY KEY (id_asen);


--
-- Name: asignacion_caso asignacion_caso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignacion_caso
    ADD CONSTRAINT asignacion_caso_pkey PRIMARY KEY (id_caso, id_personal, rol_id, fecha_asig);


--
-- Name: caso_derecho caso_derecho_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_derecho
    ADD CONSTRAINT caso_derecho_pkey PRIMARY KEY (id_caso, id_nna, id_der);


--
-- Name: caso caso_folio_caso_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso
    ADD CONSTRAINT caso_folio_caso_key UNIQUE (folio_caso);


--
-- Name: caso_nna caso_nna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_nna
    ADD CONSTRAINT caso_nna_pkey PRIMARY KEY (id_caso, id_nna);


--
-- Name: caso caso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso
    ADD CONSTRAINT caso_pkey PRIMARY KEY (id_caso);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- Name: cif_catalogo cif_catalogo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_catalogo
    ADD CONSTRAINT cif_catalogo_pkey PRIMARY KEY (codigo_cif);


--
-- Name: cif_dominio cif_dominio_letra_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_dominio
    ADD CONSTRAINT cif_dominio_letra_key UNIQUE (letra);


--
-- Name: cif_dominio cif_dominio_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_dominio
    ADD CONSTRAINT cif_dominio_nombre_key UNIQUE (nombre);


--
-- Name: cif_dominio cif_dominio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_dominio
    ADD CONSTRAINT cif_dominio_pkey PRIMARY KEY (id_dominio);


--
-- Name: cif_eval_actividad cif_eval_actividad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_actividad
    ADD CONSTRAINT cif_eval_actividad_pkey PRIMARY KEY (id_evaluacion, codigo_cif);


--
-- Name: cif_eval_ambiental cif_eval_ambiental_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_ambiental
    ADD CONSTRAINT cif_eval_ambiental_pkey PRIMARY KEY (id_evaluacion, codigo_cif);


--
-- Name: cif_eval_estructura cif_eval_estructura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_estructura
    ADD CONSTRAINT cif_eval_estructura_pkey PRIMARY KEY (id_evaluacion, codigo_cif);


--
-- Name: cif_eval_funcion cif_eval_funcion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_funcion
    ADD CONSTRAINT cif_eval_funcion_pkey PRIMARY KEY (id_evaluacion, codigo_cif);


--
-- Name: cif_evaluacion cif_evaluacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_evaluacion
    ADD CONSTRAINT cif_evaluacion_pkey PRIMARY KEY (id_evaluacion);


--
-- Name: condicion_funcion condicion_funcion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion_funcion
    ADD CONSTRAINT condicion_funcion_pkey PRIMARY KEY (id_condicion, id_funcion);


--
-- Name: condicion condicion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_pkey PRIMARY KEY (id_condicion);


--
-- Name: condicion_producto condicion_producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion_producto
    ADD CONSTRAINT condicion_producto_pkey PRIMARY KEY (id_condicion, id_producto);


--
-- Name: consulta consulta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_pkey PRIMARY KEY (id_consul);


--
-- Name: contacto_nna contacto_nna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_nna
    ADD CONSTRAINT contacto_nna_pkey PRIMARY KEY (id_contacto);


--
-- Name: contacto_personal contacto_personal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_personal
    ADD CONSTRAINT contacto_personal_pkey PRIMARY KEY (id_contacto);


--
-- Name: contacto_tutor contacto_tutor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_tutor
    ADD CONSTRAINT contacto_tutor_pkey PRIMARY KEY (id_contacto);


--
-- Name: derecho derecho_nom_der_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.derecho
    ADD CONSTRAINT derecho_nom_der_key UNIQUE (nom_der);


--
-- Name: derecho derecho_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.derecho
    ADD CONSTRAINT derecho_pkey PRIMARY KEY (id_der);


--
-- Name: direccion direccion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_pkey PRIMARY KEY (id_direccion);


--
-- Name: donacion_especie donacion_especie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion_especie
    ADD CONSTRAINT donacion_especie_pkey PRIMARY KEY (id_donacion);


--
-- Name: donacion_monetaria donacion_monetaria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion_monetaria
    ADD CONSTRAINT donacion_monetaria_pkey PRIMARY KEY (id_donacion);


--
-- Name: donacion donacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion
    ADD CONSTRAINT donacion_pkey PRIMARY KEY (id_donacion);


--
-- Name: donante_fisico donante_fisico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_fisico
    ADD CONSTRAINT donante_fisico_pkey PRIMARY KEY (id_don);


--
-- Name: donante_fisico donante_fisico_rfc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_fisico
    ADD CONSTRAINT donante_fisico_rfc_key UNIQUE (rfc);


--
-- Name: donante_moral donante_moral_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_moral
    ADD CONSTRAINT donante_moral_pkey PRIMARY KEY (id_don);


--
-- Name: donante_moral donante_moral_rfc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_moral
    ADD CONSTRAINT donante_moral_rfc_key UNIQUE (rfc);


--
-- Name: donante donante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante
    ADD CONSTRAINT donante_pkey PRIMARY KEY (id_don);


--
-- Name: enfermedad enfermedad_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enfermedad
    ADD CONSTRAINT enfermedad_nombre_key UNIQUE (nombre);


--
-- Name: enfermedad enfermedad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enfermedad
    ADD CONSTRAINT enfermedad_pkey PRIMARY KEY (id_enf);


--
-- Name: entidad_federativa entidad_federativa_nom_ent_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entidad_federativa
    ADD CONSTRAINT entidad_federativa_nom_ent_key UNIQUE (nom_ent);


--
-- Name: entidad_federativa entidad_federativa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entidad_federativa
    ADD CONSTRAINT entidad_federativa_pkey PRIMARY KEY (id_ent);


--
-- Name: equipo_miembro equipo_miembro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_miembro
    ADD CONSTRAINT equipo_miembro_pkey PRIMARY KEY (id_equipo, id_personal, fecha_alta);


--
-- Name: equipo_multidisciplinario equipo_multidisciplinario_nom_equipo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_multidisciplinario
    ADD CONSTRAINT equipo_multidisciplinario_nom_equipo_key UNIQUE (nom_equipo);


--
-- Name: equipo_multidisciplinario equipo_multidisciplinario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_multidisciplinario
    ADD CONSTRAINT equipo_multidisciplinario_pkey PRIMARY KEY (id_equipo);


--
-- Name: escolaridad escolaridad_nom_esc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escolaridad
    ADD CONSTRAINT escolaridad_nom_esc_key UNIQUE (nom_esc);


--
-- Name: escolaridad escolaridad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escolaridad
    ADD CONSTRAINT escolaridad_pkey PRIMARY KEY (id_esc);


--
-- Name: estatus_caso estatus_caso_nom_est_caso_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_caso
    ADD CONSTRAINT estatus_caso_nom_est_caso_key UNIQUE (nom_est_caso);


--
-- Name: estatus_caso estatus_caso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_caso
    ADD CONSTRAINT estatus_caso_pkey PRIMARY KEY (id_est_caso);


--
-- Name: funcion_corporal funcion_corporal_nom_funcion_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion_corporal
    ADD CONSTRAINT funcion_corporal_nom_funcion_key UNIQUE (nom_funcion);


--
-- Name: funcion_corporal funcion_corporal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion_corporal
    ADD CONSTRAINT funcion_corporal_pkey PRIMARY KEY (id_funcion);


--
-- Name: grado_dependencia grado_dependencia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grado_dependencia
    ADD CONSTRAINT grado_dependencia_pkey PRIMARY KEY (id_grado_dep);


--
-- Name: grado_dificultad grado_dificultad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grado_dificultad
    ADD CONSTRAINT grado_dificultad_pkey PRIMARY KEY (id_grado_dif);


--
-- Name: hecho_dano hecho_dano_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_dano
    ADD CONSTRAINT hecho_dano_pkey PRIMARY KEY (id_caso, id_tipo_dano);


--
-- Name: hecho_victimizante hecho_victimizante_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_victimizante
    ADD CONSTRAINT hecho_victimizante_pkey PRIMARY KEY (id_caso);


--
-- Name: lengua lengua_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lengua
    ADD CONSTRAINT lengua_pkey PRIMARY KEY (id_len);


--
-- Name: lenguaje_nna lenguaje_nna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_pkey PRIMARY KEY (id_nna, id_len);


--
-- Name: lenguaje_tutor lenguaje_tutor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_tutor
    ADD CONSTRAINT lenguaje_tutor_pkey PRIMARY KEY (id_tutor, id_len);


--
-- Name: metodo_pago metodo_pago_nom_met_pago_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metodo_pago
    ADD CONSTRAINT metodo_pago_nom_met_pago_key UNIQUE (nom_met_pago);


--
-- Name: metodo_pago metodo_pago_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metodo_pago
    ADD CONSTRAINT metodo_pago_pkey PRIMARY KEY (id_met_pago);


--
-- Name: modo_adquisicion_lengua modo_adquisicion_lengua_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modo_adquisicion_lengua
    ADD CONSTRAINT modo_adquisicion_lengua_pkey PRIMARY KEY (id_mod_adc);


--
-- Name: nacionalidad_nna nacionalidad_nna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad_nna
    ADD CONSTRAINT nacionalidad_nna_pkey PRIMARY KEY (id_nna, id_nac);


--
-- Name: nacionalidad nacionalidad_nom_nac_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad
    ADD CONSTRAINT nacionalidad_nom_nac_key UNIQUE (nom_nac);


--
-- Name: nacionalidad nacionalidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad
    ADD CONSTRAINT nacionalidad_pkey PRIMARY KEY (id_nac);


--
-- Name: nivel_competencia_oral nivel_competencia_oral_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nivel_competencia_oral
    ADD CONSTRAINT nivel_competencia_oral_pkey PRIMARY KEY (id_niv_com);


--
-- Name: nna_condicion nna_condicion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_condicion
    ADD CONSTRAINT nna_condicion_pkey PRIMARY KEY (id_nna, id_condicion);


--
-- Name: nna nna_curp_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_curp_key UNIQUE (curp);


--
-- Name: nna_enfermedad nna_enfermedad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_enfermedad
    ADD CONSTRAINT nna_enfermedad_pkey PRIMARY KEY (id_nna, id_enf);


--
-- Name: nna nna_folio_nna_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_folio_nna_key UNIQUE (folio_nna);


--
-- Name: nna nna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_pkey PRIMARY KEY (id_nna);


--
-- Name: nna_tutor nna_tutor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_tutor
    ADD CONSTRAINT nna_tutor_pkey PRIMARY KEY (id_nna, id_tutor, fecha_ini);


--
-- Name: parentesco parentesco_nom_paren_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_nom_paren_key UNIQUE (nom_paren);


--
-- Name: parentesco parentesco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parentesco
    ADD CONSTRAINT parentesco_pkey PRIMARY KEY (id_paren);


--
-- Name: personal personal_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_correo_key UNIQUE (correo);


--
-- Name: personal personal_curp_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_curp_key UNIQUE (curp);


--
-- Name: personal_lengua personal_lengua_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_pkey PRIMARY KEY (id_personal, id_len);


--
-- Name: personal personal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_pkey PRIMARY KEY (id);


--
-- Name: personal personal_rfc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_rfc_key UNIQUE (rfc);


--
-- Name: producto_apoyo producto_apoyo_nom_producto_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_apoyo
    ADD CONSTRAINT producto_apoyo_nom_producto_key UNIQUE (nom_producto);


--
-- Name: producto_apoyo producto_apoyo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_apoyo
    ADD CONSTRAINT producto_apoyo_pkey PRIMARY KEY (id_producto);


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
-- Name: seguimiento seguimiento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seguimiento
    ADD CONSTRAINT seguimiento_pkey PRIMARY KEY (id_seg);


--
-- Name: sexo sexo_nom_sexo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexo
    ADD CONSTRAINT sexo_nom_sexo_key UNIQUE (nom_sexo);


--
-- Name: sexo sexo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexo
    ADD CONSTRAINT sexo_pkey PRIMARY KEY (id_sexo);


--
-- Name: subcategoria subcategoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria
    ADD CONSTRAINT subcategoria_pkey PRIMARY KEY (id_subcategoria);


--
-- Name: tipo_apoyo tipo_apoyo_nom_tipo_apo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_apoyo
    ADD CONSTRAINT tipo_apoyo_nom_tipo_apo_key UNIQUE (nom_tipo_apo);


--
-- Name: tipo_apoyo tipo_apoyo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_apoyo
    ADD CONSTRAINT tipo_apoyo_pkey PRIMARY KEY (id_tipo_apo);


--
-- Name: tipo_consulta tipo_consulta_nom_tipo_consul_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_consulta
    ADD CONSTRAINT tipo_consulta_nom_tipo_consul_key UNIQUE (nom_tipo_consul);


--
-- Name: tipo_consulta tipo_consulta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_consulta
    ADD CONSTRAINT tipo_consulta_pkey PRIMARY KEY (id_tipo_consul);


--
-- Name: tipo_contacto tipo_contacto_nom_tipo_con_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_contacto
    ADD CONSTRAINT tipo_contacto_nom_tipo_con_key UNIQUE (nom_tipo_con);


--
-- Name: tipo_contacto tipo_contacto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_contacto
    ADD CONSTRAINT tipo_contacto_pkey PRIMARY KEY (id_tipo_con);


--
-- Name: tipo_dano tipo_dano_nom_tipo_dano_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_dano
    ADD CONSTRAINT tipo_dano_nom_tipo_dano_key UNIQUE (nom_tipo_dano);


--
-- Name: tipo_dano tipo_dano_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_dano
    ADD CONSTRAINT tipo_dano_pkey PRIMARY KEY (id_tipo_dano);


--
-- Name: tipo_enfermedad tipo_enfermedad_nom_tipo_enf_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_enfermedad
    ADD CONSTRAINT tipo_enfermedad_nom_tipo_enf_key UNIQUE (nom_tipo_enf);


--
-- Name: tipo_enfermedad tipo_enfermedad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_enfermedad
    ADD CONSTRAINT tipo_enfermedad_pkey PRIMARY KEY (id_tipo_enf);


--
-- Name: tipo_victima tipo_victima_nom_tipo_vic_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_victima
    ADD CONSTRAINT tipo_victima_nom_tipo_vic_key UNIQUE (nom_tipo_vic);


--
-- Name: tipo_victima tipo_victima_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_victima
    ADD CONSTRAINT tipo_victima_pkey PRIMARY KEY (id_tipo_vic);


--
-- Name: tutor_condicion tutor_condicion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor_condicion
    ADD CONSTRAINT tutor_condicion_pkey PRIMARY KEY (id_tutor, id_condicion);


--
-- Name: tutor tutor_curp_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor
    ADD CONSTRAINT tutor_curp_key UNIQUE (curp);


--
-- Name: tutor tutor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor
    ADD CONSTRAINT tutor_pkey PRIMARY KEY (id_tutor);


--
-- Name: ubicacion_lengua ubicacion_lengua_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion_lengua
    ADD CONSTRAINT ubicacion_lengua_pkey PRIMARY KEY (id_ent, id_len);


--
-- Name: idx_cif_codigo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cif_codigo ON public.cif_catalogo USING btree (codigo_cif);


--
-- Name: caso trg_un_equipo_por_nna_caso; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_un_equipo_por_nna_caso BEFORE INSERT OR UPDATE OF id_equipo ON public.caso FOR EACH ROW EXECUTE FUNCTION public.fn_un_equipo_por_nna_en_caso();


--
-- Name: caso_nna trg_un_equipo_por_nna_casonna; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_un_equipo_por_nna_casonna BEFORE INSERT OR UPDATE ON public.caso_nna FOR EACH ROW EXECUTE FUNCTION public.fn_un_equipo_por_nna_en_casonna();


--
-- Name: personal trg_valida_voluntariado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_valida_voluntariado BEFORE INSERT OR UPDATE ON public.personal FOR EACH ROW EXECUTE FUNCTION public.fn_valida_voluntariado();


--
-- Name: apoyo apoyo_id_tipo_apo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.apoyo
    ADD CONSTRAINT apoyo_id_tipo_apo_fkey FOREIGN KEY (id_tipo_apo) REFERENCES public.tipo_apoyo(id_tipo_apo);


--
-- Name: asentamiento asentamiento_id_ent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asentamiento
    ADD CONSTRAINT asentamiento_id_ent_fkey FOREIGN KEY (id_ent) REFERENCES public.entidad_federativa(id_ent);


--
-- Name: asignacion_caso asignacion_caso_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignacion_caso
    ADD CONSTRAINT asignacion_caso_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES public.caso(id_caso);


--
-- Name: asignacion_caso asignacion_caso_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignacion_caso
    ADD CONSTRAINT asignacion_caso_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: asignacion_caso asignacion_caso_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignacion_caso
    ADD CONSTRAINT asignacion_caso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- Name: caso_derecho caso_derecho_id_caso_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_derecho
    ADD CONSTRAINT caso_derecho_id_caso_id_nna_fkey FOREIGN KEY (id_caso, id_nna) REFERENCES public.caso_nna(id_caso, id_nna);


--
-- Name: caso_derecho caso_derecho_id_der_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_derecho
    ADD CONSTRAINT caso_derecho_id_der_fkey FOREIGN KEY (id_der) REFERENCES public.derecho(id_der);


--
-- Name: caso caso_id_equipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso
    ADD CONSTRAINT caso_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES public.equipo_multidisciplinario(id_equipo);


--
-- Name: caso caso_id_est_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso
    ADD CONSTRAINT caso_id_est_caso_fkey FOREIGN KEY (id_est_caso) REFERENCES public.estatus_caso(id_est_caso);


--
-- Name: caso_nna caso_nna_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_nna
    ADD CONSTRAINT caso_nna_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES public.caso(id_caso);


--
-- Name: caso_nna caso_nna_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caso_nna
    ADD CONSTRAINT caso_nna_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: cif_catalogo cif_catalogo_codigo_padre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_catalogo
    ADD CONSTRAINT cif_catalogo_codigo_padre_fkey FOREIGN KEY (codigo_padre) REFERENCES public.cif_catalogo(codigo_cif);


--
-- Name: cif_catalogo cif_catalogo_id_dominio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_catalogo
    ADD CONSTRAINT cif_catalogo_id_dominio_fkey FOREIGN KEY (id_dominio) REFERENCES public.cif_dominio(id_dominio);


--
-- Name: cif_eval_actividad cif_eval_actividad_codigo_cif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_actividad
    ADD CONSTRAINT cif_eval_actividad_codigo_cif_fkey FOREIGN KEY (codigo_cif) REFERENCES public.cif_catalogo(codigo_cif);


--
-- Name: cif_eval_actividad cif_eval_actividad_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_actividad
    ADD CONSTRAINT cif_eval_actividad_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.cif_evaluacion(id_evaluacion);


--
-- Name: cif_eval_ambiental cif_eval_ambiental_codigo_cif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_ambiental
    ADD CONSTRAINT cif_eval_ambiental_codigo_cif_fkey FOREIGN KEY (codigo_cif) REFERENCES public.cif_catalogo(codigo_cif);


--
-- Name: cif_eval_ambiental cif_eval_ambiental_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_ambiental
    ADD CONSTRAINT cif_eval_ambiental_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.cif_evaluacion(id_evaluacion);


--
-- Name: cif_eval_estructura cif_eval_estructura_codigo_cif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_estructura
    ADD CONSTRAINT cif_eval_estructura_codigo_cif_fkey FOREIGN KEY (codigo_cif) REFERENCES public.cif_catalogo(codigo_cif);


--
-- Name: cif_eval_estructura cif_eval_estructura_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_estructura
    ADD CONSTRAINT cif_eval_estructura_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.cif_evaluacion(id_evaluacion);


--
-- Name: cif_eval_funcion cif_eval_funcion_codigo_cif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_funcion
    ADD CONSTRAINT cif_eval_funcion_codigo_cif_fkey FOREIGN KEY (codigo_cif) REFERENCES public.cif_catalogo(codigo_cif);


--
-- Name: cif_eval_funcion cif_eval_funcion_id_evaluacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cif_eval_funcion
    ADD CONSTRAINT cif_eval_funcion_id_evaluacion_fkey FOREIGN KEY (id_evaluacion) REFERENCES public.cif_evaluacion(id_evaluacion);


--
-- Name: condicion_funcion condicion_funcion_id_funcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion_funcion
    ADD CONSTRAINT condicion_funcion_id_funcion_fkey FOREIGN KEY (id_funcion) REFERENCES public.funcion_corporal(id_funcion);


--
-- Name: condicion condicion_id_grado_dep_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_id_grado_dep_fkey FOREIGN KEY (id_grado_dep) REFERENCES public.grado_dependencia(id_grado_dep);


--
-- Name: condicion condicion_id_grado_dif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_id_grado_dif_fkey FOREIGN KEY (id_grado_dif) REFERENCES public.grado_dificultad(id_grado_dif);


--
-- Name: condicion condicion_id_subcategoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion
    ADD CONSTRAINT condicion_id_subcategoria_fkey FOREIGN KEY (id_subcategoria) REFERENCES public.subcategoria(id_subcategoria);


--
-- Name: condicion_producto condicion_producto_id_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.condicion_producto
    ADD CONSTRAINT condicion_producto_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.producto_apoyo(id_producto);


--
-- Name: consulta consulta_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: consulta consulta_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: consulta consulta_id_tipo_consul_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_id_tipo_consul_fkey FOREIGN KEY (id_tipo_consul) REFERENCES public.tipo_consulta(id_tipo_consul);


--
-- Name: contacto_nna contacto_nna_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_nna
    ADD CONSTRAINT contacto_nna_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: contacto_nna contacto_nna_id_tipo_con_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_nna
    ADD CONSTRAINT contacto_nna_id_tipo_con_fkey FOREIGN KEY (id_tipo_con) REFERENCES public.tipo_contacto(id_tipo_con);


--
-- Name: contacto_personal contacto_personal_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_personal
    ADD CONSTRAINT contacto_personal_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: contacto_personal contacto_personal_id_tipo_con_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_personal
    ADD CONSTRAINT contacto_personal_id_tipo_con_fkey FOREIGN KEY (id_tipo_con) REFERENCES public.tipo_contacto(id_tipo_con);


--
-- Name: contacto_tutor contacto_tutor_id_tipo_con_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_tutor
    ADD CONSTRAINT contacto_tutor_id_tipo_con_fkey FOREIGN KEY (id_tipo_con) REFERENCES public.tipo_contacto(id_tipo_con);


--
-- Name: contacto_tutor contacto_tutor_id_tutor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contacto_tutor
    ADD CONSTRAINT contacto_tutor_id_tutor_fkey FOREIGN KEY (id_tutor) REFERENCES public.tutor(id_tutor);


--
-- Name: direccion direccion_id_asen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_id_asen_fkey FOREIGN KEY (id_asen) REFERENCES public.asentamiento(id_asen);


--
-- Name: donacion_especie donacion_especie_id_donacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion_especie
    ADD CONSTRAINT donacion_especie_id_donacion_fkey FOREIGN KEY (id_donacion) REFERENCES public.donacion(id_donacion);


--
-- Name: donacion donacion_id_don_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion
    ADD CONSTRAINT donacion_id_don_fkey FOREIGN KEY (id_don) REFERENCES public.donante(id_don);


--
-- Name: donacion_monetaria donacion_monetaria_id_donacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion_monetaria
    ADD CONSTRAINT donacion_monetaria_id_donacion_fkey FOREIGN KEY (id_donacion) REFERENCES public.donacion(id_donacion);


--
-- Name: donacion_monetaria donacion_monetaria_id_met_pago_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donacion_monetaria
    ADD CONSTRAINT donacion_monetaria_id_met_pago_fkey FOREIGN KEY (id_met_pago) REFERENCES public.metodo_pago(id_met_pago);


--
-- Name: donante_fisico donante_fisico_id_don_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_fisico
    ADD CONSTRAINT donante_fisico_id_don_fkey FOREIGN KEY (id_don) REFERENCES public.donante(id_don);


--
-- Name: donante_moral donante_moral_id_don_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donante_moral
    ADD CONSTRAINT donante_moral_id_don_fkey FOREIGN KEY (id_don) REFERENCES public.donante(id_don);


--
-- Name: enfermedad enfermedad_id_tipo_enf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enfermedad
    ADD CONSTRAINT enfermedad_id_tipo_enf_fkey FOREIGN KEY (id_tipo_enf) REFERENCES public.tipo_enfermedad(id_tipo_enf);


--
-- Name: equipo_miembro equipo_miembro_id_equipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_miembro
    ADD CONSTRAINT equipo_miembro_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES public.equipo_multidisciplinario(id_equipo);


--
-- Name: equipo_miembro equipo_miembro_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_miembro
    ADD CONSTRAINT equipo_miembro_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: hecho_dano hecho_dano_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_dano
    ADD CONSTRAINT hecho_dano_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES public.hecho_victimizante(id_caso) ON DELETE CASCADE;


--
-- Name: hecho_dano hecho_dano_id_tipo_dano_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_dano
    ADD CONSTRAINT hecho_dano_id_tipo_dano_fkey FOREIGN KEY (id_tipo_dano) REFERENCES public.tipo_dano(id_tipo_dano);


--
-- Name: hecho_victimizante hecho_victimizante_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_victimizante
    ADD CONSTRAINT hecho_victimizante_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES public.caso(id_caso) ON DELETE CASCADE;


--
-- Name: hecho_victimizante hecho_victimizante_id_tipo_vic_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_victimizante
    ADD CONSTRAINT hecho_victimizante_id_tipo_vic_fkey FOREIGN KEY (id_tipo_vic) REFERENCES public.tipo_victima(id_tipo_vic);


--
-- Name: hecho_victimizante hecho_victimizante_lugar_hecho_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_victimizante
    ADD CONSTRAINT hecho_victimizante_lugar_hecho_fkey FOREIGN KEY (lugar_hecho) REFERENCES public.entidad_federativa(id_ent);


--
-- Name: hecho_victimizante hecho_victimizante_victima_directa_parentesco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hecho_victimizante
    ADD CONSTRAINT hecho_victimizante_victima_directa_parentesco_fkey FOREIGN KEY (victima_directa_parentesco) REFERENCES public.parentesco(id_paren);


--
-- Name: lenguaje_nna lenguaje_nna_id_len_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_len_fkey FOREIGN KEY (id_len) REFERENCES public.lengua(id_len);


--
-- Name: lenguaje_nna lenguaje_nna_id_mod_adc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_mod_adc_fkey FOREIGN KEY (id_mod_adc) REFERENCES public.modo_adquisicion_lengua(id_mod_adc);


--
-- Name: lenguaje_nna lenguaje_nna_id_niv_com_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_niv_com_fkey FOREIGN KEY (id_niv_com) REFERENCES public.nivel_competencia_oral(id_niv_com);


--
-- Name: lenguaje_nna lenguaje_nna_id_niv_escrito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_niv_escrito_fkey FOREIGN KEY (id_niv_escrito) REFERENCES public.nivel_competencia_oral(id_niv_com);


--
-- Name: lenguaje_nna lenguaje_nna_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: lenguaje_nna lenguaje_nna_id_personal_registro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lenguaje_nna
    ADD CONSTRAINT lenguaje_nna_id_personal_registro_fkey FOREIGN KEY (id_personal_registro) REFERENCES public.personal(id);


--
-- Name: nacionalidad_nna nacionalidad_nna_id_nac_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad_nna
    ADD CONSTRAINT nacionalidad_nna_id_nac_fkey FOREIGN KEY (id_nac) REFERENCES public.nacionalidad(id_nac);


--
-- Name: nacionalidad_nna nacionalidad_nna_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nacionalidad_nna
    ADD CONSTRAINT nacionalidad_nna_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: nna_condicion nna_condicion_id_condicion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_condicion
    ADD CONSTRAINT nna_condicion_id_condicion_fkey FOREIGN KEY (id_condicion) REFERENCES public.condicion(id_condicion);


--
-- Name: nna_condicion nna_condicion_id_grado_dep_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_condicion
    ADD CONSTRAINT nna_condicion_id_grado_dep_fkey FOREIGN KEY (id_grado_dep) REFERENCES public.grado_dependencia(id_grado_dep);


--
-- Name: nna_condicion nna_condicion_id_grado_dif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_condicion
    ADD CONSTRAINT nna_condicion_id_grado_dif_fkey FOREIGN KEY (id_grado_dif) REFERENCES public.grado_dificultad(id_grado_dif);


--
-- Name: nna_condicion nna_condicion_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_condicion
    ADD CONSTRAINT nna_condicion_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: nna_enfermedad nna_enfermedad_id_enf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_enfermedad
    ADD CONSTRAINT nna_enfermedad_id_enf_fkey FOREIGN KEY (id_enf) REFERENCES public.enfermedad(id_enf);


--
-- Name: nna_enfermedad nna_enfermedad_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_enfermedad
    ADD CONSTRAINT nna_enfermedad_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: nna nna_id_direccion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direccion(id_direccion);


--
-- Name: nna nna_id_esc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_id_esc_fkey FOREIGN KEY (id_esc) REFERENCES public.escolaridad(id_esc);


--
-- Name: nna nna_id_sexo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_id_sexo_fkey FOREIGN KEY (id_sexo) REFERENCES public.sexo(id_sexo);


--
-- Name: nna nna_lugar_nacimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna
    ADD CONSTRAINT nna_lugar_nacimiento_fkey FOREIGN KEY (lugar_nacimiento) REFERENCES public.entidad_federativa(id_ent);


--
-- Name: nna_tutor nna_tutor_id_nna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_tutor
    ADD CONSTRAINT nna_tutor_id_nna_fkey FOREIGN KEY (id_nna) REFERENCES public.nna(id_nna);


--
-- Name: nna_tutor nna_tutor_id_paren_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_tutor
    ADD CONSTRAINT nna_tutor_id_paren_fkey FOREIGN KEY (id_paren) REFERENCES public.parentesco(id_paren);


--
-- Name: nna_tutor nna_tutor_id_tutor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nna_tutor
    ADD CONSTRAINT nna_tutor_id_tutor_fkey FOREIGN KEY (id_tutor) REFERENCES public.tutor(id_tutor);


--
-- Name: personal personal_id_direccion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direccion(id_direccion);


--
-- Name: personal personal_id_sexo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_id_sexo_fkey FOREIGN KEY (id_sexo) REFERENCES public.sexo(id_sexo);


--
-- Name: personal_lengua personal_lengua_id_len_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_id_len_fkey FOREIGN KEY (id_len) REFERENCES public.lengua(id_len);


--
-- Name: personal_lengua personal_lengua_id_mod_adc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_id_mod_adc_fkey FOREIGN KEY (id_mod_adc) REFERENCES public.modo_adquisicion_lengua(id_mod_adc);


--
-- Name: personal_lengua personal_lengua_id_niv_com_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_id_niv_com_fkey FOREIGN KEY (id_niv_com) REFERENCES public.nivel_competencia_oral(id_niv_com);


--
-- Name: personal_lengua personal_lengua_id_niv_escrito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_id_niv_escrito_fkey FOREIGN KEY (id_niv_escrito) REFERENCES public.nivel_competencia_oral(id_niv_com);


--
-- Name: personal_lengua personal_lengua_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_lengua
    ADD CONSTRAINT personal_lengua_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: personal personal_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- Name: seguimiento seguimiento_id_caso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seguimiento
    ADD CONSTRAINT seguimiento_id_caso_fkey FOREIGN KEY (id_caso) REFERENCES public.caso(id_caso);


--
-- Name: seguimiento seguimiento_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seguimiento
    ADD CONSTRAINT seguimiento_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id);


--
-- Name: subcategoria subcategoria_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria
    ADD CONSTRAINT subcategoria_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);


--
-- Name: tutor_condicion tutor_condicion_id_grado_dep_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor_condicion
    ADD CONSTRAINT tutor_condicion_id_grado_dep_fkey FOREIGN KEY (id_grado_dep) REFERENCES public.grado_dependencia(id_grado_dep);


--
-- Name: tutor_condicion tutor_condicion_id_grado_dif_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor_condicion
    ADD CONSTRAINT tutor_condicion_id_grado_dif_fkey FOREIGN KEY (id_grado_dif) REFERENCES public.grado_dificultad(id_grado_dif);


--
-- Name: tutor tutor_id_direccion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor
    ADD CONSTRAINT tutor_id_direccion_fkey FOREIGN KEY (id_direccion) REFERENCES public.direccion(id_direccion);


--
-- Name: tutor tutor_id_sexo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tutor
    ADD CONSTRAINT tutor_id_sexo_fkey FOREIGN KEY (id_sexo) REFERENCES public.sexo(id_sexo);


--
-- Name: ubicacion_lengua ubicacion_lengua_id_ent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion_lengua
    ADD CONSTRAINT ubicacion_lengua_id_ent_fkey FOREIGN KEY (id_ent) REFERENCES public.entidad_federativa(id_ent);


--
-- Name: ubicacion_lengua ubicacion_lengua_id_len_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion_lengua
    ADD CONSTRAINT ubicacion_lengua_id_len_fkey FOREIGN KEY (id_len) REFERENCES public.lengua(id_len);


--
-- PostgreSQL database dump complete
--

\unrestrict 0hvNdYOO4pGKoF7hhVqDVPcvMyO8e20dM4gK2g1LbXsRGwezPPwdOB6za52Ls7x

