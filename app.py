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

        # 🔀 DIVISIÓN DE CAMINOS
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
    rfc = d['rfc'].upper()   # Lo convertimos a mayúsculas automáticamente
    curp = d['curp'].upper() # Lo convertimos a mayúsculas automáticamente

    # --- VALIDACIÓN DE CONTRASEÑAS ---
    if pass1 != pass2:
        flash("Las contraseñas no coinciden", "error")
        return redirect(url_for('dashboard'))

    # --- VALIDACIÓN DE RFC (Formato: 4 letras, 6 números, 3 alfanuméricos) ---
    # Esta regla sirve para personas físicas
    rfc_pattern = r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$'
    if not re.match(rfc_pattern, rfc):
        flash("El formato del RFC es inválido", "error")
        return redirect(url_for('dashboard'))

    # --- VALIDACIÓN DE CURP (Formato: 18 caracteres específicos) ---
    curp_pattern = r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$'
    if not re.match(curp_pattern, curp):
        flash("El formato de la CURP es inválido", "error")
        return redirect(url_for('dashboard'))

    # Si todo está bien, procedemos a guardar
    es_emp = True if d['es_empleado'] == '1' else False

    conn = conectar_db()
    cur = conn.cursor()
    query = """
        INSERT INTO personal (nombre, apellido_p, apellido_m, rfc, curp, correo, 
        password1, rol_id, sexo, edad, direccion, es_empleado, esta_activo) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
    """
    cur.execute(query, (
        d['nombre'], 
        d['apellido_p'], 
        d['apellido_m'], 
        d['rfc'], 
        d['curp'], 
        d['correo'], 
        pass1, 
        d['rol_id'], 
        d['sexo'], 
        d['edad'], 
        d['direccion'], 
        es_emp
        ))
    conn.commit()
    cur.close()
    conn.close()

    flash("Usuario registrado con éxito", "success")
    return redirect(url_for('dashboard'))

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
    cur.execute("SELECT * FROM personal WHERE id = %s", (id,))
    persona = cur.fetchone()
    cur.close()
    conn.close()
    
    if not persona:
        return "Usuario no encontrado", 404
        
    return render_template('consultar.html', p=persona)
#editar los datos del trabajador y guardar los datos 
# --- RUTA PARA MOSTRAR EL FORMULARIO DE EDICIÓN ---
@app.route('/editar/<int:id>')
def editar_usuario(id):
    if 'usuario_id' not in session: return redirect(url_for('index'))
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM personal WHERE id = %s", (id,))
    usuario = cur.fetchone()
    cur.close()
    conn.close()
    return render_template('editar.html', u=usuario)

# --- RUTA PARA GUARDAR LOS CAMBIOS ---
@app.route('/actualizar', methods=['POST'])
def actualizar():
    if 'usuario_id' not in session: return redirect(url_for('index'))
    d = request.form
    es_emp = True if d['es_empleado'] == '1' else False
    
    conn = conectar_db()
    cur = conn.cursor()
    query = """
        UPDATE personal SET 
        nombre=%s, apellido_p=%s, apellido_m=%s, rfc=%s, curp=%s, 
        correo=%s, rol_id=%s, sexo=%s, edad=%s, direccion=%s, es_empleado=%s
        WHERE id=%s
    """
    cur.execute(query, (d['nombre'], d['apellido_p'], d['apellido_m'], d['rfc'], 
                        d['curp'], d['correo'], d['rol_id'], d['sexo'], 
                        d['edad'], d['direccion'], es_emp, d['id']))
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('dashboard'))
@app.route('/home')
def home():
    if 'usuario_id' not in session:
        return redirect(url_for('index'))
    
    return render_template('home.html', nombre=session['nombre'])

    # cerrar sesion

@app.route('/logout')
def logout():
        session.clear()
        return redirect(url_for('index'))
    
if __name__ == '__main__':
        app.run(debug=True)