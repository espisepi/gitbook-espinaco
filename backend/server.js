const express = require("express");
const cors = require("cors");
const { exec } = require("child_process");
const path = require("path");

const app = express();
const PORT = 3000;

// 🔹 Ruta del repositorio (¡CÁMBIALA antes de ejecutar!)
const repoPath = "/ruta/del/repositorio";

app.get("/generate-commits", (req, res) => {
    const script = `
    #!/bin/bash
    mkdir -p commits_html

    total_commits=$(git rev-list --count HEAD)
    counter=1

    git log --reverse --pretty=format:"%h|%s" | while IFS='|' read -r commit_hash commit_title; do
        sanitized_title=$(echo "$commit_title" | tr -cd '[:alnum:]-_ ' | tr ' ' '_')
        commit_file="commits_html/${counter}_commit_${commit_hash}_${sanitized_title}.html"

        cat <<EOF > "$commit_file"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[$counter] Commit $commit_hash - $commit_title</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: auto; padding: 20px; background-color: #1e1e1e; color: #c9d1d9; }
        h2 { color: #58a6ff; border-bottom: 2px solid #30363d; padding-bottom: 5px; }
        pre { background: #161b22; color: #c9d1d9; padding: 10px; overflow-x: auto; border-radius: 5px; }
        code { font-family: "Courier New", Courier, monospace; }
        .diff { white-space: pre-wrap; display: block; padding: 2rem 0.5rem; border: solid 1px; border-radius: 5px; overflow: scroll; }
        .addition { color: #28a745; background-color: rgba(40, 167, 69, 0.2); display: block; }
        .deletion { color: #d73a49; background-color: rgba(215, 58, 73, 0.2); display: block; }
        ::-webkit-scrollbar { width: 10px; }
        ::-webkit-scrollbar-thumb { background: #30363d; border-radius: 5px; }
        ::-webkit-scrollbar-track { background: #161b22; }
        ::-webkit-scrollbar-corner { background: transparent; }
    </style>
</head>
<body>

EOF

        git log -1 --pretty=format:"<h2>[$counter] Commit %h</h2><p><strong>Fecha:</strong> %ad</p><p><strong>Autor:</strong> %an</p><p><strong>Mensaje:</strong> %s</p>" --date=local "$commit_hash" >> "$commit_file"

        echo "<pre><code class='diff'>" >> "$commit_file"
        git show "$commit_hash" --color=never | sed 's/&/\\&amp;/g; s/</\\&lt;/g; s/>/\\&gt;/g;' >> "$commit_file"
        echo "</code></pre>" >> "$commit_file"

        cat <<EOF >> "$commit_file"
<script>
    document.addEventListener("DOMContentLoaded", function() {
        document.querySelectorAll("code.diff").forEach(function (block) {
            let lines = block.innerHTML.split("\\n").map(line => {
                if (line.startsWith("+")) { return \`<span class='addition'>\${line}</span>\`; }
                else if (line.startsWith("-")) { return \`<span class='deletion'>\${line}</span>\`; }
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
        counter=$((counter + 1))
    done
    `;

    exec(`bash -c '${script}'`, { cwd: repoPath, shell: "/bin/bash" }, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        res.json({ message: "Archivos HTML generados con éxito.", output: stdout });
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
