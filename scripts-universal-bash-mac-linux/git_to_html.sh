#!/bin/bash

# Crear carpeta si no existe
mkdir -p commits_html

# Obtener la cantidad total de commits para numerarlos
total_commits=$(git rev-list --count HEAD)
counter=1

# Leer los commits en un array para evitar problemas con subshells
commits=()
while IFS='|' read -r commit_hash commit_title; do
    commits+=("$commit_hash|$commit_title")
done < <(git log --reverse --pretty=format:"%h|%s")

# Recorrer la lista de commits y generar los archivos HTML
for commit in "${commits[@]}"; do
    IFS='|' read -r commit_hash commit_title <<< "$commit"

    # Reemplazar caracteres especiales en el título del commit para formar el nombre de archivo
    sanitized_title=$(echo "$commit_title" | tr -cd '[:alnum:]-_ ' | tr ' ' '_')

    # Nombre del archivo: número_commit_hash_título.html
    commit_file="commits_html/${counter}_commit_${commit_hash}_${sanitized_title}.html"

    # --- Primera parte: cabecera HTML, estilos y variables (se expande) ---
    cat <<EOF > "$commit_file"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[$counter] Commit $commit_hash - $commit_title</title>
  <style>
    /* Estilos generales */
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: auto;
      padding: 20px;
      background-color: #1e1e1e;
      color: #c9d1d9;
    }
    h2 { 
      color: #58a6ff; 
      border-bottom: 2px solid #30363d; 
      padding-bottom: 5px; 
    }
    h3 { color: #58a6ff; }
    p { margin: 0.5em 0; }
    pre {
      background: #161b22;
      color: #c9d1d9;
      padding: 10px;
      overflow-x: auto;
      border-radius: 5px;
    }
    code { 
      font-family: "Courier New", Courier, monospace; 
    }
    /* Bloques de diff (cada archivo modificado) */
    .file-diff {
      margin-bottom: 20px;
      border: 1px solid #30363d;
      border-radius: 5px;
    }
    .addition {
      color: #28a745;
      background-color: rgba(40, 167, 69, 0.2);
      display: block;
    }
    .deletion {
      color: #d73a49;
      background-color: rgba(215, 58, 73, 0.2);
      display: block;
    }
    /* Personalización de la scrollbar */
    ::-webkit-scrollbar { width: 10px; }
    ::-webkit-scrollbar-thumb {
      background: #30363d;
      border-radius: 5px;
    }
    ::-webkit-scrollbar-track { background: #161b22; }
    ::-webkit-scrollbar-corner { background: transparent; }
    /* Estilos para el buscador en diff */
    #searchInputDiff {
      width: 100%;
      padding: 8px;
      margin-bottom: 10px;
      border: 1px solid #30363d;
      border-radius: 4px;
      background-color: #161b22;
      color: #c9d1d9;
    }
    #searchInputDiff::placeholder {
      color: #8b949e;
    }
  </style>
EOF

    # --- Segunda parte: bloque JavaScript (sin expansión: usar heredoc literal) ---
    cat <<'EOF_JS' >> "$commit_file"
  <script>
    // Función para filtrar los bloques de diff (cada archivo modificado)
    function searchDiffBlocks() {
      var input = document.getElementById("searchInputDiff");
      var filter = input.value.toUpperCase().trim();
      var searchTerms = filter.split(/\s+/);
      var diffBlocks = document.getElementsByClassName("file-diff");
      for (var i = 0; i < diffBlocks.length; i++) {
        var text = diffBlocks[i].textContent || diffBlocks[i].innerText;
        text = text.toUpperCase();
        var match = true;
        for (var j = 0; j < searchTerms.length; j++) {
          if (text.indexOf(searchTerms[j]) === -1) {
            match = false;
            break;
          }
        }
        diffBlocks[i].style.display = match ? "" : "none";
      }
    }
  </script>
EOF_JS

    # --- Tercera parte: continuar con el HTML (se expande) ---
    cat <<EOF >> "$commit_file"
</head>
<body>
EOF

    # Agregar información del commit (encabezado, fecha, autor y mensaje)
    git log -1 --pretty=format:"<h2>[$counter] Commit %h</h2><p><strong>Fecha:</strong> %ad</p><p><strong>Autor:</strong> %an</p><p><strong>Mensaje:</strong> %s</p>" --date=local "$commit_hash" >> "$commit_file"

    # Sección para buscar dentro del diff
    cat <<EOF >> "$commit_file"
<h3>Buscar en diff</h3>
<input type="text" id="searchInputDiff" onkeyup="searchDiffBlocks()" placeholder="Buscar en diff...">
EOF

    # Abrir contenedor de diff
    echo "<div id=\"diffBlocks\">" >> "$commit_file"

    # Obtener el diff del commit, escaparlo y procesarlo para separar cada bloque por archivo
    #
    # Se usa sed para reemplazar caracteres especiales y awk para detectar líneas que comienzan con "diff --git"
    # y envolver cada bloque en un <div class="file-diff">.
    git show "$commit_hash" --color=never | \
      sed -E 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;' | \
      awk 'BEGIN {inBlock=0} 
           /^diff --git/ {
               if (inBlock==1) { print "</code></pre></div>" }
               print "<div class=\"file-diff\"><pre><code class=\"diff\">"
               inBlock=1
           }
           { print }
           END { if (inBlock==1) print "</code></pre></div>" }' >> "$commit_file"

    # Cerrar contenedor diff
    echo "</div>" >> "$commit_file"

    # Cerrar etiquetas HTML
    cat <<EOF >> "$commit_file"
</body>
</html>
EOF

    echo "Archivo creado: $commit_file"
    ((counter++))
done