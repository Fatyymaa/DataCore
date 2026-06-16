// ============================================================
//  boton_inicio.js  —  Sistema DataCore
//  Botón flotante "Inicio" + protección contra salida sin guardar.
//
//  CÓMO FUNCIONA:
//   1. Inyecta un botón fijo arriba a la izquierda en todas las pantallas.
//   2. Vigila TODOS los formularios de la página. Si el usuario escribe
//      o cambia algo (y todavía no ha guardado), marca una bandera
//      "hayCambiosSinGuardar".
//   3. Al hacer clic en "Inicio":
//        - si hay cambios sin guardar  -> pregunta antes de salir.
//        - si no se tocó nada           -> sale directo a /dashboard.
//   4. Cuando el usuario envía un formulario (clic en Guardar), se
//      entiende que SÍ va a guardar, así que se limpia la bandera y
//      no se le molesta con la advertencia.
//   5. Como respaldo, también avisa si intenta cerrar la pestaña o
//      navegar fuera con cambios pendientes (evento nativo del navegador).
//
//  USO: agregar al final del <body> de cada plantilla:
//     <script src="{{ url_for('static', filename='js/boton_inicio.js') }}"></script>
// ============================================================

(function () {
    // Bandera global: ¿el usuario modificó algo sin guardar?
    let hayCambiosSinGuardar = false;

    // A dónde lleva el botón de inicio
    const URL_INICIO = "/dashboard";

    // ----------------------------------------------------------------
    // 1. Crear e inyectar el botón flotante
    // ----------------------------------------------------------------
    function crearBoton() {
        const btn = document.createElement("button");
        btn.id = "btn-inicio-flotante";
        btn.type = "button";
        btn.innerHTML = "&#8962; INICIO";   // &#8962; es un iconito de casita
        btn.title = "Regresar al panel principal";

        // Estilos en línea para que se vea igual en todas las pantallas
        // (estilo brutalista monoespaciado, como el resto del sistema)
        Object.assign(btn.style, {
            position: "fixed",
            top: "15px",
            left: "15px",
            zIndex: "9999",
            background: "#000",
            color: "#fff",
            border: "2px solid #000",
            boxShadow: "3px 3px 0px #888",
            padding: "8px 14px",
            fontFamily: "monospace",
            fontWeight: "bold",
            fontSize: "12px",
            cursor: "pointer",
            letterSpacing: "1px"
        });

        btn.addEventListener("mouseenter", () => { btn.style.background = "#333"; });
        btn.addEventListener("mouseleave", () => { btn.style.background = "#000"; });

        btn.addEventListener("click", manejarClicInicio);
        document.body.appendChild(btn);
    }

    // ----------------------------------------------------------------
    // 2. Qué pasa al hacer clic en "Inicio"
    // ----------------------------------------------------------------
    function manejarClicInicio() {
        if (hayCambiosSinGuardar) {
            const seguro = confirm(
                "Tienes información sin guardar en esta pantalla.\n\n" +
                "Si sales ahora, se perderá lo que escribiste.\n\n" +
                "¿Deseas salir sin guardar?"
            );
            if (!seguro) {
                return; // el usuario decidió quedarse
            }
        }
        // Si no hay cambios, o si confirmó que quiere salir:
        // quitamos el aviso nativo y navegamos.
        hayCambiosSinGuardar = false;
        window.location.href = URL_INICIO;
    }

    // ----------------------------------------------------------------
    // 3. Vigilar los formularios para detectar cambios
    // ----------------------------------------------------------------
    function vigilarFormularios() {
        const formularios = document.querySelectorAll("form");

        formularios.forEach(form => {
            // Cualquier escritura o cambio marca la bandera
            form.addEventListener("input", () => { hayCambiosSinGuardar = true; });
            form.addEventListener("change", () => { hayCambiosSinGuardar = true; });

            // Al enviar el formulario (Guardar), el usuario SÍ guarda:
            // limpiamos la bandera para no molestarlo con la advertencia.
            form.addEventListener("submit", () => { hayCambiosSinGuardar = false; });
        });
    }

    // ----------------------------------------------------------------
    // 4. Respaldo: avisar si cierra la pestaña / navega fuera
    //    con cambios pendientes (diálogo nativo del navegador)
    // ----------------------------------------------------------------
    function vigilarSalidaNavegador() {
        window.addEventListener("beforeunload", function (e) {
            if (hayCambiosSinGuardar) {
                e.preventDefault();
                e.returnValue = "";   // los navegadores muestran su mensaje estándar
            }
        });
    }

    // ----------------------------------------------------------------
    // Arranque: cuando el HTML esté listo
    // ----------------------------------------------------------------
    document.addEventListener("DOMContentLoaded", function () {
        crearBoton();
        vigilarFormularios();
        vigilarSalidaNavegador();
    });
})();