## Explicação do Script de OSINT

Este código faz parte de um script de OSINT (Open Source Intelligence) que busca por um usuário específico em múltiplas plataformas online. Abaixo está uma explicação de cada parte:

### Inicialização das Estruturas de Dados

- O script inicializa duas variáveis principais para criar um grafo de relacionamentos:
    - `nodes`: começa com um nó central representando o usuário pesquisado, formatado como objeto JSON compatível com bibliotecas de visualização de grafos (ex: Cytoscape.js).
    - `edges`: inicia vazia e armazenará as conexões entre o usuário e os sites onde ele for encontrado.

### Processamento do Arquivo de Sites

- Um loop `while` processa o arquivo `sites.json`, que contém uma lista de sites e seus templates de URL.
- O comando `jq` converte o JSON em linhas de texto no formato "chave valor", onde cada linha representa um site e seu template de URL.
- Para cada linha, o script extrai:
    - O nome do site: `awk '{print $1}'`
    - O template da URL: `awk '{print $2}'`

### Substituição Dinâmica de Parâmetros

- O trecho `${urlTemplate//\{\}/$usuario}` faz a substituição de todos os placeholders `{}` no template da URL pelo nome do usuário real, usando a funcionalidade de substituição de strings do Bash.
- Isso permite reutilizar o mesmo template para diferentes usuários.

### Verificação de Existência do Perfil

- Para cada URL gerada, o script utiliza `curl` com as flags:
    - `-s` (silencioso)
    - `-o /dev/null` (descarta o conteúdo)
    - `-w "%{http_code}"` (retorna apenas o código de status HTTP)
- Se o código retornado for `200`, significa que o perfil do usuário existe naquele site.

### Saída Multi-formato

- Quando um usuário é encontrado, o script gera saídas em múltiplos formatos:
    - Exibe uma mensagem colorida no terminal
    - Salva em um arquivo temporário
    - Adiciona uma linha ao arquivo CSV
    - Insere uma linha de tabela HTML
    - Mostra uma mensagem formatada com `toilet`
    - Atualiza as estruturas de dados do grafo adicionando um novo nó e uma aresta

### Pontos de Atenção

- Um ponto importante é que o código assume que um HTTP 200 sempre indica que o usuário existe, mas alguns sites podem retornar 200 mesmo para usuários inexistentes (exibindo uma página de "usuário não encontrado").
- O script não implementa rate limiting, o que pode resultar em bloqueio por parte dos sites se executado muito rapidamente.