#!/bin/bash

# Crear carpeta si no existe
mkdir -p commits_html

# Obtener la cantidad total de commits para numerarlos
total_commits=$(git rev-list --count HEAD)
counter=1

# Leer los commits en un array para evitar el problema del subshell
commits=()
while IFS='|' read -r commit_hash commit_title; do
    commits+=("$commit_hash|$commit_title")
done < <(git log --reverse --pretty=format:"%h|%s")

# Recorrer la lista de commits y generar los archivos HTML
for commit in "${commits[@]}"; do
    IFS='|' read -r commit_hash commit_title <<< "$commit"

    # Reemplazar caracteres especiales en el título del commit
    sanitized_title=$(echo "$commit_title" | tr -cd '[:alnum:]-_ ' | tr ' ' '_')

    # Nombre del archivo con número de commit + hash + título del commit
    commit_file="commits_html/${counter}_commit_${commit_hash}_${sanitized_title}.html"

    cat <<EOF > "$commit_file"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[$counter] Commit $commit_hash - $commit_title</title>
    <style>
        /* Modo Oscuro */
        body { 
            font-family: Arial, sans-serif; 
            max-width: 800px; 
            margin: auto; 
            padding: 20px; 
            background-color: #1e1e1e;  /* Fondo oscuro */
            color: #c9d1d9;  /* Texto claro */
        }
        h2 { 
            color: #58a6ff;  /* Azul claro */
            border-bottom: 2px solid #30363d; 
            padding-bottom: 5px;
        }
        pre { 
            background: #161b22;  /* Fondo más oscuro */
            color: #c9d1d9;  /* Texto claro */
            padding: 10px; 
            overflow-x: auto; 
            border-radius: 5px;
        }
        code { 
            font-family: "Courier New", Courier, monospace; 
        }
        .diff { 
            white-space: pre-wrap; 
            display: block;
            padding: 2rem 0.5rem;
            border: solid 1px;
            border-radius: 5px;
            overflow: scroll;
        }
        .addition { 
            color: #28a745;  /* Verde */
            background-color: rgba(40, 167, 69, 0.2); /* Verde con transparencia */
            display: block;
        }
        .deletion { 
            color: #d73a49;  /* Rojo */
            background-color: rgba(215, 58, 73, 0.2); /* Rojo con transparencia */
            display: block;
        }
        /* Barra de scroll personalizada */
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

EOF

    # Agregar información del commit
    git log -1 --pretty=format:"<h2>[$counter] Commit %h</h2><p><strong>Fecha:</strong> %ad</p><p><strong>Autor:</strong> %an</p><p><strong>Mensaje:</strong> %s</p>" --date=local "$commit_hash" >> "$commit_file"

    echo "<pre><code class='diff'>" >> "$commit_file"

    # Agregar los cambios del commit escapando caracteres HTML
    git show "$commit_hash" --color=never | sed -E 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;' >> "$commit_file"

    echo "</code></pre>" >> "$commit_file"

    # Agregar JavaScript para resaltar cambios correctamente
    cat <<EOF >> "$commit_file"
<script>
    document.addEventListener("DOMContentLoaded", function() {
        const bodyText = document.body.innerHTML;
        const diffRegex = /diff[\\s\\S]+?(?=\\ndiff|\\s*\$)/g; // Captura bloques enteros de diff hasta el siguiente o el final

        const formattedText = bodyText.replace(diffRegex, function (match) {
            return \`<pre><code class="diff">\${match.replace(/</g, "&lt;").replace(/>/g, "&gt;")}</code></pre>\`;
        });

        document.body.innerHTML = formattedText;

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
