from flask import Flask, render_template, request, redirect, url_for, session, abort, flash
import psycopg2
import re  
import os
from psycopg2.extras import RealDictConnection, RealDictCursor
from functools import wraps

os.environ["PGCLIENTENCODING"] = "UTF8"

app = Flask(__name__)
app.secret_key = 'tu_llave_secreta_super_pro'


def conectar_db():
    return psycopg2.connect(
        host="localhost",
        database="base_normalizada",
        user="postgres",
        password="Diana2005"
    )

# ----------------------------------------------------------------
# FUNCIONES AUXILIARES PARA EL ESQUEMA NORMALIZADO
# ----------------------------------------------------------------

def _primer_valor(fila):
    if fila is None:
        return None
    if isinstance(fila, dict):
        return list(fila.values())[0]
    return fila[0]


def obtener_id_sexo(cur, valor):
    if valor is None or str(valor).strip() == '':
        return None
    valor = str(valor).strip()
    if valor.isdigit():
        return int(valor)
    cur.execute("SELECT id_sexo FROM sexo WHERE nom_sexo ILIKE %s", (valor,))
    return _primer_valor(cur.fetchone())


def obtener_o_crear_asentamiento(cur, municipio, colonia, cp, estado):
    cur.execute("SELECT id_ent FROM entidad_federativa WHERE nom_ent ILIKE %s", (estado,))
    fila = cur.fetchone()
    if fila:
        id_ent = _primer_valor(fila)
    else:
        cur.execute(
            "INSERT INTO entidad_federativa (nom_ent) VALUES (%s) RETURNING id_ent",
            (estado,)
        )
        id_ent = _primer_valor(cur.fetchone())

    cur.execute("""
        SELECT id_asen FROM asentamiento
        WHERE nom_mun ILIKE %s
          AND COALESCE(nom_col, '') ILIKE COALESCE(%s, '')
          AND COALESCE(cp_asen, '') = COALESCE(%s, '')
          AND id_ent = %s
    """, (municipio, colonia, cp, id_ent))
    fila = cur.fetchone()
    if fila:
        return _primer_valor(fila)

    cur.execute("""
        INSERT INTO asentamiento (nom_mun, nom_col, cp_asen, id_ent)
        VALUES (%s, %s, %s, %s) RETURNING id_asen
    """, (municipio, colonia, cp, id_ent))
    return _primer_valor(cur.fetchone())


def crear_direccion(cur, d):
    id_asen = obtener_o_crear_asentamiento(
        cur,
        d.get('municipio'),
        d.get('colonia'),
        d.get('cp'),
        d.get('estado')
    )
    cur.execute("""
        INSERT INTO direccion (calle, numero_ext, numero_int, id_asen)
        VALUES (%s, %s, %s, %s) RETURNING id_direccion
    """, (
        d.get('calle'),
        d.get('numero_ext'),
        d.get('numero_int') if d.get('numero_int') else None,
        id_asen
    ))
    return _primer_valor(cur.fetchone())



QUERY_PERSONAL_COMPLETO = """
    SELECT p.*,
           s.nom_sexo  AS sexo,
           r.nombre_rol AS rol,
           d.calle, d.numero_ext, d.numero_int,
           a.nom_col   AS colonia,
           a.cp_asen   AS cp,
           a.nom_mun   AS municipio,
           e.nom_ent   AS estado
    FROM personal p
    LEFT JOIN sexo s               ON s.id_sexo = p.id_sexo
    LEFT JOIN roles r              ON r.id = p.rol_id
    LEFT JOIN direccion d          ON d.id_direccion = p.id_direccion
    LEFT JOIN asentamiento a       ON a.id_asen = d.id_asen
    LEFT JOIN entidad_federativa e ON e.id_ent = a.id_ent
"""

# ----------------------------------------------------------------
# CONTROL DE ACCESO POR ROL
# ----------------------------------------------------------------

def requiere_coordinador(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'rol' not in session or session['rol'] != 2: 
            flash("Acceso denegado: Solo el Coordinador puede realizar esta acción.", "danger")
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# ----------------------------------------------------------------
# CONTROLADORES: AUTENTICACIÓN Y PERSONAL (EMPLEADOS)
# ----------------------------------------------------------------

@app.route('/')
def index():
    return render_template('login.html')


@app.route('/login', methods=['POST'])
def login():
    correo = request.form['correo']
    password_ingresada = request.form['password1']

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("SELECT * FROM personal WHERE correo = %s", (correo,))
    usuario = cur.fetchone()

    cur.close()
    conn.close()

    if usuario and usuario['password1'] == password_ingresada:
        if usuario['esta_activo']:
            session['usuario_id'] = usuario['id']
            session['nombre'] = usuario['nombre']
            session['Apellido_paterno'] = usuario['apellido_p']
            session['apellido_materno'] = usuario['apellido_m']
            session['rol'] = usuario['rol_id']

            if session['rol'] in [1, 2]:
                return redirect(url_for('dashboard'))
            else:
                return redirect(url_for('home'))
        else:
            return "Tu cuenta no está activa, contacta al director o coordinador."
    else:
        return "Correo o contraseña incorrectos. <a href='/'>Volver a intentar</a>"


@app.route('/registro')
def vista_registro():
    return render_template('registro.html')


@app.route('/dashboard')
def dashboard():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(QUERY_PERSONAL_COMPLETO + " ORDER BY p.id ASC")
    usuarios = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('dashboard.html', personal=usuarios, nombre=session['nombre'])


@app.route('/registrar', methods=['POST'])
def registrar():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    d = request.form
    pass1 = d['password1']
    pass2 = d['confirmar_password']
    rfc = d['rfc'].upper()
    curp = d['curp'].upper()

    if pass1 != pass2:
        flash("Las contraseñas no coinciden", "error")
        return redirect('/dashboard')

    rfc_pattern = r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$'
    if not re.match(rfc_pattern, rfc):
        flash("El formato del RFC es inválido", "error")
        return redirect('/dashboard')

    curp_pattern = r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$'
    if not re.match(curp_pattern, curp):
        flash("El formato de la CURP es inválido", "error")
        return redirect('/dashboard')

    es_emp = True if d['es_empleado'] == '1' else False
    activo = False

    conn = conectar_db()
    cur = conn.cursor()

    try:
        id_direccion = crear_direccion(cur, d)
        id_sexo = obtener_id_sexo(cur, d.get('sexo'))

        query_personal = """
            INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp, correo,
            password1, rol_id, id_sexo, fecha_nacimiento, es_empleado, esta_activo,
            id_direccion)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """
        cur.execute(query_personal, (
            d['nombre'], d['apellido_p'], d['apellido_m'], rfc, curp, d['correo'],
            pass1, d['rol_id'], id_sexo, d['fecha_nacimiento'], es_emp, activo, id_direccion
        ))

        conn.commit()
        flash("Usuario y dirección registrados con éxito", "success")
    except Exception as e:
        conn.rollback()
        print(f"Error en el registro: {e}")
        flash(f"Error al registrar en base de datos: {e}", "error")
    finally:
        cur.close()
        conn.close()

    return redirect('/dashboard')


@app.route('/estado/<int:id>/<string:actual>')
def cambiar_estado(id, actual):
    nuevo_estado = False if actual == 'True' else True
    conn = conectar_db()
    cur = conn.cursor()
    cur.execute("UPDATE personal SET esta_activo = %s WHERE id = %s", (nuevo_estado, id))
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))


@app.route('/eliminar/<int:id>')
def eliminar(id):
    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM personal WHERE id = %s", (id,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"Error al eliminar: {e}")
        flash("No se pudo eliminar: el usuario tiene registros relacionados. Desactívalo.", "error")
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))


@app.route('/consultar/<int:id>')
def consultar_detalle(id):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(QUERY_PERSONAL_COMPLETO + " WHERE p.id = %s", (id,))
    persona = cur.fetchone()
    cur.close()
    conn.close()

    if not persona: return "Usuario no encontrado", 404
    return render_template('consultar.html', p=persona)


@app.route('/editar/<int:id>')
def editar_usuario(id):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(QUERY_PERSONAL_COMPLETO + " WHERE p.id = %s", (id,))
    usuario = cur.fetchone()
    cur.close()
    conn.close()

    return render_template('editar.html', u=usuario)


@app.route('/actualizar', methods=['POST'])
def actualizar():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    d = request.form
    es_emp = True if d.get('es_empleado') == '1' else False

    conn = conectar_db()
    cur = conn.cursor()

    try:
        id_sexo = obtener_id_sexo(cur, d.get('sexo'))
        query_personal = """
            UPDATE personal SET
            nombre=%s, apellido_p=%s, apellido_m=%s, rfc=%s, curp=%s,
            correo=%s, rol_id=%s, id_sexo=%s, fecha_nacimiento=%s, es_empleado=%s
            WHERE id=%s
        """
        cur.execute(query_personal, (
            d['nombre'], d['apellido_p'], d['apellido_m'], d['rfc'],
            d['curp'], d['correo'], d['rol_id'], id_sexo,
            d['fecha_nacimiento'], es_emp, d['id']
        ))

        cur.execute("SELECT id_direccion FROM personal WHERE id = %s", (d['id'],))
        id_direccion_actual = _primer_valor(cur.fetchone())

        if id_direccion_actual:
            id_asen = obtener_o_crear_asentamiento(
                cur, d.get('municipio'), d.get('colonia'), d.get('cp'), d.get('estado')
            )
            cur.execute("""
                UPDATE direccion SET calle=%s, numero_ext=%s, numero_int=%s, id_asen=%s
                WHERE id_direccion=%s
            """, (d['calle'], d['numero_ext'], d['numero_int'] if d.get('numero_int') else None, id_asen, id_direccion_actual))
        else:
            nueva_dir = crear_direccion(cur, d)
            cur.execute("UPDATE personal SET id_direccion = %s WHERE id = %s", (nueva_dir, d['id']))

        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"Error al actualizar: {e}")

    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


@app.route('/home') 
def home():
    if 'usuario_id' not in session: 
        return redirect(url_for('index'))
    
    id_personal = session['usuario_id']
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        query_usuario = """
            SELECT p.*, r.nombre_rol 
            FROM personal p 
            LEFT JOIN roles r ON p.rol_id = r.id 
            WHERE p.id = %s AND p.esta_activo = TRUE
        """
        cur.execute(query_usuario, (id_personal,))
        usuario = cur.fetchone()
        
        if not usuario:
            return "Usuario no encontrado o inactivo", 404
            
        query_casos = """
            SELECT 
                c.id_caso,
                c.folio_caso,
                ec.nom_est_caso AS prioridad,
                CONCAT(n.nombre, ' ', COALESCE(n.apellido_p, ''), ' ', COALESCE(n.apellido_m, '')) AS nombre_nna,
                COALESCE(TO_CHAR(MAX(s.fecha_seg), 'DD/MM/YYYY'), TO_CHAR(c.fecha_aper, 'DD/MM/YYYY')) AS fecha_ultima_visita
            FROM asignacion_caso ac
            JOIN caso c ON ac.id_caso = c.id_caso
            JOIN estatus_caso ec ON c.id_est_caso = ec.id_est_caso
            LEFT JOIN caso_nna cn ON c.id_caso = cn.id_caso
            LEFT JOIN nna n ON cn.id_nna = n.id_nna
            LEFT JOIN seguimiento s ON c.id_caso = s.id_caso
            WHERE ac.id_personal = %s AND ac.fecha_fin IS NULL
            GROUP BY c.id_caso, c.folio_caso, ec.nom_est_caso, n.nombre, n.apellido_p, n.apellido_m, c.fecha_aper
            ORDER BY c.fecha_aper DESC;
        """
        cur.execute(query_casos, (id_personal,))
        casos_asignados = cur.fetchall()

        query_consultas = """
            SELECT 
                c.id_consul,
                tc.nom_tipo_consul AS tipo,
                CONCAT(n.nombre, ' ', COALESCE(n.apellido_p, ''), ' ', COALESCE(n.apellido_m, '')) AS nombre_nna,
                TO_CHAR(c.fecha_consul, 'DD/MM/YYYY HH24:MI') AS fecha_consulta,
                c.motivo
            FROM consulta c
            JOIN tipo_consulta tc ON c.id_tipo_consul = tc.id_tipo_consul
            JOIN nna n ON c.id_nna = n.id_nna
            WHERE c.id_personal = %s
            ORDER BY c.fecha_consul DESC;
        """
        cur.execute(query_consultas, (id_personal,))
        consultas_asignadas = cur.fetchall()
        
    except Exception as e:
        print(f"Error en la carga del Dashboard General: {e}")
        casos_asignados = []
        consultas_asignadas = []
        usuario = None
    finally:
        cur.close()
        conn.close()
        
    if not usuario:
        return "Error interno del servidor", 500
        
    return render_template('home.html', p=usuario, casos=casos_asignados, consultas=consultas_asignadas)

# ----------------------------------------------------------------
# MÓDULO 2 (NNA) Y MÓDULO 3 (TUTORES)
# ----------------------------------------------------------------

@app.route('/nna')
def listar_nna():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT n.*, s.nom_sexo AS sexo, esc.nom_esc AS escolaridad,
               CASE
                 WHEN EXISTS (SELECT 1 FROM caso_nna cn
                              JOIN caso c          ON c.id_caso = cn.id_caso
                              JOIN estatus_caso ec ON ec.id_est_caso = c.id_est_caso
                              WHERE cn.id_nna = n.id_nna
                                AND ec.nom_est_caso <> 'Cerrado')
                      THEN 'EN ATENCION'
                 WHEN EXISTS (SELECT 1 FROM caso_nna cn WHERE cn.id_nna = n.id_nna)
                      THEN 'ATENDIDO'
                 ELSE 'REGISTRADO (SIN CASO)'
               END AS estatus_atencion
        FROM nna n
        LEFT JOIN sexo s ON s.id_sexo = n.id_sexo
        LEFT JOIN escolaridad esc ON esc.id_esc = n.id_esc
        ORDER BY n.id_nna DESC
    """)
    niños = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('nna_listado.html', niños=niños)

@app.route('/nna/registrar', methods=['GET', 'POST'])
@requiere_coordinador
def registrar_nna():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            id_dir = crear_direccion(cur, d)

            curp = (d.get('curp') or '').strip().upper() or None

            cur.execute("""
                INSERT INTO nna (nombre, apellido_p, apellido_m, curp,
                                 fecha_nacimiento, lugar_nacimiento, id_sexo,
                                 id_esc, id_direccion)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id_nna
            """, (
                d['nombre'], d['apellido_p'], d['apellido_m'], curp,
                d['fecha_nacimiento'] or None,
                d['lugar_nacimiento'] or None,
                d['id_sexo'] or None,
                d['id_esc'] or None,
                id_dir
            ))
            id_nna = _primer_valor(cur.fetchone())

            folio = d.get('folio_nna', '').strip() or f"NNA-{id_nna:05d}"
            cur.execute("UPDATE nna SET folio_nna = %s WHERE id_nna = %s",
                        (folio[:10], id_nna))

            # --- MÚLTIPLES LENGUAS CON PREFERENTE, MODO Y NIVELES ---
            # El formulario manda una lista de id_len (lenguas elegidas),
            # un id preferente (radio), y por CADA lengua sus atributos
            # nombrados con el id: modo_<id>, oral_<id>, escrito_<id>.
            lenguas_elegidas = request.form.getlist('lenguas')   # lista de ids
            len_preferente = d.get('lengua_preferente')          # un solo id (o None)

            for id_len in lenguas_elegidas:
                es_pref = (str(id_len) == str(len_preferente))
                # Atributos específicos de esta lengua (pueden venir vacíos)
                id_mod    = d.get(f'modo_{id_len}') or None
                id_oral   = d.get(f'oral_{id_len}') or None
                id_escrito = d.get(f'escrito_{id_len}') or None
                cur.execute("""
                    INSERT INTO lenguaje_nna
                        (id_nna, id_len, preferente, id_mod_adc, id_niv_com, id_niv_escrito)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (id_nna, id_len) DO UPDATE SET
                        preferente = EXCLUDED.preferente,
                        id_mod_adc = EXCLUDED.id_mod_adc,
                        id_niv_com = EXCLUDED.id_niv_com,
                        id_niv_escrito = EXCLUDED.id_niv_escrito
                """, (id_nna, id_len, es_pref, id_mod, id_oral, id_escrito))

            # --- MÚLTIPLES DISCAPACIDADES CON GRADO POR NNA ---
            # Por cada discapacidad elegida, el usuario captura su
            # grado de dificultad y dependencia PARA ESE NIÑO. Los
            # campos vienen nombrados con el id: gradodif_<id>,
            # gradodep_<id>. El grado es un atributo de la relación
            # (NNA, condición), por eso vive en nna_condicion.
            for id_cond in request.form.getlist('condiciones'):
                id_gdif = d.get(f'gradodif_{id_cond}') or None
                id_gdep = d.get(f'gradodep_{id_cond}') or None
                cur.execute("""
                    INSERT INTO nna_condicion (id_nna, id_condicion, id_grado_dif, id_grado_dep)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (id_nna, id_condicion) DO UPDATE SET
                        id_grado_dif = EXCLUDED.id_grado_dif,
                        id_grado_dep = EXCLUDED.id_grado_dep
                """, (id_nna, id_cond, id_gdif, id_gdep))

            conn.commit()
            flash(f"Menor protegido registrado exitosamente. Folio: {folio[:10]}", "success")
            return redirect(url_for('listar_nna'))
        except Exception as e:
            conn.rollback()
            print(f"Error al registrar NNA: {e}")
            flash(f"Error operativo: {e}", "error")
            return redirect('/dashboard')
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT id_sexo, nom_sexo FROM sexo")
    sexos = cur.fetchall()
    cur.execute("SELECT id_esc, nom_esc FROM escolaridad")
    escolaridades = cur.fetchall()
    # Traemos TODOS los campos de la lengua para mostrarlos en la pantalla
    cur.execute("""
        SELECT id_len, variante_len, familia_len, agrupacion_len, autodenom_len
        FROM lengua ORDER BY variante_len
    """)
    lenguas = cur.fetchall()
    # Datos para la cascada Categoría -> Subcategoría -> Condición
    cur.execute("SELECT id_categoria, nombre FROM categoria ORDER BY nombre")
    categorias = cur.fetchall()
    cur.execute("SELECT id_subcategoria, nombre, id_categoria FROM subcategoria ORDER BY nombre")
    subcategorias = cur.fetchall()
    cur.execute("""
        SELECT id_condicion, nombre, codigo_cif, id_subcategoria
        FROM condicion ORDER BY nombre
    """)
    condiciones = cur.fetchall()
    # Catálogos de grados (los elige el usuario por cada NNA)
    cur.execute("""
        SELECT id_grado_dif, nom_grado_dif, codigo_cif_dif,
               desc_cualitativa, rango_porcent
        FROM grado_dificultad ORDER BY codigo_cif_dif
    """)
    grados_dif = cur.fetchall()
    cur.execute("SELECT id_grado_dep, nom_grado_dep FROM grado_dependencia ORDER BY id_grado_dep")
    grados_dep = cur.fetchall()

    cur.execute("SELECT id_ent, nom_ent FROM entidad_federativa ORDER BY nom_ent")
    entidades = cur.fetchall()
    # Catálogos para los atributos de cada lengua (INALI)
    cur.execute("SELECT id_mod_adc, categ_mod_adc FROM modo_adquisicion_lengua ORDER BY id_mod_adc")
    modos_adquisicion = cur.fetchall()
    cur.execute("SELECT id_niv_com, niv_prac_com FROM nivel_competencia_oral ORDER BY id_niv_com")
    niveles_competencia = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('nna_registro.html', sexos=sexos,
                           escolaridades=escolaridades, lenguas=lenguas,
                           entidades=entidades,
                           modos_adquisicion=modos_adquisicion,
                           niveles_competencia=niveles_competencia,
                           categorias=categorias, subcategorias=subcategorias,
                           condiciones=condiciones,
                           grados_dif=grados_dif, grados_dep=grados_dep)

@app.route('/nna/detalle/<int:id_nna>')
def detalle_nna(id_nna):
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    query = """
        SELECT nna.*, 
               s.nom_sexo AS sexo,
               e.nom_esc AS escolaridad_nombre,
               d.calle, d.numero_ext, d.numero_int, d.referencias,
               a.nom_mun AS municipio, a.nom_col AS colonia, a.cp_asen AS cp,
               ent.nom_ent AS estado,
               ent_nac.nom_ent AS lugar_nacimiento_nombre,
               c.nombre AS condicion_nombre,
               t.nombre AS tutor_nombre,
               t.apellido_p AS tutor_apellido_p,
               t.apellido_m AS tutor_apellido_m,
               t.ocupacion AS tutor_ocupacion,
               t.curp AS tutor_curp,
               p.nom_paren AS tutor_parentesco,
               nt.tutor_legal AS es_tutor_legal
        FROM nna nna
        LEFT JOIN sexo s ON nna.id_sexo = s.id_sexo
        LEFT JOIN escolaridad e ON nna.id_esc = e.id_esc
        LEFT JOIN direccion d ON nna.id_direccion = d.id_direccion
        LEFT JOIN asentamiento a ON d.id_asen = a.id_asen
        LEFT JOIN entidad_federativa ent ON a.id_ent = ent.id_ent
        LEFT JOIN entidad_federativa ent_nac ON nna.lugar_nacimiento = ent_nac.id_ent
        LEFT JOIN nna_condicion nc ON nna.id_nna = nc.id_nna
        LEFT JOIN condicion c ON nc.id_condicion = c.id_condicion
        LEFT JOIN nna_tutor nt ON nna.id_nna = nt.id_nna
        LEFT JOIN tutor t ON nt.id_tutor = t.id_tutor
        LEFT JOIN parentesco p ON nt.id_paren = p.id_paren
        WHERE nna.id_nna = %s
    """
    cur.execute(query, (id_nna,))
    nna = cur.fetchone()

    # Traemos TODAS las lenguas del NNA (puede tener varias)
    cur.execute("""
        SELECT l.variante_len, l.familia_len, l.autodenom_len, ln.preferente
        FROM lenguaje_nna ln
        JOIN lengua l ON l.id_len = ln.id_len
        WHERE ln.id_nna = %s
        ORDER BY ln.preferente DESC, l.variante_len
    """, (id_nna,))
    lenguas_nna = cur.fetchall()

    cur.close()
    conn.close()
    
    return render_template('detalle_nna.html', nna=nna, lenguas_nna=lenguas_nna)

@app.route('/tutor/registrar', methods=['GET', 'POST'])
def registrar_tutor():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            id_dir = crear_direccion(cur, d)
            curp = (d.get('curp') or '').strip().upper() or None

            cur.execute("""
                INSERT INTO tutor (nombre, apellido_p, apellido_m, curp, fecha_nacimiento,
                                   id_sexo, ocupacion, id_direccion)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id_tutor
            """, (
                d['nombre'], d['apellido_p'], d['apellido_m'], curp,
                d['fecha_nacimiento'] or None, d['id_sexo'] or None,
                d.get('ocupacion') or None, id_dir
            ))
            id_tutor = _primer_valor(cur.fetchone())

            tutor_legal = d.get('tutor_legal') in ('1', 'on', 'true', 'True')
            cur.execute("""
                INSERT INTO nna_tutor (id_nna, id_tutor, id_paren, tutor_legal)
                VALUES (%s, %s, %s, %s)
            """, (d['id_nna'], id_tutor, d.get('id_paren') or None, tutor_legal))

            # --- LENGUAS DEL TUTOR (igual que el NNA) ---
            lenguas_elegidas = request.form.getlist('lenguas')
            len_preferente = d.get('lengua_preferente')
            for id_len in lenguas_elegidas:
                es_pref = (str(id_len) == str(len_preferente))
                id_mod    = d.get(f'modo_{id_len}') or None
                id_oral   = d.get(f'oral_{id_len}') or None
                id_escrito = d.get(f'escrito_{id_len}') or None
                cur.execute("""
                    INSERT INTO lenguaje_tutor
                        (id_tutor, id_len, preferente, id_mod_adc, id_niv_com, id_niv_escrito)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (id_tutor, id_len) DO UPDATE SET
                        preferente = EXCLUDED.preferente,
                        id_mod_adc = EXCLUDED.id_mod_adc,
                        id_niv_com = EXCLUDED.id_niv_com,
                        id_niv_escrito = EXCLUDED.id_niv_escrito
                """, (id_tutor, id_len, es_pref, id_mod, id_oral, id_escrito))

            # --- DISCAPACIDADES DEL TUTOR (cascada con grados, igual que NNA) ---
            for id_cond in request.form.getlist('condiciones'):
                id_gdif = d.get(f'gradodif_{id_cond}') or None
                id_gdep = d.get(f'gradodep_{id_cond}') or None
                cur.execute("""
                    INSERT INTO tutor_condicion (id_tutor, id_condicion, id_grado_dif, id_grado_dep)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (id_tutor, id_condicion) DO UPDATE SET
                        id_grado_dif = EXCLUDED.id_grado_dif,
                        id_grado_dep = EXCLUDED.id_grado_dep
                """, (id_tutor, id_cond, id_gdif, id_gdep))

            conn.commit()
            flash("Tutor registrado y vinculado correctamente.", "success")
            return redirect(url_for('dashboard'))
        except Exception as e:
            conn.rollback()
            print(f"Error al registrar Tutor: {e}")
            flash(f"Error en la vinculación: {e}", "error")
            return redirect('/dashboard')
        finally:
            cur.close()
            conn.close()

    cur.execute("SELECT id_nna, folio_nna, nombre, apellido_p FROM nna ORDER BY nombre")
    niños = cur.fetchall()
    cur.execute("SELECT id_paren, nom_paren FROM parentesco")
    parentescos = cur.fetchall()
    cur.execute("SELECT id_sexo, nom_sexo FROM sexo")
    sexos = cur.fetchall()

    # Catálogos de LENGUA (igual que en el registro de NNA)
    cur.execute("""
        SELECT id_len, variante_len, familia_len, agrupacion_len, autodenom_len
        FROM lengua ORDER BY variante_len
    """)
    lenguas = cur.fetchall()
    cur.execute("SELECT id_mod_adc, categ_mod_adc FROM modo_adquisicion_lengua ORDER BY id_mod_adc")
    modos_adquisicion = cur.fetchall()
    cur.execute("SELECT id_niv_com, niv_prac_com FROM nivel_competencia_oral ORDER BY id_niv_com")
    niveles_competencia = cur.fetchall()

    # Catálogos de DISCAPACIDAD (cascada, igual que en NNA)
    cur.execute("SELECT id_categoria, nombre FROM categoria ORDER BY nombre")
    categorias = cur.fetchall()
    cur.execute("SELECT id_subcategoria, nombre, id_categoria FROM subcategoria ORDER BY nombre")
    subcategorias = cur.fetchall()
    cur.execute("SELECT id_condicion, nombre, codigo_cif, id_subcategoria FROM condicion ORDER BY nombre")
    condiciones = cur.fetchall()
    cur.execute("""
        SELECT id_grado_dif, nom_grado_dif, codigo_cif_dif, desc_cualitativa, rango_porcent
        FROM grado_dificultad ORDER BY codigo_cif_dif
    """)
    grados_dif = cur.fetchall()
    cur.execute("SELECT id_grado_dep, nom_grado_dep FROM grado_dependencia ORDER BY id_grado_dep")
    grados_dep = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('tutor_registro.html', niños=niños, parentescos=parentescos, sexos=sexos,
                           lenguas=lenguas, modos_adquisicion=modos_adquisicion,
                           niveles_competencia=niveles_competencia,
                           categorias=categorias, subcategorias=subcategorias,
                           condiciones=condiciones, grados_dif=grados_dif, grados_dep=grados_dep)


# ----------------------------------------------------------------
# MÓDULO 4: CASOS
# ----------------------------------------------------------------

@app.route('/casos')
def listar_casos():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT c.*, ec.nom_est_caso AS estatus,
               eq.nom_equipo,
               (SELECT string_agg(n.nombre || ' ' || COALESCE(n.apellido_p, ''), ', ')
                  FROM caso_nna cn JOIN nna n ON n.id_nna = cn.id_nna
                 WHERE cn.id_caso = c.id_caso) AS nna_nombres,
               (SELECT COUNT(*) FROM caso_derecho cd
                 WHERE cd.id_caso = c.id_caso AND cd.restituido = FALSE) AS derechos_pendientes,
               (SELECT COUNT(*) FROM seguimiento sg
                 WHERE sg.id_caso = c.id_caso) AS num_seguimientos
        FROM caso c
        JOIN estatus_caso ec ON ec.id_est_caso = c.id_est_caso
        LEFT JOIN equipo_multidisciplinario eq ON eq.id_equipo = c.id_equipo
        ORDER BY c.id_caso DESC
    """)
    casos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('casos_listado.html', casos=casos, nombre=session['nombre'])


@app.route('/casos/registrar', methods=['GET', 'POST'])
def registrar_caso():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            cur.execute("SELECT id_est_caso FROM estatus_caso WHERE nom_est_caso = 'Deteccion'")
            id_est = _primer_valor(cur.fetchone())

            cur.execute("""
                INSERT INTO caso (folio_caso, nom_caso, narracion, id_est_caso, id_equipo)
                VALUES ('TEMP', %s, %s, %s, %s)
                RETURNING id_caso
            """, (d['nom_caso'], d.get('narracion') or None, id_est,
                  d.get('id_equipo') or None))
            id_caso = _primer_valor(cur.fetchone())

            folio = f"CASO-{id_caso:06d}"
            cur.execute("UPDATE caso SET folio_caso = %s WHERE id_caso = %s",
                        (folio, id_caso))

            cur.execute("""
                INSERT INTO caso_nna (id_caso, id_nna) VALUES (%s, %s)
            """, (id_caso, d['id_nna']))

            for id_der in request.form.getlist('derechos'):
                cur.execute("""
                    INSERT INTO caso_derecho (id_caso, id_nna, id_der)
                    VALUES (%s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (id_caso, d['id_nna'], id_der))

            cur.execute("SELECT rol_id FROM personal WHERE id = %s", (session['usuario_id'],))
            rol_usuario = _primer_valor(cur.fetchone())
            cur.execute("""
                INSERT INTO asignacion_caso (id_caso, id_personal, rol_id)
                VALUES (%s, %s, %s)
            """, (id_caso, session['usuario_id'], rol_usuario))

            conn.commit()
            flash(f"Caso abierto con éxito. Folio: {folio}", "success")
            return redirect(url_for('detalle_caso', id_caso=id_caso))
        except Exception as e:
            conn.rollback()
            print(f"Error al abrir caso: {e}")
            flash(f"Error al abrir el caso: {e}", "error")
            return redirect(url_for('listar_casos'))
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT id_nna, folio_nna, nombre, apellido_p, apellido_m
        FROM nna ORDER BY nombre, apellido_p
    """)
    nna_lista = cur.fetchall()
    cur.execute("SELECT id_der, nom_der FROM derecho ORDER BY id_der")
    derechos = cur.fetchall()
    cur.execute("SELECT id_equipo, nom_equipo FROM equipo_multidisciplinario ORDER BY nom_equipo")
    equipos = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('caso_registro.html', nna_lista=nna_lista,
                           derechos=derechos, equipos=equipos)


@app.route('/caso/<int:id_caso>')
def detalle_caso(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("""
        SELECT c.*, ec.nom_est_caso AS estatus, eq.nom_equipo
        FROM caso c
        JOIN estatus_caso ec ON ec.id_est_caso = c.id_est_caso
        LEFT JOIN equipo_multidisciplinario eq ON eq.id_equipo = c.id_equipo
        WHERE c.id_caso = %s
    """, (id_caso,))
    caso = cur.fetchone()
    if not caso:
        cur.close(); conn.close()
        return "Caso no encontrado", 404

    cur.execute("""
        SELECT n.id_nna, n.folio_nna, n.nombre, n.apellido_p, n.apellido_m,
               n.fecha_nacimiento, s.nom_sexo AS sexo, cn.fecha_incorp
        FROM caso_nna cn
        JOIN nna n ON n.id_nna = cn.id_nna
        LEFT JOIN sexo s ON s.id_sexo = n.id_sexo
        WHERE cn.id_caso = %s
        ORDER BY cn.fecha_incorp
    """, (id_caso,))
    nna_caso = cur.fetchall()

    cur.execute("""
        SELECT cd.*, der.nom_der, n.nombre AS nna_nombre, n.apellido_p AS nna_apellido
        FROM caso_derecho cd
        JOIN derecho der ON der.id_der = cd.id_der
        JOIN nna n ON n.id_nna = cd.id_nna
        WHERE cd.id_caso = %s
        ORDER BY cd.restituido, cd.fecha_detec
    """, (id_caso,))
    derechos_caso = cur.fetchall()

    cur.execute("""
        SELECT ac.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM asignacion_caso ac
        JOIN personal p ON p.id = ac.id_personal
        JOIN roles r    ON r.id = ac.rol_id
        WHERE ac.id_caso = %s AND ac.fecha_fin IS NULL
        ORDER BY ac.fecha_asig
    """, (id_caso,))
    asignados = cur.fetchall()

    cur.execute("""
        SELECT sg.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM seguimiento sg
        JOIN personal p ON p.id = sg.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE sg.id_caso = %s
        ORDER BY sg.fecha_seg DESC, sg.id_seg DESC
    """, (id_caso,))
    seguimientos = cur.fetchall()

    cur.execute("""
        SELECT id_nna, folio_nna, nombre, apellido_p FROM nna
        WHERE id_nna NOT IN (SELECT id_nna FROM caso_nna WHERE id_caso = %s)
        ORDER BY nombre
    """, (id_caso,))
    nna_disponibles = cur.fetchall()
    cur.execute("SELECT id_der, nom_der FROM derecho ORDER BY id_der")
    derechos_catalogo = cur.fetchall()
    cur.execute("""
        SELECT p.id, p.nombre, p.apellido_p, p.rol_id, r.nombre_rol
        FROM personal p JOIN roles r ON r.id = p.rol_id
        WHERE p.esta_activo = TRUE
        ORDER BY p.nombre
    """)
    personal_activo = cur.fetchall()
    cur.execute("SELECT * FROM estatus_caso ORDER BY id_est_caso")
    estatus_lista = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('caso_detalle.html',
                           caso=caso, nna_caso=nna_caso,
                           derechos_caso=derechos_caso, asignados=asignados,
                           seguimientos=seguimientos,
                           nna_disponibles=nna_disponibles,
                           derechos_catalogo=derechos_catalogo,
                           personal_activo=personal_activo,
                           estatus_lista=estatus_lista)


@app.route('/caso/<int:id_caso>/agregar_nna', methods=['POST'])
def caso_agregar_nna(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO caso_nna (id_caso, id_nna) VALUES (%s, %s)",
                    (id_caso, request.form['id_nna']))
        conn.commit()
        flash("NNA agregado al caso", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al agregar NNA: {e}", "error")
    finally:
        cur.close(); conn.close()
    return redirect(url_for('detalle_caso', id_caso=id_caso))


@app.route('/caso/<int:id_caso>/derecho', methods=['POST'])
def caso_registrar_derecho(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO caso_derecho (id_caso, id_nna, id_der)
            VALUES (%s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (id_caso, request.form['id_nna'], request.form['id_der']))
        conn.commit()
        flash("Derecho vulnerado registrado en el caso", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al registrar derecho: {e}", "error")
    finally:
        cur.close(); conn.close()
    return redirect(url_for('detalle_caso', id_caso=id_caso))


@app.route('/caso/<int:id_caso>/restituir/<int:id_nna>/<int:id_der>')
def caso_restituir_derecho(id_caso, id_nna, id_der):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE caso_derecho
        SET restituido = TRUE, fecha_rest = CURRENT_DATE
        WHERE id_caso = %s AND id_nna = %s AND id_der = %s
    """, (id_caso, id_nna, id_der))
    conn.commit()
    cur.close(); conn.close()
    flash("Derecho marcado como restituido", "success")
    return redirect(url_for('detalle_caso', id_caso=id_caso))


@app.route('/caso/<int:id_caso>/asignar', methods=['POST'])
def caso_asignar_personal(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    try:
        id_personal = request.form['id_personal']
        cur.execute("SELECT rol_id FROM personal WHERE id = %s", (id_personal,))
        rol_id = _primer_valor(cur.fetchone())
        cur.execute("""
            INSERT INTO asignacion_caso (id_caso, id_personal, rol_id)
            VALUES (%s, %s, %s)
        """, (id_caso, id_personal, rol_id))
        conn.commit()
        flash("Personal asignado al caso", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al asignar (¿ya estaba asignado hoy?): {e}", "error")
    finally:
        cur.close(); conn.close()
    return redirect(url_for('detalle_caso', id_caso=id_caso))


@app.route('/caso/<int:id_caso>/seguimiento', methods=['POST'])
def caso_agregar_seguimiento(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO seguimiento (id_caso, id_personal, descripcion)
            VALUES (%s, %s, %s)
        """, (id_caso, session['usuario_id'], request.form['descripcion']))
        conn.commit()
        flash("Seguimiento registrado", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al registrar seguimiento: {e}", "error")
    finally:
        cur.close(); conn.close()
    return redirect(url_for('detalle_caso', id_caso=id_caso))


@app.route('/caso/<int:id_caso>/estatus', methods=['POST'])
def caso_cambiar_estatus(id_caso):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor()
    try:
        id_est = request.form['id_est_caso']
        cur.execute("SELECT nom_est_caso FROM estatus_caso WHERE id_est_caso = %s", (id_est,))
        nom_est = _primer_valor(cur.fetchone())

        if nom_est == 'Cerrado':
            cur.execute("""
                UPDATE caso SET id_est_caso = %s, fecha_cierre = CURRENT_DATE
                WHERE id_caso = %s
            """, (id_est, id_caso))
        else:
            cur.execute("""
                UPDATE caso SET id_est_caso = %s, fecha_cierre = NULL
                WHERE id_caso = %s
            """, (id_est, id_caso))
        conn.commit()
        flash(f"Estatus del caso actualizado a: {nom_est}", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al cambiar estatus: {e}", "error")
    finally:
        cur.close(); conn.close()
    return redirect(url_for('detalle_caso', id_caso=id_caso))


# ----------------------------------------------------------------
# PANTALLAS COMPLEMENTARIAS
# ----------------------------------------------------------------

@app.route('/pantalla_personas')
def pantalla_personas():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    return render_template('personas.html')


@app.route('/pantalla_discapacidades')
def pantalla_discapacidades():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    return render_template('discapacidades.html')


@app.route('/pantalla_agregar_persona')
def pantalla_agregar_persona():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    return render_template('agregar_persona.html')


@app.route('/pantalla_asignar_discapacidad')
def pantalla_asignar_discapacidad():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    return render_template('asignar_discapacidad.html')

# ================================================================
# MÓDULO 5: CATÁLOGOS
# ================================================================
CATALOGOS = {
    'sexo':           {'tabla': 'sexo',           'id': 'id_sexo',      'campos': [('nom_sexo', 'Nombre')], 'titulo': 'Sexo'},
    'nacionalidad':   {'tabla': 'nacionalidad',   'id': 'id_nac',       'campos': [('nom_nac', 'Nacionalidad')], 'titulo': 'Nacionalidades'},
    'escolaridad':    {'tabla': 'escolaridad',    'id': 'id_esc',       'campos': [('nom_esc', 'Nivel')], 'titulo': 'Escolaridad'},
    'parentesco':     {'tabla': 'parentesco',     'id': 'id_paren',     'campos': [('nom_paren', 'Parentesco')], 'titulo': 'Parentesco'},
    'tipo_contacto':  {'tabla': 'tipo_contacto',  'id': 'id_tipo_con',  'campos': [('nom_tipo_con', 'Tipo de contacto')], 'titulo': 'Tipos de contacto'},
    'derecho':        {'tabla': 'derecho',        'id': 'id_der',       'campos': [('nom_der', 'Derecho')], 'titulo': 'Derechos (LGDNNA)'},
    'tipo_consulta':  {'tabla': 'tipo_consulta',  'id': 'id_tipo_consul', 'campos': [('nom_tipo_consul', 'Tipo de consulta')], 'titulo': 'Tipos de consulta'},
    'metodo_pago':    {'tabla': 'metodo_pago',    'id': 'id_met_pago',  'campos': [('nom_met_pago', 'Método de pago')], 'titulo': 'Métodos de pago'},
    'enfermedad':     {'tabla': 'enfermedad',     'id': 'id_enf',       'campos': [('nombre', 'Enfermedad'), ('codigo_cie', 'Código CIE')], 'titulo': 'Enfermedades'},
    'lengua':         {'tabla': 'lengua',         'id': 'id_len',       'campos': [('variante_len', 'Variante'), ('familia_len', 'Familia'), ('agrupacion_len', 'Agrupación'), ('autodenom_len', 'Autodenominación')], 'titulo': 'Lenguas'},
}


@app.route('/catalogos')
@app.route('/catalogos/<cat>')
def administrar_catalogos(cat=None):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    if cat is None or cat not in CATALOGOS:
        cat = 'derecho'

    conf = CATALOGOS[cat]
    columnas = conf['id'] + ', ' + ', '.join(c[0] for c in conf['campos'])

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(f"SELECT {columnas} FROM {conf['tabla']} ORDER BY {conf['id']}")
    filas = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('catalogos.html',
                           catalogos=CATALOGOS,
                           cat_actual=cat,
                           conf=conf,
                           filas=filas,
                           nombre=session.get('nombre', 'Usuario'))


@app.route('/catalogos/<cat>/agregar', methods=['POST'])
def agregar_valor_catalogo(cat):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    if cat not in CATALOGOS:
        flash("Catálogo no válido", "error")
        return redirect(url_for('administrar_catalogos'))

    conf = CATALOGOS[cat]
    cols = [c[0] for c in conf['campos']]
    valores = [request.form.get(c) or None for c in cols]

    placeholders = ', '.join(['%s'] * len(cols))
    columnas_sql = ', '.join(cols)

    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute(
            f"INSERT INTO {conf['tabla']} ({columnas_sql}) VALUES ({placeholders})",
            valores
        )
        conn.commit()
        flash(f"Valor agregado al catálogo: {conf['titulo']}", "success")
    except Exception as e:
        conn.rollback()
        print(f"Error al agregar a catálogo: {e}")
        flash(f"Error (¿valor duplicado?): {e}", "error")
    finally:
        cur.close()
        conn.close()

    return redirect(url_for('administrar_catalogos', cat=cat))

# ----------------------------------------------------------------
# MÓDULO 6: CONSULTAS
# ----------------------------------------------------------------

@app.route('/consultas')
def listar_consultas():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT c.*,
               tc.nom_tipo_consul AS tipo,
               n.folio_nna, n.nombre AS nna_nombre, n.apellido_p AS nna_apellido,
               p.nombre AS prof_nombre, p.apellido_p AS prof_apellido,
               r.nombre_rol AS prof_rol
        FROM consulta c
        JOIN tipo_consulta tc ON tc.id_tipo_consul = c.id_tipo_consul
        JOIN nna n            ON n.id_nna = c.id_nna
        JOIN personal p       ON p.id = c.id_personal
        LEFT JOIN roles r     ON r.id = p.rol_id
        ORDER BY c.fecha_consul DESC
    """)
    consultas = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('consultas_listado.html',
                           consultas=consultas, nombre=session['nombre'])


@app.route('/consultas/registrar', methods=['GET', 'POST'])
def registrar_consulta():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            cur.execute("""
                INSERT INTO consulta (id_nna, id_personal, id_tipo_consul, motivo, notas)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                d['id_nna'], d['id_personal'], d['id_tipo_consul'],
                d.get('motivo') or None, d.get('notas') or None
            ))
            conn.commit()
            flash("Consulta registrada con éxito", "success")
            return redirect(url_for('listar_consultas'))
        except Exception as e:
            conn.rollback()
            print(f"Error al registrar consulta: {e}")
            flash(f"Error al registrar consulta: {e}", "error")
            return redirect('/consultas/registrar')
        finally:
            cur.close()
            conn.close()

    cur.execute("""
        SELECT id_nna, folio_nna, nombre, apellido_p, apellido_m
        FROM nna ORDER BY nombre, apellido_p
    """)
    nna_lista = cur.fetchall()
    cur.execute("SELECT id_tipo_consul, nom_tipo_consul FROM tipo_consulta ORDER BY id_tipo_consul")
    tipos = cur.fetchall()
    cur.execute("""
        SELECT p.id, p.nombre, p.apellido_p, r.nombre_rol
        FROM personal p JOIN roles r ON r.id = p.rol_id
        WHERE p.esta_activo = TRUE
          AND r.nombre_rol IN ('Doctor','Psicologo','Abogado','Trabajador Social')
        ORDER BY p.nombre
    """)
    profesionales = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('consulta_registro.html',
                           nna_lista=nna_lista, tipos=tipos,
                           profesionales=profesionales)

# ----------------------------------------------------------------
# MÓDULO 8: EQUIPOS MULTIDISCIPLINARIOS
# ----------------------------------------------------------------

@app.route('/equipos')
def listar_equipos():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT e.*,
               (SELECT COUNT(*) FROM equipo_miembro em
                 WHERE em.id_equipo = e.id_equipo AND em.fecha_baja IS NULL) AS num_activos,
               (SELECT COUNT(*) FROM caso c
                 WHERE c.id_equipo = e.id_equipo) AS num_casos
        FROM equipo_multidisciplinario e
        ORDER BY e.id_equipo ASC
    """)
    equipos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('equipos_listado.html', equipos=equipos, nombre=session['nombre'])


@app.route('/equipos/crear', methods=['POST'])
def crear_equipo():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    nombre_equipo = request.form.get('nom_equipo', '').strip()

    if not nombre_equipo:
        flash("El nombre del equipo no puede estar vacío", "error")
        return redirect('/equipos')

    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO equipo_multidisciplinario (nom_equipo) VALUES (%s)",
            (nombre_equipo,)
        )
        conn.commit()
        flash(f"Equipo '{nombre_equipo}' creado con éxito", "success")
    except Exception as e:
        conn.rollback()
        print(f"Error al crear equipo: {e}")
        flash(f"Error (¿ya existe un equipo con ese nombre?): {e}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect('/equipos')


@app.route('/equipo/<int:id_equipo>')
def detalle_equipo(id_equipo):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("SELECT * FROM equipo_multidisciplinario WHERE id_equipo = %s", (id_equipo,))
    equipo = cur.fetchone()
    if not equipo:
        cur.close(); conn.close()
        return "Equipo no encontrado", 404

    cur.execute("""
        SELECT em.*, p.nombre, p.apellido_p, p.apellido_m, r.nombre_rol
        FROM equipo_miembro em
        JOIN personal p ON p.id = em.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE em.id_equipo = %s AND em.fecha_baja IS NULL
        ORDER BY r.nombre_rol, p.nombre
    """, (id_equipo,))
    miembros_activos = cur.fetchall()

    cur.execute("""
        SELECT em.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM equipo_miembro em
        JOIN personal p ON p.id = em.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE em.id_equipo = %s AND em.fecha_baja IS NOT NULL
        ORDER BY em.fecha_baja DESC
    """, (id_equipo,))
    historial = cur.fetchall()

    cur.execute("""
        SELECT c.id_caso, c.folio_caso, c.nom_caso, ec.nom_est_caso AS estatus
        FROM caso c
        JOIN estatus_caso ec ON ec.id_est_caso = c.id_est_caso
        WHERE c.id_equipo = %s
        ORDER BY c.id_caso DESC
    """, (id_equipo,))
    casos = cur.fetchall()

    cur.execute("""
        SELECT p.id, p.nombre, p.apellido_p, r.nombre_rol
        FROM personal p
        JOIN roles r ON r.id = p.rol_id
        WHERE p.esta_activo = TRUE
          AND p.id NOT IN (
              SELECT id_personal FROM equipo_miembro
              WHERE id_equipo = %s AND fecha_baja IS NULL
          )
        ORDER BY r.nombre_rol, p.nombre
    """, (id_equipo,))
    personal_disponible = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('equipo_detalle.html',
                           equipo=equipo,
                           miembros_activos=miembros_activos,
                           historial=historial,
                           casos=casos,
                           personal_disponible=personal_disponible,
                           nombre=session['nombre'])


@app.route('/equipo/<int:id_equipo>/agregar_miembro', methods=['POST'])
def equipo_agregar_miembro(id_equipo):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO equipo_miembro (id_equipo, id_personal, fecha_alta)
            VALUES (%s, %s, CURRENT_DATE)
        """, (id_equipo, request.form['id_personal']))
        conn.commit()
        flash("Miembro agregado al equipo", "success")
    except Exception as e:
        conn.rollback()
        print(f"Error al agregar miembro: {e}")
        flash(f"Error al agregar miembro: {e}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for('detalle_equipo', id_equipo=id_equipo))


@app.route('/equipo/<int:id_equipo>/dar_baja/<int:id_personal>/<fecha_alta>')
def equipo_dar_baja(id_equipo, id_personal, fecha_alta):
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            UPDATE equipo_miembro
            SET fecha_baja = CURRENT_DATE
            WHERE id_equipo = %s AND id_personal = %s
              AND fecha_alta = %s AND fecha_baja IS NULL
        """, (id_equipo, id_personal, fecha_alta))
        conn.commit()
        flash("Miembro dado de baja del equipo (historial conservado)", "success")
    except Exception as e:
        conn.rollback()
        print(f"Error al dar de baja: {e}")
        flash(f"Error al dar de baja: {e}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for('detalle_equipo', id_equipo=id_equipo))

# ----------------------------------------------------------------
# EDITAR NNA (con múltiples lenguas y preferente)
# ----------------------------------------------------------------

@app.route('/nna/editar/<int:id_nna>', methods=['GET', 'POST'])
def editar_nna(id_nna):
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    if request.method == 'POST':
        folio_nna = request.form.get('folio_nna')
        nombre = request.form.get('nombre')
        apellido_p = request.form.get('apellido_p') or None
        apellido_m = request.form.get('apellido_m') or None
        fecha_nacimiento = request.form.get('fecha_nacimiento') or None
        curp = request.form.get('curp') or None
        id_sexo = request.form.get('id_sexo') or None
        id_esc = request.form.get('id_esc') or None
        lugar_nacimiento = request.form.get('lugar_nacimiento') or None
        
        calle = request.form.get('calle')
        numero_ext = request.form.get('numero_ext')
        numero_int = request.form.get('numero_int') or None
        referencias = request.form.get('referencias') or None
        nom_mun = request.form.get('nom_mun')
        nom_col = request.form.get('nom_col') or None
        cp_asen = request.form.get('cp_asen') or None
        id_ent_domicilio = request.form.get('id_ent_domicilio') or None
        
        id_condicion = request.form.get('id_condicion')

        try:
            cur.execute("SELECT id_direccion FROM nna WHERE id_nna = %s", (id_nna,))
            res_nna = cur.fetchone()
            id_direccion = res_nna['id_direccion'] if res_nna else None

            if id_direccion:
                cur.execute("SELECT id_asen FROM direccion WHERE id_direccion = %s", (id_direccion,))
                id_asen = cur.fetchone()['id_asen']
                cur.execute("""
                    UPDATE asentamiento 
                    SET nom_mun = %s, nom_col = %s, cp_asen = %s, id_ent = %s 
                    WHERE id_asen = %s
                """, (nom_mun, nom_col, cp_asen, id_ent_domicilio, id_asen))
                cur.execute("""
                    UPDATE direccion 
                    SET calle = %s, numero_ext = %s, numero_int = %s, referencias = %s 
                    WHERE id_direccion = %s
                """, (calle, numero_ext, numero_int, referencias, id_direccion))
            else:
                cur.execute("""
                    INSERT INTO asentamiento (nom_mun, nom_col, cp_asen, id_ent) 
                    VALUES (%s, %s, %s, %s) RETURNING id_asen
                """, (nom_mun, nom_col, cp_asen, id_ent_domicilio))
                id_asen = cur.fetchone()['id_asen']
                cur.execute("""
                    INSERT INTO direccion (calle, numero_ext, numero_int, referencias, id_asen) 
                    VALUES (%s, %s, %s, %s, %s) RETURNING id_direccion
                """, (calle, numero_ext, numero_int, referencias, id_asen))
                id_direccion = cur.fetchone()['id_direccion']

            cur.execute("""
                UPDATE nna 
                SET folio_nna = %s, nombre = %s, apellido_p = %s, apellido_m = %s, 
                    fecha_nacimiento = %s, curp = %s, id_sexo = %s, id_esc = %s, 
                    id_direccion = %s, lugar_nacimiento = %s 
                WHERE id_nna = %s
            """, (folio_nna, nombre, apellido_p, apellido_m, fecha_nacimiento, curp, 
                  id_sexo, id_esc, id_direccion, lugar_nacimiento, id_nna))

            # --- LENGUAS MÚLTIPLES CON PREFERENTE ---
            # Borramos las anteriores y reinsertamos las elegidas.
            cur.execute("DELETE FROM lenguaje_nna WHERE id_nna = %s", (id_nna,))
            lenguas_elegidas = request.form.getlist('lenguas')
            len_preferente = request.form.get('lengua_preferente')
            for id_len in lenguas_elegidas:
                es_pref = (str(id_len) == str(len_preferente))
                cur.execute("""
                    INSERT INTO lenguaje_nna (id_nna, id_len, preferente)
                    VALUES (%s, %s, %s)
                """, (id_nna, id_len, es_pref))

            cur.execute("DELETE FROM nna_condicion WHERE id_nna = %s", (id_nna,))
            if id_condicion:
                cur.execute("INSERT INTO nna_condicion (id_nna, id_condicion) VALUES (%s, %s)", (id_nna, id_condicion))

            conn.commit()
            return redirect(url_for('detalle_nna', id_nna=id_nna))

        except Exception as e:
            conn.rollback()
            print(f"Error crítico detectado en la actualización: {e}")
            flash(f"Error al actualizar: {e}", "error")

    cur.execute("""
        SELECT nna.*, 
               d.calle, d.numero_ext, d.numero_int, d.referencias,
               a.nom_mun, a.nom_col, a.cp_asen, a.id_ent AS id_ent_domicilio,
               nc.id_condicion
        FROM nna nna
        LEFT JOIN direccion d ON nna.id_direccion = d.id_direccion
        LEFT JOIN asentamiento a ON d.id_asen = a.id_asen
        LEFT JOIN nna_condicion nc ON nna.id_nna = nc.id_nna
        WHERE nna.id_nna = %s
    """, (id_nna,))
    nna = cur.fetchone()

    # Lenguas que YA tiene el NNA (para marcarlas en el formulario)
    cur.execute("""
        SELECT id_len, preferente FROM lenguaje_nna WHERE id_nna = %s
    """, (id_nna,))
    lenguas_actuales = {row['id_len']: row['preferente'] for row in cur.fetchall()}

    cur.execute("SELECT id_sexo, nom_sexo FROM sexo ORDER BY nom_sexo")
    cat_sexo = cur.fetchall()
    cur.execute("SELECT id_esc, nom_esc FROM escolaridad")
    cat_escolaridad = cur.fetchall()
    cur.execute("SELECT id_ent, nom_ent FROM entidad_federativa ORDER BY nom_ent")
    cat_estados = cur.fetchall()
    cur.execute("""
        SELECT id_len, variante_len, familia_len, agrupacion_len, autodenom_len
        FROM lengua ORDER BY variante_len
    """)
    cat_lenguas = cur.fetchall()
    cur.execute("SELECT id_condicion, nombre FROM condicion ORDER BY nombre")
    cat_condiciones = cur.fetchall()

    cur.close()
    conn.close()

    return render_template('editar_nna.html', nna=nna, cat_sexo=cat_sexo, 
                           cat_escolaridad=cat_escolaridad, cat_estados=cat_estados, 
                           cat_lenguas=cat_lenguas, cat_condiciones=cat_condiciones,
                           lenguas_actuales=lenguas_actuales)

# ----------------------------------------------------------------
# MÓDULO: DISCAPACIDADES (CIF)
# ----------------------------------------------------------------

@app.route('/discapacidades')
def listar_discapacidades():
    """Lista las 100 discapacidades del catálogo CIF con su jerarquía."""
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT c.id_condicion, c.nombre, c.codigo_cif,
               ca.nombre AS categoria, sc.nombre AS subcategoria,
               gd.nom_grado_dif, gd.codigo_cif_dif,
               gp.nom_grado_dep
        FROM condicion c
        JOIN subcategoria sc ON sc.id_subcategoria = c.id_subcategoria
        JOIN categoria ca    ON ca.id_categoria = sc.id_categoria
        LEFT JOIN grado_dificultad gd  ON gd.id_grado_dif = c.id_grado_dif
        LEFT JOIN grado_dependencia gp ON gp.id_grado_dep = c.id_grado_dep
        ORDER BY ca.nombre, sc.nombre, c.nombre
    """)
    discapacidades = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('discapacidades_listado.html',
                           discapacidades=discapacidades, nombre=session['nombre'])


@app.route('/discapacidad/<int:id_condicion>', methods=['GET', 'POST'])
def detalle_discapacidad(id_condicion):
    """Ver / editar una discapacidad: grados + funciones + productos."""
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        try:
            # Grados (un valor cada uno)
            id_grado_dif = request.form.get('id_grado_dif') or None
            id_grado_dep = request.form.get('id_grado_dep') or None
            cur.execute("""
                UPDATE condicion SET id_grado_dif = %s, id_grado_dep = %s
                WHERE id_condicion = %s
            """, (id_grado_dif, id_grado_dep, id_condicion))

            # Funciones afectadas (N:M): borrar y reinsertar las marcadas
            cur.execute("DELETE FROM condicion_funcion WHERE id_condicion = %s", (id_condicion,))
            for id_func in request.form.getlist('funciones'):
                cur.execute("""
                    INSERT INTO condicion_funcion (id_condicion, id_funcion)
                    VALUES (%s, %s) ON CONFLICT DO NOTHING
                """, (id_condicion, id_func))

            # Productos de apoyo (N:M)
            cur.execute("DELETE FROM condicion_producto WHERE id_condicion = %s", (id_condicion,))
            for id_prod in request.form.getlist('productos'):
                cur.execute("""
                    INSERT INTO condicion_producto (id_condicion, id_producto)
                    VALUES (%s, %s) ON CONFLICT DO NOTHING
                """, (id_condicion, id_prod))

            conn.commit()
            flash("Discapacidad actualizada correctamente", "success")
            return redirect(url_for('detalle_discapacidad', id_condicion=id_condicion))
        except Exception as e:
            conn.rollback()
            print(f"Error al actualizar discapacidad: {e}")
            flash(f"Error al actualizar: {e}", "error")

    # --- Datos de la discapacidad ---
    cur.execute("""
        SELECT c.*, ca.nombre AS categoria, sc.nombre AS subcategoria
        FROM condicion c
        JOIN subcategoria sc ON sc.id_subcategoria = c.id_subcategoria
        JOIN categoria ca    ON ca.id_categoria = sc.id_categoria
        WHERE c.id_condicion = %s
    """, (id_condicion,))
    disc = cur.fetchone()
    if not disc:
        cur.close(); conn.close()
        return "Discapacidad no encontrada", 404

    # Catálogos para los menús
    cur.execute("SELECT id_grado_dif, nom_grado_dif, codigo_cif_dif FROM grado_dificultad ORDER BY codigo_cif_dif")
    grados_dif = cur.fetchall()
    cur.execute("SELECT id_grado_dep, nom_grado_dep FROM grado_dependencia ORDER BY id_grado_dep")
    grados_dep = cur.fetchall()
    cur.execute("SELECT id_funcion, nom_funcion, codigo_cif FROM funcion_corporal ORDER BY nom_funcion")
    funciones = cur.fetchall()
    cur.execute("SELECT id_producto, nom_producto FROM producto_apoyo ORDER BY nom_producto")
    productos = cur.fetchall()

    # Lo que ya tiene marcado (para precargar los checkboxes)
    cur.execute("SELECT id_funcion FROM condicion_funcion WHERE id_condicion = %s", (id_condicion,))
    func_marcadas = [r['id_funcion'] for r in cur.fetchall()]
    cur.execute("SELECT id_producto FROM condicion_producto WHERE id_condicion = %s", (id_condicion,))
    prod_marcados = [r['id_producto'] for r in cur.fetchall()]

    cur.close()
    conn.close()
    return render_template('discapacidad_detalle.html',
                           disc=disc, grados_dif=grados_dif, grados_dep=grados_dep,
                           funciones=funciones, productos=productos,
                           func_marcadas=func_marcadas, prod_marcados=prod_marcados,
                           nombre=session['nombre'])


# Arranque del servidor Flask al final de todas las definiciones
if __name__ == '__main__':
    app.run(debug=True)