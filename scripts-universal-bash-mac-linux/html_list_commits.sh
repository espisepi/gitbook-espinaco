#!/bin/bash
# Archivo: generar_listado.sh
# Descripción: Genera un único archivo HTML (index.html) que contiene un listado de enlaces a todos
#              los archivos HTML de la carpeta commits_html, ordenados por el número de commit.
#              Además, establece el título del HTML con el nombre del proyecto git.
#              Ahora se incluye un buscador similar al del script 1 para filtrar la lista de commits.

output_file="index.html"
html_dir="commits_html"

# Verificar que la carpeta exista
if [ ! -d "$html_dir" ]; then
  echo "El directorio '$html_dir' no existe. Por favor, verifica la ruta."
  exit 1
fi

# Obtener el nombre del proyecto git usando git rev-parse y basename
project_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")

# Si no se encuentra un proyecto git, asignar un valor por defecto
if [ -z "$project_name" ]; then
  project_name="Proyecto Git"
fi

# Crear el archivo HTML y escribir la cabecera
cat <<EOF > "$output_file"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project_name} list commits</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1e1e1e;
            color: #c9d1d9;
            margin: 0;
            padding: 20px;
        }
        h1 {
            color: #58a6ff;
        }
        ul {
            list-style: none;
            padding: 0;
        }
        li {
            margin-bottom: 10px;
        }
        a {
            text-decoration: none;
            color: #58a6ff;
        }
        a:hover {
            text-decoration: underline;
        }
        /* Estilos para el buscador con dark mode */
        #searchInput {
          width: 100%;
          padding: 8px;
          margin-bottom: 10px;
          border: 1px solid #30363d;
          border-radius: 4px;
          background-color: #161b22;
          color: #c9d1d9;
        }
        #searchInput::placeholder {
          color: #8b949e;
        }
        /* Scrollbar personalizado (en caso de que la lista sea muy larga) */
        ::-webkit-scrollbar {
          width: 10px;
        }
        ::-webkit-scrollbar-thumb {
          background: #30363d;
          border-radius: 5px;
        }
        ::-webkit-scrollbar-track {
          background: #161b22;
        }
        ::-webkit-scrollbar-corner {
          background: transparent;
        }
    </style>
    <script>
      function searchLinks() {
        var input = document.getElementById("searchInput");
        var filter = input.value.toUpperCase().trim();
        var searchTerms = filter.split(/\s+/);
        var ul = document.getElementById("linksList");
        var li = ul.getElementsByTagName("li");
        
        for (var i = 0; i < li.length; i++) {
          var a = li[i].getElementsByTagName("a")[0];
          if (a) {
            var txtValue = (a.textContent || a.innerText).toUpperCase();
            var match = true;
            for (var j = 0; j < searchTerms.length; j++) {
              if (txtValue.indexOf(searchTerms[j]) === -1) {
                match = false;
                break;
              }
            }
            li[i].style.display = match ? "" : "none";
          }
        }
      }
    </script>
</head>
<body>
    <h1>${project_name} list commits</h1>
    <input type="text" id="searchInput" onkeyup="searchLinks()" placeholder="Buscar...">
    <ul id="linksList">
EOF

# Listar los archivos usando ls (solo el nombre) y ordenarlos numéricamente según el número al inicio.
# Se asume que el nombre es: <número>_commit_<hash>_<titulo>.html
ls "$html_dir" | sort -t'_' -k1,1n | while IFS= read -r file; do
    echo "        <li><a href=\"$html_dir/$file\">$file</a></li>" >> "$output_file"
done

# Cerrar las etiquetas del HTML
cat <<EOF >> "$output_file"
    </ul>
</body>
</html>
EOF

echo "Archivo '$output_file' generado correctamente."