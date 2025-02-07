#!/bin/bash
# Archivo: generar_listado.sh
# Descripción: Genera un único archivo HTML (index.html) que contiene un listado de enlaces a todos
#              los archivos HTML de la carpeta commits_html, ordenados por el número de commit.
#              Además, establece el título del HTML con el nombre del proyecto git.

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
    </style>
</head>
<body>
    <h1>${project_name} list commits</h1>
    <ul>
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