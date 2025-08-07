#!/bin/bash

# Verifica se o usuário foi passado como parâmetro
if [ -z "$1" ]; then
  echo "Uso: $0 <usuario>"
  exit 1
fi

usuario=$1

# Verifica se o jq está instalado
if ! command -v jq &> /dev/null; then
  echo "jq não está instalado. Instale-o usando 'sudo apt-get install jq'."
  exit 1
fi

# Exibe o splash screen com ASCII art usando toilet
clear
toilet -f mono12 -F metal "WB-OSINTBY LINUX 2025"
sleep 2

# Cria um arquivo temporário para armazenar os resultados
temp_file=$(mktemp)

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

# Caminho para o arquivo sites.json
sites_file="./sites.json"

# Verifica se o arquivo sites.json existe e é legível
if [ ! -r "$sites_file" ]; then
  echo "Arquivo $sites_file não encontrado ou não é legível."
  exit 1
fi

# Nome dos arquivos com data e hora
timestamp=$(date +"%Y%m%d_%H%M%S")
csv_file="${usuario}_${timestamp}.csv"
html_file="${usuario}_${timestamp}.html"

# Cabeçalho do arquivo CSV
echo "Site,URL,Status" > "$csv_file"

# Cabeçalho do arquivo HTML com CSS estilizado
echo "<html><head><title>Relatório de Busca de Usuário</title><script src='https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js'></script><style>
body {
  font-family: Arial, sans-serif;
  background-color: #f4f4f9;
  color: #333;
  margin: 0;
  padding: 0;
}
h1 {
  text-align: center;
  color: #444;
}
table {
  width: 80%;
  margin: 20px auto;
  border-collapse: collapse;
  box-shadow: 0 2px 3px rgba(0,0,0,0.1);
}
table th, table td {
  padding: 10px;
  border: 1px solid #ddd;
  text-align: left;
}
table th {
  background-color: #f4f4f9;
  color: #555;
}
table tr:nth-child(even) {
  background-color: #f9f9f9;
}
table tr:hover {
  background-color: #f1f1f1;
}
#cy {
  width: 90%;
  height: 700px;
  margin: 20px auto;
  border: 1px solid #ddd;
  box-shadow: 0 2px 3px rgba(0,0,0,0.1);
}
</style></head><body><h1>Relatório de Busca de Usuário</h1><table><tr><th>Site</th><th>URL</th><th>Status</th></tr>" > "$html_file"

# Variáveis globais para armazenar dados do grafo
nodes="[ { data: { id: '$usuario', label: '$usuario' } }"
edges=""

# Lê o arquivo sites.json e substitui {} pelo usuário
while IFS= read -r line; do
  site=$(echo "$line" | awk '{print $1}')
  urlTemplate=$(echo "$line" | awk '{print $2}')
  url="${urlTemplate//\{\}/$usuario}"
  echo "Verificando $site: $url"
  status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status_code" -eq 200 ]; then
    echo -e "${GREEN}Usuário encontrado em $site: $url${NC}" | tee -a "$temp_file"
    echo "$site,$url,Usuário encontrado" >> "$csv_file"
    echo "<tr><td>$site</td><td><a href='$url'>$url</a></td><td>Usuário encontrado</td></tr>" >> "$html_file"
    toilet -f term -F border "Usuário encontrado em $site"
    nodes+=", { data: { id: '$url', label: '$site' } }"
    edges+=", { data: { source: '$usuario', target: '$url' } }"
  else
    echo -e "${RED}Usuário não encontrado em $site: $url${NC}" | tee -a "$temp_file"
  fi
done < <(jq -r 'to_entries[] | "\(.key) \(.value)"' "$sites_file")

# Remove a última vírgula dos edges
edges=${edges#,}

# Finaliza o arquivo HTML
echo "</table>" >> "$html_file"

# Adiciona o grafo ao arquivo HTML
cat <<EOT >> "$html_file"
<h2>Grafo de Conexões</h2>
<div id="cy"></div>
<script>
  var cy = cytoscape({
    container: document.getElementById('cy'),
    elements: {
      nodes: $nodes ],
      edges: [ $edges ]
    },
    style: [
      {
        selector: 'node',
        style: {
          'label': 'data(label)',
          'text-valign': 'center',
          'color': '#000',
          'background-color': '#61bffc',
          'border-width': 2,
          'border-color': '#000'
        }
      },
      {
        selector: 'edge',
        style: {
          'label': 'data(label)',
          'width': 2,
          'line-color': '#ccc',
          'target-arrow-color': '#ccc',
          'target-arrow-shape': 'triangle',
          'curve-style': 'bezier'
        }
      }
    ],
    layout: {
      name: 'cose',
      padding: 10
    }
  });

  cy.on('tap', 'edge', function(evt){
    var edge = evt.target;
    window.open(edge.data('label'), '_blank');
  });
</script>
</body></html>
EOT

# Remove o arquivo temporário
rm "$temp_file"

echo "Relatório gerado: $csv_file"
echo "Relatório gerado: $html_file"
echo "Abrindo relatório em um navegador..."
xdg-open "$html_file"