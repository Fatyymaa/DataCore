from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
from psycopg2.extras import RealDictCursor
from functools import wraps

app = Flask(__name__)
app.secret_key = 'tu_llave_secreta_super_pro'

def conectar_db():
    return psycopg2.connect(host="localhost", database="fundacion", user="postgres", password="1234")

# Decorador de seguridad
def requiere_puesto(puestos_permitidos):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'puesto_nombre' not in session or session['puesto_nombre'] not in puestos_permitidos:
                flash("Acceso denegado: Área exclusiva para Directores y Coordinadores.")
                return redirect(url_for('login'))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        correo = request.form['correo']
        password = request.form['password']
        
        conn = conectar_db()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # CONSULTA: Ahora seleccionamos la columna 'contrasena' en texto plano
        query = """
            SELECT cu.id_cuenta, cu.contrasena, cp.nombre AS nombre_puesto, p.nombre AS nombre_persona 
            FROM cuenta_usuario cu
            JOIN personal per ON cu.id_personal = per.id_personal
            JOIN cat_puesto cp ON per.id_puesto = cp.id_puesto
            JOIN persona p ON per.id_persona = p.id_persona
            WHERE cu.correo = %s AND cu.activo = TRUE
        """
        cur.execute(query, (correo,))
        usuario = cur.fetchone()
        cur.close()
        conn.close()

        # Validación directa (comparación de strings)
        if usuario and usuario['contrasena'] == password:
            session['id_cuenta'] = usuario['id_cuenta']
            session['puesto_nombre'] = usuario['nombre_puesto']
            session['nombre_persona'] = usuario['nombre_persona']
            return redirect(url_for('dashboard'))
        else:
            flash('Correo o contraseña incorrectos')
            
    return render_template('login.html')

@app.route('/dashboard')
@requiere_puesto(['Director', 'Coordinador'])
def dashboard():
    if 'id_cuenta' not in session:
        return redirect(url_for('login'))
        
    conn = conectar_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Métricas
    cur.execute("SELECT COUNT(*) FROM cuenta_usuario WHERE activo = TRUE")
    usuarios_activos = cur.fetchone()['count']
    
    cur.execute("SELECT COUNT(*) FROM nino")
    total_ninos = cur.fetchone()['count']
    
    cur.execute("SELECT COUNT(*) FROM cuenta_usuario")
    total_usuarios = cur.fetchone()['count']
    
    # CORRECCIÓN: Aquí está el JOIN necesario a la tabla 'persona'
    query = """
        SELECT p.id_personal, per.nombre, per.primer_apellido, cp.nombre as puesto, p.fecha_ingreso 
        FROM personal p 
        JOIN persona per ON p.id_persona = per.id_persona
        JOIN cat_puesto cp ON p.id_puesto = cp.id_puesto
    """
    cur.execute(query)
    trabajadores = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return render_template('dashboard.html', 
                           usuarios_activos=usuarios_activos, 
                           total_ninos=total_ninos, 
                           total_usuarios=total_usuarios,
                           trabajadores=trabajadores)

@app.route('/logout')
def logout():
    # Limpia toda la sesión actual
    session.clear()
    # Redirige al usuario a la pantalla de inicio de sesión
    return redirect(url_for('login'))

@app.route('/registro', methods=['GET', 'POST'])
def registro():
    if request.method == 'POST':
        try:
            conn = conectar_db()
            cur = conn.cursor()
            
            # 1. Insertar en PERSONA
            cur.execute("""
                INSERT INTO persona (nombre, primer_apellido, segundo_apellido, fecha_nacimiento, curp, rfc, id_sexo)
                VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id_persona
            """, (
                request.form['nombre'], 
                request.form['primer_apellido'], 
                request.form.get('segundo_apellido'),
                request.form['fecha_nacimiento'], 
                request.form['curp'], 
                request.form['rfc'], 
                request.form['id_sexo']
            ))
            id_persona = cur.fetchone()[0]
            
            # 2. Insertar TELÉFONOS
            telefonos = request.form.getlist('telefono[]')
            tipos = request.form.getlist('id_tipo_telefono[]')
            for i in range(len(telefonos)):
                if telefonos[i]: # Validar que no esté vacío
                    cur.execute("INSERT INTO telefono (id_persona, numero, id_tipo_telefono) VALUES (%s, %s, %s)",
                                (id_persona, telefonos[i], tipos[i]))
            
            # 3. Insertar DIRECCIÓN
            cur.execute("""
                INSERT INTO direccion (id_persona, calle, numero_exterior, numero_interior, id_asentamiento)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                id_persona, 
                request.form['calle'], 
                request.form['num_ext'], 
                request.form.get('num_int'), 
                request.form['id_asentamiento']
            ))
            
            # 4. Insertar PERSONAL
            cur.execute("""
                INSERT INTO personal (id_persona, id_puesto, id_tipo_contratacion, fecha_ingreso)
                VALUES (%s, %s, %s, %s) RETURNING id_personal
            """, (
                id_persona, 
                request.form['id_puesto'], 
                request.form['id_tipo_contratacion'], 
                request.form['fecha_ingreso']
            ))
            id_personal = cur.fetchone()[0]
            
            # 5. Insertar CUENTA_USUARIO
            cur.execute("""
                INSERT INTO cuenta_usuario (id_personal, correo, contrasena) VALUES (%s, %s, %s)
            """, (
                id_personal, 
                request.form['correo'], 
                request.form['contrasena']
            ))
            
            conn.commit()
            cur.close()
            conn.close()
            return "Usuario registrado correctamente"
            
        except Exception as e:
            if 'conn' in locals() and conn: conn.rollback()
            return f"Error en la base de datos: {str(e)}"
            
    # Si es GET, solo renderizamos el formulario
    return render_template('registro.html')

if __name__ == '__main__':
    app.run(debug=True)