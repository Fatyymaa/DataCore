from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
import re  # Esta librería sirve para validar formatos de texto
from psycopg2.extras import RealDictConnection, RealDictCursor

app = Flask(__name__)
app.secret_key = 'tu_llave_secreta_super_pro'

#funcion para la conexion de postgresql
def conectar_db():
    return psycopg2.connect(
        host="localhost",
        database="fundacion_db",
        user="postgres",
        password="1234"
    )
# Ruta principal para el login
@app.route('/')
def index():
    return render_template('login.html')

# Logica de inicio de sesion 
@app.route('/login', methods=['POST'])
def login():
    correo = request.form['correo']
    password_ingresada = request.form['password1']

    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # buscar al usuario y verificar que este conectado
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
            session['rol'] = usuario['rol_id'] # Guardamos el rol en la sesión

        # DIVISIÓN DE CAMINOS
            if session['rol'] in [1, 2]:
                return redirect(url_for('dashboard'))
            else:
                return redirect(url_for('home'))
        else:
            # Este else pertenece al "if usuario['esta_activo']"
            return "Tu cuenta no está activa, contacta al director o coordinador."
    else:
        # Este else pertenece al "if usuario and password..."
        return "Correo o contraseña incorrectos. <a href='/'>Volver a intentar</a>"
    
    #ruta para el registro de los trabajadores
@app.route('/registro')
def vista_registro():
    return render_template('registro.html')

    

    # Ruta para el dashboard
@app.route('/dashboard')
def dashboard():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    # Listamos a todos por ID
    cur.execute("SELECT * FROM personal ORDER BY id ASC")
    usuarios = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('dashboard.html', personal=usuarios, nombre=session['nombre'])

# registrar nuevos empleados
@app.route('/registrar', methods=['POST'])
def registrar():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    
    d = request.form
    pass1 = d['password1']
    pass2 = d['confirmar_password']
    rfc = d['rfc'].upper()   
    curp = d['curp'].upper() 

    # --- VALIDACIÓN DE CONTRASEÑAS ---
    if pass1 != pass2:
        flash("Las contraseñas no coinciden", "error")
        return redirect('/dashboard') # 👈 CAMBIA ESTO por tu ruta real (ej. '/panel')

    # --- VALIDACIÓN DE RFC ---
    rfc_pattern = r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$'
    if not re.match(rfc_pattern, rfc):
        flash("El formato del RFC es inválido", "error")
        return redirect('/dashboard') # 👈 CAMBIA ESTO

    # --- VALIDACIÓN DE CURP ---
    curp_pattern = r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$'
    if not re.match(curp_pattern, curp):
        flash("El formato de la CURP es inválido", "error")
        return redirect('/dashboard') # 👈 CAMBIA ESTO

    # --- PREPARACIÓN DE DATOS ---
    es_emp = True if d['es_empleado'] == '1' else False
    activo = False 

    conn = conectar_db()
    cur = conn.cursor()
    
    try:
        # 1. INSERTAR EN LA TABLA PERSONAL
        # Ya no incluimos 'direccion' aquí porque no existe en esta tabla
        query_personal = """
            INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp, correo, 
            password1, rol_id, sexo, fecha_nacimiento, es_empleado, esta_activo) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """
        cur.execute(query_personal, (
            d['nombre'], 
            d['apellido_p'], 
            d['apellido_m'], 
            rfc, 
            curp, 
            d['correo'], 
            pass1, 
            d['rol_id'], 
            d['sexo'], 
            d['fecha_nacimiento'], 
            es_emp,
            activo
        ))
        
        # Cachamos el ID que Postgres acaba de generar para este usuario
        id_persona_nuevo = cur.fetchone()[0]

        # 2. INSERTAR EN LA TABLA DIRECCION
        # Usamos los nombres exactos de tus columnas según la terminal
        query_direccion = """
            INSERT INTO direccion (id_persona, calle, numero_ext, numero_int, colonia, cp, municipio, estado)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """
        cur.execute(query_direccion, (
            id_persona_nuevo,
            d['calle'],
            d['numero_ext'],
            d['numero_int'] if 'numero_int' in d and d['numero_int'] else None, # Protegido por si lo dejan vacío
            d['colonia'],
            d['cp'],
            d['municipio'],
            d['estado']
        ))
        
        # Si ambas consultas salieron bien, guardamos en la base de datos
        conn.commit()
        flash("Usuario y dirección registrados con éxito", "success")
        
    except Exception as e:
        # Si algo falla, deshacemos todo para no dejar datos a medias
        conn.rollback() 
        print(f"Error en el registro: {e}")
        flash(f"Error al registrar en base de datos: {e}", "error")
        
    finally:
        cur.close()
        conn.close()

    return redirect('/dashboard') 
#cambiar estado
@app.route('/estado/<int:id>/<string:actual>')
def cambiar_estado(id, actual):
    # Cambia de True a False o viceversa
    nuevo_estado = False if actual == 'True' else True
    conn = conectar_db()
    cur = conn.cursor()
    cur.execute("UPDATE personal SET esta_activo = %s WHERE id = %s", (nuevo_estado, id))
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))

# eliminar usuario
@app.route('/eliminar/<int:id>')
def eliminar(id):
    conn = conectar_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM personal WHERE id = %s", (id,))
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))
# consultar los datos del empleado
@app.route('/consultar/<int:id>')
def consultar_detalle(id):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    
    conn = conectar_db()
    # Usamos RealDictCursor para llamar los datos por nombre
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Hacemos el JOIN con la tabla direccion. 
    # Asegúrate de que los nombres de las columnas coincidan con los de tu BDD.
    query = """
        SELECT p.*, d.calle, d.numero_ext, d.numero_int, d.colonia, d.cp, d.municipio, d.estado 
        FROM personal p 
        LEFT JOIN direccion d ON p.id = d.id_persona 
        WHERE p.id = %s
    """
    
    cur.execute(query, (id,))
    persona = cur.fetchone()
    cur.close()
    conn.close()
    
    if not persona:
        return "Usuario no encontrado", 404
        
    return render_template('consultar.html', p=persona)
# --- RUTA PARA MOSTRAR EL FORMULARIO DE EDICIÓN ---
@app.route('/editar/<int:id>')
def editar_usuario(id):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Hacemos JOIN para traer los datos de ambas tablas en un solo objeto
    query = """
        SELECT p.*, d.calle, d.numero_ext, d.numero_int, d.colonia, d.cp, d.municipio, d.estado 
        FROM personal p 
        LEFT JOIN direccion d ON p.id = d.id_persona 
        WHERE p.id = %s
    """
    cur.execute(query, (id,))
    usuario = cur.fetchone()
    
    cur.close()
    conn.close()
    
    return render_template('editar.html', u=usuario)

# --- RUTA PARA GUARDAR LOS CAMBIOS ---
@app.route('/actualizar', methods=['POST'])
def actualizar():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    d = request.form
    es_emp = True if d.get('es_empleado') == '1' else False
    
    conn = conectar_db()
    cur = conn.cursor()
    
    try:
        # 1. Actualizar tabla PERSONAL
        query_personal = """
            UPDATE personal SET 
            nombre=%s, apellido_p=%s, apellido_m=%s, rfc=%s, curp=%s, 
            correo=%s, rol_id=%s, sexo=%s, fecha_nacimiento=%s, es_empleado=%s
            WHERE id=%s
        """
        cur.execute(query_personal, (
            d['nombre'], d['apellido_p'], d['apellido_m'], d['rfc'], 
            d['curp'], d['correo'], d['rol_id'], d['sexo'], 
            d['fecha_nacimiento'], es_emp, d['id']
        ))
        
        # 2. Actualizar tabla DIRECCION (Upsert: intenta actualizar, si no existe, inserta)
        query_update_dir = """
            UPDATE direccion SET 
            calle=%s, numero_ext=%s, numero_int=%s, colonia=%s, cp=%s, municipio=%s, estado=%s
            WHERE id_persona=%s
        """
        cur.execute(query_update_dir, (
            d['calle'], d['numero_ext'], d['numero_int'], d['colonia'], 
            d['cp'], d['municipio'], d['estado'], d['id']
        ))

        # Si cur.rowcount es 0, significa que el usuario no tenía dirección registrada antes
        if cur.rowcount == 0:
            query_insert_dir = """
                INSERT INTO direccion (id_persona, calle, numero_ext, numero_int, colonia, cp, municipio, estado)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            cur.execute(query_insert_dir, (
                d['id'], d['calle'], d['numero_ext'], d['numero_int'], 
                d['colonia'], d['cp'], d['municipio'], d['estado']
            ))
        
        conn.commit() # Guardamos los cambios de ambas tablas
        
    except Exception as e:
        conn.rollback() # Si algo falla, no guardamos nada
        print(f"Error al actualizar: {e}")
        
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))

    # cerrar sesion

@app.route('/logout')
def logout():
        session.clear()
        return redirect(url_for('index'))
#ruta home
@app.route('/home')
def home():
    # Verifica si el usuario inició sesión
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    
    # Pasamos el nombre desde la sesión al template
    nombre_usuario = session.get('nombre', 'Usuario')
    
    return render_template('home.html', nombre=nombre_usuario)

if __name__ == '__main__':
        app.run(debug=True)


# -------------------------------
# NUEVAS PANTALLAS (REQUISITO)
# -------------------------------

@app.route('/pantalla_personas')
def pantalla_personas():
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    return render_template('personas.html')


@app.route('/pantalla_discapacidades')
def pantalla_discapacidades():
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    return render_template('discapacidades.html')


@app.route('/pantalla_agregar_persona')
def pantalla_agregar_persona():
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    return render_template('agregar_persona.html')


@app.route('/pantalla_asignar_discapacidad')
def pantalla_asignar_discapacidad():
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    return render_template('asignar_discapacidad.html')

