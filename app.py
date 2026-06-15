from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
import re  # Esta librería sirve para validar formatos de texto
import os
from psycopg2.extras import RealDictConnection, RealDictCursor

# FORZAMOS UTF-8 para que los mensajes de error de PostgreSQL en español no provoquen fallos
os.environ["PGCLIENTENCODING"] = "UTF8"

app = Flask(__name__)
app.secret_key = 'tu_llave_secreta_super_pro'

# Función para la conexión de postgresql
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

# Las auxiliares hacían fila[0], pero con RealDictCursor las filas son
# diccionarios. Esta función funciona con ambos tipos de cursor.
def _primer_valor(fila):
    if fila is None:
        return None
    if isinstance(fila, dict):
        return list(fila.values())[0]
    return fila[0]


def obtener_id_sexo(cur, valor):
    """Convierte lo que mande el formulario al id_sexo que espera la base de datos."""
    if valor is None or str(valor).strip() == '':
        return None
    valor = str(valor).strip()
    if valor.isdigit():
        return int(valor)
    cur.execute("SELECT id_sexo FROM sexo WHERE nom_sexo ILIKE %s", (valor,))
    return _primer_valor(cur.fetchone())


def obtener_o_crear_asentamiento(cur, municipio, colonia, cp, estado):
    """Busca o inserta entidades y asentamientos dinámicamente."""
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
    """Crea una dirección con el nuevo esquema y devuelve su id_direccion."""
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


# Consulta reutilizable que traduce la base nueva al formato de las plantillas
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


@app.route('/home') # Asegúrate de que esta sea la ruta que estás visitando
def home():
    if 'usuario_id' not in session: 
        return redirect(url_for('index'))
    
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Hacemos un JOIN para traer nombre_rol directamente de la tabla roles
    query = """
        SELECT p.*, r.nombre_rol 
        FROM personal p 
        LEFT JOIN roles r ON p.rol_id = r.id 
        WHERE p.id = %s
    """
    cur.execute(query, (session['usuario_id'],))
    usuario = cur.fetchone()
    cur.close()
    conn.close()
    
    if not usuario:
        return "Usuario no encontrado", 404
        
    # Aquí es donde fallabas: debes enviar 'p=usuario'
    return render_template('home.html', p=usuario)

# ----------------------------------------------------------------
# MÓDULO 2 (NNA) Y MÓDULO 3 (TUTORES)
# ----------------------------------------------------------------

@app.route('/nna')
def listar_nna():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    # El estatus se deriva de los casos (normalización):
    #   EN ATENCION = tiene al menos un caso abierto (estatus <> 'Cerrado')
    #   ATENDIDO    = tiene casos pero todos cerrados
    #   REGISTRADO  = no tiene ningún caso todavía
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
def registrar_nna():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            id_dir = crear_direccion(cur, d)

            # CURP opcional: si viene vacía guardamos NULL (por el UNIQUE)
            curp = (d.get('curp') or '').strip().upper() or None

            # La tabla nna no tiene id_len ni id_condicion: son relaciones
            # N:M que viven en lenguaje_nna y nna_condicion
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

            # Folio máximo 10 caracteres (VARCHAR(10))
            folio = d.get('folio_nna', '').strip() or f"NNA-{id_nna:05d}"
            cur.execute("UPDATE nna SET folio_nna = %s WHERE id_nna = %s",
                        (folio[:10], id_nna))

            if d.get('id_len'):
                cur.execute("""
                    INSERT INTO lenguaje_nna (id_nna, id_len, preferente)
                    VALUES (%s, %s, TRUE)
                    ON CONFLICT DO NOTHING
                """, (id_nna, d['id_len']))

            if d.get('id_condicion'):
                cur.execute("""
                    INSERT INTO nna_condicion (id_nna, id_condicion)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING
                """, (id_nna, d['id_condicion']))

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

    # Carga de catálogos relacionales para renderizar el formulario dinámico
    cur.execute("SELECT id_sexo, nom_sexo FROM sexo")
    sexos = cur.fetchall()
    cur.execute("SELECT id_esc, nom_esc FROM escolaridad")
    escolaridades = cur.fetchall()
    cur.execute("SELECT id_len, variante_len FROM lengua ORDER BY variante_len")
    lenguas = cur.fetchall()
    cur.execute("""
        SELECT c.id_condicion, c.nombre, ca.nombre AS categoria
        FROM condicion c
        JOIN subcategoria sc ON sc.id_subcategoria = c.id_subcategoria
        JOIN categoria ca    ON ca.id_categoria   = sc.id_categoria
        ORDER BY ca.nombre, c.nombre
    """)
    condiciones = cur.fetchall()
    cur.execute("SELECT id_ent, nom_ent FROM entidad_federativa ORDER BY nom_ent")
    entidades = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('nna_registro.html', sexos=sexos,
                           escolaridades=escolaridades, lenguas=lenguas,
                           condiciones=condiciones, entidades=entidades)

@app.route('/nna/detalle/<int:id_nna>')
def detalle_nna(id_nna):
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Usamos LEFT JOIN para traer la info de nna y su direccion en una sola consulta
    query = """
        SELECT nna.*, direccion.calle, direccion.numero_ext, direccion.numero_int 
        FROM nna 
        LEFT JOIN direccion ON nna.id_direccion = direccion.id_direccion 
        WHERE nna.id_nna = %s
    """
    cur.execute(query, (id_nna,))
    nna = cur.fetchone() # Esto trae un solo registro
    
    cur.close()
    conn.close()
    
    return render_template('detalle_nna.html', nna=nna)

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

    cur.close()
    conn.close()
    return render_template('tutor_registro.html', niños=niños, parentescos=parentescos, sexos=sexos)

# ----------------------------------------------------------------
# NUEVO — MÓDULO 4: CASOS (procedimiento art. 123 LGDNNA)
# Tres pantallas: listado, apertura y EXPEDIENTE del caso.
# El expediente concentra: NNA, derechos vulnerados/restituidos,
# personal asignado, seguimientos y control de estatus.
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
            # 1. Estatus inicial: siempre 'Deteccion' (primer paso del art. 123)
            cur.execute("SELECT id_est_caso FROM estatus_caso WHERE nom_est_caso = 'Deteccion'")
            id_est = _primer_valor(cur.fetchone())

            # 2. Crear el caso (folio automático: la columna es VARCHAR(25))
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

            # 3. Vincular el NNA afectado (obligatorio: un caso es sobre un NNA)
            cur.execute("""
                INSERT INTO caso_nna (id_caso, id_nna) VALUES (%s, %s)
            """, (id_caso, d['id_nna']))

            # 4. Registrar los derechos vulnerados marcados (checkboxes:
            #    getlist trae TODOS los seleccionados)
            for id_der in request.form.getlist('derechos'):
                cur.execute("""
                    INSERT INTO caso_derecho (id_caso, id_nna, id_der)
                    VALUES (%s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (id_caso, d['id_nna'], id_der))

            # 5. Quien abre el caso queda asignado automáticamente con su rol
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

    # GET: catálogos para el formulario
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
    """EXPEDIENTE del caso: toda la información y acciones en una pantalla."""
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Datos generales del caso
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

    # NNA vinculados al caso
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

    # Derechos vulnerados/restituidos por NNA
    cur.execute("""
        SELECT cd.*, der.nom_der, n.nombre AS nna_nombre, n.apellido_p AS nna_apellido
        FROM caso_derecho cd
        JOIN derecho der ON der.id_der = cd.id_der
        JOIN nna n ON n.id_nna = cd.id_nna
        WHERE cd.id_caso = %s
        ORDER BY cd.restituido, cd.fecha_detec
    """, (id_caso,))
    derechos_caso = cur.fetchall()

    # Personal asignado (vigente)
    cur.execute("""
        SELECT ac.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM asignacion_caso ac
        JOIN personal p ON p.id = ac.id_personal
        JOIN roles r    ON r.id = ac.rol_id
        WHERE ac.id_caso = %s AND ac.fecha_fin IS NULL
        ORDER BY ac.fecha_asig
    """, (id_caso,))
    asignados = cur.fetchall()

    # Seguimientos (aquí viven el seguimiento legal, psicológico, etc.:
    # cada nota queda firmada por quien la hizo y su rol)
    cur.execute("""
        SELECT sg.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM seguimiento sg
        JOIN personal p ON p.id = sg.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE sg.id_caso = %s
        ORDER BY sg.fecha_seg DESC, sg.id_seg DESC
    """, (id_caso,))
    seguimientos = cur.fetchall()

    # Catálogos para las acciones del expediente
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
    """Marca un derecho como restituido con la fecha de hoy."""
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
    """Asigna personal al caso con su rol actual (relación ternaria)."""
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
    """Agrega una nota de seguimiento firmada por el usuario en sesión.
    El seguimiento legal/psicológico se distingue por el rol de quien firma."""
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
    """Cambia el estatus del caso. Si pasa a 'Cerrado' guarda la fecha de
    cierre; si se reabre, la limpia."""
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
# PANTALLAS COMPLEMENTARIAS ORIGINALES (MANTENIDAS)
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
    'tipo_apoyo':     {'tabla': 'tipo_apoyo',     'id': 'id_tipo_apo',  'campos': [('nom_tipo_apo', 'Tipo de apoyo')], 'titulo': 'Tipos de apoyo'},
    'tipo_consulta':  {'tabla': 'tipo_consulta',  'id': 'id_tipo_consul', 'campos': [('nom_tipo_consul', 'Tipo de consulta')], 'titulo': 'Tipos de consulta'},
    'metodo_pago':    {'tabla': 'metodo_pago',    'id': 'id_met_pago',  'campos': [('nom_met_pago', 'Método de pago')], 'titulo': 'Métodos de pago'},
    'enfermedad':     {'tabla': 'enfermedad',     'id': 'id_enf',       'campos': [('nombre', 'Enfermedad'), ('codigo_cie', 'Código CIE')], 'titulo': 'Enfermedades'},
    'lengua':         {'tabla': 'lengua',         'id': 'id_len',       'campos': [('variante_len', 'Variante'), ('familia_len', 'Familia'), ('autodenom_len', 'Autodenominación')], 'titulo': 'Lenguas'},
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
# CONSULTAS: se ligan directamente a un NNA (no requieren caso).
#            Tipos: Médica, Psicológica, Jurídica, Trabajo Social.
# APOYOS:    se ligan a un caso+NNA (por la FK compuesta a caso_nna),
#            por eso primero eliges el caso y luego el NNA de ese caso.
# ================================================================

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

    # GET: catálogos para el formulario
    cur.execute("""
        SELECT id_nna, folio_nna, nombre, apellido_p, apellido_m
        FROM nna ORDER BY nombre, apellido_p
    """)
    nna_lista = cur.fetchall()
    cur.execute("SELECT id_tipo_consul, nom_tipo_consul FROM tipo_consulta ORDER BY id_tipo_consul")
    tipos = cur.fetchall()
    # Solo profesionales que dan consultas (médico, psicólogo, abogado, T. social)
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
# MÓDULO 7: APOYOS  (ligados a caso + NNA)
# ----------------------------------------------------------------

@app.route('/apoyos')
def listar_apoyos():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT a.*,
               ta.nom_tipo_apo AS tipo,
               c.folio_caso,
               n.folio_nna, n.nombre AS nna_nombre, n.apellido_p AS nna_apellido,
               p.nombre AS aut_nombre, p.apellido_p AS aut_apellido,
               -- Cuánto de este apoyo ya está cubierto por donaciones
               COALESCE((SELECT SUM(ad.monto_aplicado)
                         FROM apoyo_donacion ad WHERE ad.id_apo = a.id_apo), 0) AS cubierto
        FROM apoyo a
        JOIN tipo_apoyo ta ON ta.id_tipo_apo = a.id_tipo_apo
        JOIN caso c        ON c.id_caso = a.id_caso
        JOIN nna n         ON n.id_nna = a.id_nna
        JOIN personal p    ON p.id = a.id_autoriza
        ORDER BY a.fecha_apo DESC
    """)
    apoyos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('apoyos_listado.html',
                           apoyos=apoyos, nombre=session['nombre'])


@app.route('/apoyos/registrar', methods=['GET', 'POST'])
def registrar_apoyo():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if request.method == 'POST':
        d = request.form
        try:
            cur.execute("""
                INSERT INTO apoyo (id_caso, id_nna, id_tipo_apo, descripcion,
                                   monto, id_autoriza)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                d['id_caso'], d['id_nna'], d['id_tipo_apo'],
                d.get('descripcion') or None,
                d.get('monto') or None,
                session['usuario_id']  # quien autoriza es el usuario en sesión
            ))
            conn.commit()
            flash("Apoyo registrado con éxito", "success")
            return redirect(url_for('listar_apoyos'))
        except Exception as e:
            conn.rollback()
            print(f"Error al registrar apoyo: {e}")
            flash(f"Error al registrar apoyo: {e}", "error")
            return redirect('/apoyos/registrar')
        finally:
            cur.close()
            conn.close()

    # GET: para apoyos necesitamos las PAREJAS caso+NNA válidas (caso_nna),
    # porque la FK del apoyo apunta a esa combinación, no a cualquier NNA.
    cur.execute("""
        SELECT cn.id_caso, cn.id_nna,
               c.folio_caso, c.nom_caso,
               n.folio_nna, n.nombre, n.apellido_p
        FROM caso_nna cn
        JOIN caso c ON c.id_caso = cn.id_caso
        JOIN nna n  ON n.id_nna = cn.id_nna
        ORDER BY c.id_caso DESC, n.nombre
    """)
    pares_caso_nna = cur.fetchall()
    cur.execute("SELECT id_tipo_apo, nom_tipo_apo FROM tipo_apoyo ORDER BY id_tipo_apo")
    tipos = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('apoyo_registro.html',
                           pares_caso_nna=pares_caso_nna, tipos=tipos)

# ----------------------------------------------------------------
# La membresía vive en la tabla puente 'equipo_miembro', con
# fecha_alta y fecha_baja. NUNCA borramos un miembro: cerramos su
# fecha_baja. Así se conserva el historial completo y los cambios
# de un miembro no afectan a los demás.
# ================================================================

@app.route('/equipos')
def listar_equipos():
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT e.*,
               -- Miembros activos (los que no tienen fecha_baja)
               (SELECT COUNT(*) FROM equipo_miembro em
                 WHERE em.id_equipo = e.id_equipo AND em.fecha_baja IS NULL) AS num_activos,
               -- Casos que atiende este equipo
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
    """Detalle de UN equipo: sus miembros activos, su historial de
    bajas, y los casos que atiende."""
    if 'usuario_id' not in session: return redirect(url_for('index'))

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Datos del equipo
    cur.execute("SELECT * FROM equipo_multidisciplinario WHERE id_equipo = %s", (id_equipo,))
    equipo = cur.fetchone()
    if not equipo:
        cur.close(); conn.close()
        return "Equipo no encontrado", 404

    # Miembros ACTIVOS (fecha_baja IS NULL)
    cur.execute("""
        SELECT em.*, p.nombre, p.apellido_p, p.apellido_m, r.nombre_rol
        FROM equipo_miembro em
        JOIN personal p ON p.id = em.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE em.id_equipo = %s AND em.fecha_baja IS NULL
        ORDER BY r.nombre_rol, p.nombre
    """, (id_equipo,))
    miembros_activos = cur.fetchall()

    # Historial: miembros que YA salieron (fecha_baja NO nula)
    cur.execute("""
        SELECT em.*, p.nombre, p.apellido_p, r.nombre_rol
        FROM equipo_miembro em
        JOIN personal p ON p.id = em.id_personal
        LEFT JOIN roles r ON r.id = p.rol_id
        WHERE em.id_equipo = %s AND em.fecha_baja IS NOT NULL
        ORDER BY em.fecha_baja DESC
    """, (id_equipo,))
    historial = cur.fetchall()

    # Casos que atiende el equipo
    cur.execute("""
        SELECT c.id_caso, c.folio_caso, c.nom_caso, ec.nom_est_caso AS estatus
        FROM caso c
        JOIN estatus_caso ec ON ec.id_est_caso = c.id_est_caso
        WHERE c.id_equipo = %s
        ORDER BY c.id_caso DESC
    """, (id_equipo,))
    casos = cur.fetchall()

    # Personal activo que NO está ya en el equipo (para el desplegable de alta).
    # Excluimos a quienes ya tienen membresía activa en este equipo.
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
    """Da de alta a un miembro: inserta una fila nueva con fecha_alta=hoy
    y fecha_baja=NULL. Un trabajador puede estar en varios equipos."""
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
    """Da de baja a un miembro: NO borra la fila, solo le pone
    fecha_baja=hoy. Conserva el historial. Necesitamos fecha_alta
    porque es parte de la clave primaria de equipo_miembro."""
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



# Arranque del servidor Flask al final de todas las definiciones
if __name__ == '__main__':
    app.run(debug=True)