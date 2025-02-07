#!/bin/bash
# Archivo: generar_html_proyecto.sh
# Descripción:
#   Recorre recursivamente el directorio de origen y genera, en un directorio de salida,
#   un archivo HTML por cada archivo (mostrando su contenido en modo oscuro y con scroll
#   horizontal y vertical cuando sea necesario).
#   Además, en cada carpeta se crea un index.html para facilitar la navegación entre
#   los archivos HTML generados.
#
# Uso:
#   ./generar_html_proyecto.sh [directorio_origen] [directorio_salida]
#
#   Si no se indican parámetros:
#     - directorio_origen se asume como el directorio actual (.)
#     - directorio_salida se crea en "html_output"
#
# Ejemplo:
#   ./generar_html_proyecto.sh src mi_salida_html
#

# --- Función para generar el HTML que muestra el contenido de un archivo ---
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
      font-family: Arial, sans-serif; 
      max-width: 800px;
      margin: auto;
      padding: 20px; 
      background-color: #1e1e1e; 
      color: #c9d1d9;  
    }
    h1 { 
      color: #58a6ff;
      border-bottom: 2px solid #30363d;
      padding-bottom: 5px;
    }
    pre { 
      background: #161b22; 
      color: #c9d1d9; 
      padding: 10px; 
      overflow: auto; /* Scroll horizontal y vertical */
      border-radius: 5px;
      white-space: pre; /* Respetar saltos de línea originales */
    }
    a {
      color: #58a6ff;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    .button-return {
      position: fixed;
      bottom: 0.5rem;
    }
    /* Scrollbar personalizado */
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
</head>
<body>
  <h1>$filename</h1>
    <p><a href="index.html">Volver al índice</a></p>
  <pre>
EOF

    # Se escapan los caracteres HTML especiales y se añade el contenido del archivo.
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$input_file" >> "$output_file"

    cat <<EOF >> "$output_file"
  </pre>
  <p><a class="button-return" href="index.html">Volver al índice</a></p>
</body>
</html>
EOF
}

# --- Función para generar un index.html en una carpeta dada ---
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
      font-family: Arial, sans-serif; 
      max-width: 800px;
      margin: auto;
      padding: 20px;
      background-color: #1e1e1e;
      color: #c9d1d9;
    }
    h1 { 
      color: #58a6ff;
      border-bottom: 2px solid #30363d;
      padding-bottom: 5px;
    }
    ul {
      list-style: none;
      padding: 0;
    }
    li {
      margin-bottom: 8px;
    }
    a {
      color: #58a6ff;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
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
</head>
<body>
  <h1>Índice de $current_dir_name</h1>
EOF

    # Si no estamos en la raíz del directorio de salida, se añade un enlace para subir un nivel
    if [ "$dir" != "$OUTPUT_DIR" ]; then
        cat <<EOF >> "$index_file"
  <p><a href="../index.html">Subir un nivel</a></p>
EOF
    fi

    cat <<EOF >> "$index_file"
  <ul>
EOF

    # Listar subdirectorios (se añade "/" al final para indicar que es directorio)
    for subdir in "$dir"/*/ ; do
        if [ -d "$subdir" ]; then
            subdirname=$(basename "$subdir")
            echo "    <li>[DIR] <a href=\"$subdirname/index.html\">$subdirname/</a></li>" >> "$index_file"
        fi
    done

    # Listar archivos HTML generados (se omite el index.html)
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

# --- Variables de configuración ---
# Directorio de origen: primer parámetro o el directorio actual (.)
SOURCE_DIR="${1:-.}"
# Directorio de salida: segundo parámetro o "html_output"
OUTPUT_DIR="${2:-html_output}"

# Se obtienen las rutas absolutas para comprobar que no sean iguales
SOURCE_DIR_ABS=$(realpath "$SOURCE_DIR")
OUTPUT_DIR_ABS=$(realpath -m "$OUTPUT_DIR")
if [ "$SOURCE_DIR_ABS" = "$OUTPUT_DIR_ABS" ]; then
    echo "El directorio de salida no puede ser el mismo que el de origen."
    exit 1
fi

# Se elimina el directorio de salida si existe y se crea de nuevo
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Generando archivos HTML a partir de los archivos en '$SOURCE_DIR'..."

# Se cambia al directorio de origen para trabajar con rutas relativas
pushd "$SOURCE_DIR" > /dev/null

# Se recorre recursivamente cada archivo (find lista rutas relativas comenzando con "./")
find . -type f | while read -r file; do
    # Se elimina el prefijo "./" para obtener la ruta relativa limpia
    relpath="${file#./}"
    # Ruta completa del archivo de origen
    input_file="$SOURCE_DIR/$relpath"
    # Se genera la ruta de salida correspondiente; se le añade la extensión .html
    output_file="$OUTPUT_DIR/$relpath.html"
    # Se crea el directorio donde irá el archivo HTML generado
    output_dir_for_file=$(dirname "$output_file")
    mkdir -p "$output_dir_for_file"
    # Se genera el HTML para el archivo actual
    generate_file_html "$input_file" "$output_file"
    echo "Generado: $output_file"
done

popd > /dev/null

echo "Generando archivos index.html para la navegación..."

# Se recorre cada directorio (en el árbol de salida) y se genera un index.html
find "$OUTPUT_DIR" -type d | while read -r dir; do
    generate_index "$dir"
    echo "Índice generado en: $dir/index.html"
done

echo "Proceso completado. Revisa el directorio '$OUTPUT_DIR' para ver los archivos HTML generados."