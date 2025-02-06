#!/bin/bash
# Archivo: generar_listado.sh
# Descripción: Genera un archivo HTML con un listado de enlaces a los archivos HTML
#              que se encuentran en la carpeta commits_html. Los enlaces se ordenan
#              según el número que aparece al inicio de cada nombre de archivo.

output_file="index.html"
html_dir="commits_html"

# Verificar que el directorio exista
if [ ! -d "$html_dir" ]; then
  echo "El directorio '$html_dir' no existe. Por favor, crea la carpeta o verifica la ruta."
  exit 1
fi

# Crear el archivo HTML y escribir la cabecera
cat <<EOF > "$output_file"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Listado de Commits</title>
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
    <h1>Listado de Commits</h1>
    <ul>
EOF

# Listar los archivos HTML en commits_html ordenados por el número (campo antes del primer guion bajo)
# Se utiliza find y sort para mayor compatibilidad en los distintos sistemas.
find "$html_dir" -maxdepth 1 -type f -name "*.html" | sort -t'_' -k1,1n | while IFS= read -r file; do
    basefile=$(basename "$file")
    echo "        <li><a href=\"$html_dir/$basefile\">$basefile</a></li>" >> "$output_file"
done

# Cerrar las etiquetas HTML
cat <<EOF >> "$output_file"
    </ul>
</body>
</html>
EOF

echo "Archivo '$output_file' generado correctamente."