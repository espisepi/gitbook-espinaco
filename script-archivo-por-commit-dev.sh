#!/bin/bash

# Crear la carpeta de salida de commits
mkdir -p commits_html || exit 1  # Verifica si la carpeta se creó correctamente

# Obtener la cantidad total de commits para numerarlos
total_commits=$(git rev-list --count HEAD)
counter=1

# Extraer el log de Git en un formato estructurado
commits=$(git log --reverse --pretty=format:"%h|%s")

for commit in $commits; do
    # Dividir el commit en hash y título
    commit_hash=$(echo "$commit" | cut -d'|' -f1)
    commit_title=$(echo "$commit" | cut -d'|' -f2-)

    # Asegurar que el nombre del archivo sea válido en todos los sistemas
    sanitized_title=$(echo "$commit_title" | tr -cd '[:alnum:]-_' | tr ' ' '_')

    # Nombre del archivo HTML generado
    commit_file="commits_html/${counter}_commit_${commit_hash}_${sanitized_title}.html"

    # Crear el archivo HTML con información del commit
    cat <<EOF > "$commit_file"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[$counter] Commit $commit_hash - $commit_title</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #1e1e1e; color: #c9d1d9; padding: 20px; }
        h2 { color: #58a6ff; border-bottom: 2px solid #30363d; padding-bottom: 5px; }
        pre { background: #161b22; padding: 10px; overflow-x: auto; border-radius: 5px; }
        .diff { white-space: pre-wrap; display: block; padding: 2rem 0.5rem; border: solid 1px; border-radius: 5px; overflow: scroll; }
        .addition { color: #28a745; background-color: rgba(40, 167, 69, 0.2); display: block; }
        .deletion { color: #d73a49; background-color: rgba(215, 58, 73, 0.2); display: block; }
    </style>
</head>
<body>
EOF

    # Agregar detalles del commit
    git log -1 --pretty=format:"<h2>[$counter] Commit %h</h2><p><strong>Fecha:</strong> %ad</p><p><strong>Autor:</strong> %an</p><p><strong>Mensaje:</strong> %s</p>" --date=local "$commit_hash" >> "$commit_file"

    echo "<pre><code class='diff'>" >> "$commit_file"

    # Agregar los cambios del commit escapando caracteres HTML
    git show "$commit_hash" --color=never | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;' >> "$commit_file"

    echo "</code></pre>" >> "$commit_file"

    cat <<EOF >> "$commit_file"
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.querySelectorAll("code.diff").forEach(function (block) {
            let lines = block.innerHTML.split("\\n").map(line => {
                if (line.startsWith("+")) {
                    return \`<span class='addition'>\${line}</span>\`;
                } else if (line.startsWith("-")) {
                    return \`<span class='deletion'>\${line}</span>\`;
                }
                return line;
            });
            block.innerHTML = lines.join("\\n");
        });
    });
</script>
</body>
</html>
EOF

    echo "Archivo creado: $commit_file"

    # Incrementar el contador
    ((counter++))

done
