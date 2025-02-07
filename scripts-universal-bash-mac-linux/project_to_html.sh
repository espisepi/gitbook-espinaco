#!/bin/bash
# Archivo: project_to_html.sh
# Descripción:
#   Recorre recursivamente un directorio de origen y, para cada archivo de texto
#   (excluyendo directorios como .git y node_modules), genera un archivo HTML que
#   muestra su contenido en modo oscuro.
#
#   Se genera un árbol en el directorio de salida que refleja la estructura original,
#   además de un índice global y un index.html en cada subcarpeta para navegar.
#
# Uso:
#   ./project_to_html.sh [directorio_origen] [directorio_salida]
#
# Ejemplo:
#   ./project_to_html.sh ./mi_proyecto html_output
#

# ------------------------------
# Función: generar el HTML de un archivo
generate_file_html() {
    local input_file="$1"
    local output_file="$2"
    local filename
    filename=$(basename "$input_file")
    
    cat <<EOF > "$output_file"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$filename</title>
  <style>
    body {
      background-color: #1e1e1e;
      color: #c9d1d9;
      font-family: monospace;
      padding: 20px;
    }
    pre {
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    a {
      color: #58a6ff;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <h1>$filename</h1>
  <pre>
EOF

    # Escapa caracteres HTML (<, >, &) y añade el contenido del archivo
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$input_file" >> "$output_file"

    cat <<EOF >> "$output_file"
  </pre>
  <p><a href="index.html">Volver al índice</a></p>
</body>
</html>
EOF
}

# ------------------------------
# Función: generar un index.html en cada directorio
generate_index() {
    local dir="$1"
    local index_file="$dir/index.html"
    local current_dir_name
    current_dir_name=$(basename "$dir")
    
    cat <<EOF > "$index_file"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Índice de $current_dir_name</title>
  <style>
    body {
      background-color: #1e1e1e;
      color: #c9d1d9;
      font-family: sans-serif;
      padding: 20px;
    }
    h1 { color: #58a6ff; }
    ul { list-style: none; padding: 0; }
    li { margin-bottom: 8px; }
    a { color: #58a6ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <h1>Índice de $current_dir_name</h1>
EOF

    # Si no estamos en la raíz de la salida, agregamos un enlace al índice global
    if [ "$dir" != "$OUTPUT_DIR" ]; then
      cat <<EOF >> "$index_file"
  <p><a href="../global_index.html">Volver al índice global</a></p>
EOF
    fi

    cat <<EOF >> "$index_file"
  <ul>
EOF

    # Listar subdirectorios (añadiendo "/" al final)
    for subdir in "$dir"/*/ ; do
        if [ -d "$subdir" ]; then
            subdirname=$(basename "$subdir")
            echo "    <li>[DIR] <a href=\"$subdirname/index.html\">$subdirname/</a></li>" >> "$index_file"
        fi
    done

    # Listar archivos HTML (excepto index.html)
    for file in "$dir"/* ; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ "$filename" != "index.html" ]; then
                echo "    <li>[FILE] <a href=\"$filename\">$filename</a></li>" >> "$index_file"
            fi
        fi
    done

    cat <<EOF >> "$index_file"
  </ul>
</body>
</html>
EOF
}

# ------------------------------
# Variables de configuración

# Directorio de origen: primer parámetro o el actual (.)
SOURCE_DIR="${1:-.}"
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: El directorio de origen '$SOURCE_DIR' no existe."
  exit 1
fi
# Obtenemos la ruta absoluta del directorio de origen
SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)

# Directorio de salida: segundo parámetro o "html_output"
OUTPUT_DIR="${2:-html_output}"
# Creamos OUTPUT_DIR y obtenemos su ruta absoluta
if ! mkdir -p "$OUTPUT_DIR" 2>/dev/null; then
    echo "Error: No se pudo crear el directorio de salida '$OUTPUT_DIR'. ¿Tienes permisos de escritura?"
    exit 1
fi
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

# Verificar que SOURCE_DIR y OUTPUT_DIR sean distintos
if [ "$SOURCE_DIR" = "$OUTPUT_DIR" ]; then
    echo "El directorio de salida no puede ser el mismo que el de origen."
    exit 1
fi

echo "Generando archivos HTML a partir de los archivos en '$SOURCE_DIR'..."
pushd "$SOURCE_DIR" > /dev/null

# ------------------------------
# Excluir directorios que no queremos procesar (por ejemplo, .git y node_modules)
EXCLUDES=(-not -path "./.git/*" -not -path "./node_modules/*")

# Recorrer recursivamente los archivos (excluyendo los directorios indicados)
find . -type f "${EXCLUDES[@]}" | while read -r file; do
    # Eliminar el prefijo "./" para obtener la ruta relativa
    relpath="${file#./}"
    input_file="$SOURCE_DIR/$relpath"
    # Si el archivo ya termina en .html, no se le agrega de nuevo la extensión
    if [[ "$relpath" == *.html ]]; then
        output_file="$OUTPUT_DIR/$relpath"
    else
        output_file="$OUTPUT_DIR/$relpath.html"
    fi
    output_dir_for_file=$(dirname "$output_file")
    mkdir -p "$output_dir_for_file"
    generate_file_html "$input_file" "$output_file"
    echo "Generado: $output_file"
done

popd > /dev/null

# ------------------------------
# Generar índices locales en cada carpeta del directorio de salida
echo "Generando índices locales en cada carpeta..."
find "$OUTPUT_DIR" -type d | while read -r dir; do
    generate_index "$dir"
    echo "Índice generado en: $dir/index.html"
done

# ------------------------------
# Generar el índice global en la raíz de OUTPUT_DIR
global_index="$OUTPUT_DIR/global_index.html"
echo "Generando índice global en: $global_index"
cat <<EOF > "$global_index"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Índice Global de Archivos</title>
  <style>
    body {
      background-color: #1e1e1e;
      color: #c9d1d9;
      font-family: sans-serif;
      padding: 20px;
    }
    h1 { color: #58a6ff; }
    ul { list-style: none; padding: 0; }
    li { margin-bottom: 8px; }
    a { color: #58a6ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <h1>Índice Global de Archivos</h1>
  <ul>
    <li><a href="index.html">[RAÍZ] Índice local de la raíz</a></li>
EOF

pushd "$OUTPUT_DIR" > /dev/null
find . -type f -name "*.html" | while read -r file; do
    # file tendrá el formato "./ruta/archivo.html"; se elimina el prefijo "./"
    file="${file#./}"
    base=$(basename "$file")
    if [[ "$base" == "index.html" || "$base" == "global_index.html" ]]; then
        continue
    fi
    echo "    <li>[FILE] <a href=\"$file\">$file</a></li>" >> "$global_index"
done
popd > /dev/null

cat <<EOF >> "$global_index"
  </ul>
</body>
</html>
EOF

echo "Proceso completado."
echo "Abre '$global_index' en tu navegador para ver el índice global."