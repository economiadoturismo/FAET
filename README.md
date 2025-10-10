# FAET - Ferramenta de Análise em Estudos do Turismo


O **FAET** (Ferramenta de Análise e Exploração de Turismo) é um pacote R e um aplicativo Shiny projetado para auxiliar pesquisadores da área de turismo na realização de análises complexas de literatura científica. Ele oferece uma abordagem integrada para:

*   **Revisão Sistemática e Meta-análise**
*   **Análise Bibliométrica e Cienciométrica**
*   **Análise Qualitativa Investigativa (Bardin)**
*   **Modelagem de Tópicos (LDA)**

Com uma interface gráfica intuitiva e didática, o FAET visa democratizar o acesso a metodologias avançadas, permitindo que usuários sem conhecimento aprofundado em programação R possam gerar visualizações de alta qualidade e insights valiosos para suas pesquisas.

## Funcionalidades Principais

*   **Importação e Pré-processamento de Dados**: Suporte para bases de dados como Scopus e Web of Science, com funcionalidades de mesclagem, deduplicação e limpeza.
*   **Análise Bibliométrica e Cienciométrica**: Métricas de produtividade, análise de citações (h-index), crescimento anual e co-ocorrência de palavras-chave.
*   **Análise de Redes Científicas**: Visualização de redes de colaboração (autores, instituições, países), co-citação e acoplamento bibliográfico.
*   **Análise Qualitativa (Bardin)**: Preparação de corpus textual, análise de frequência e nuvens de palavras.
*   **Modelagem de Tópicos**: Identificação de temas latentes em grandes volumes de texto usando LDA.
*   **Visualização Avançada**: Geração de gráficos interativos e estáticos de alta qualidade, incluindo mapas geográficos.
*   **Exportação de Resultados**: Opções para exportar dados, gráficos e relatórios em diversos formatos.

## Instalação

Para instalar e executar o FAET, siga os passos abaixo:

1.  **Instale o R e o RStudio** (se ainda não tiver):
    *   R: [https://cran.r-project.org/](https://cran.r-project.org/)
    *   RStudio Desktop: [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)

2.  **Clone o repositório**:
    Abra o RStudio (ou seu terminal) e execute:
    ```bash
    git clone https://github.com/economiadoturismo/FAET.git
    ```

3.  **Instale os pacotes R necessários**:
    Abra o RStudio, navegue até o diretório `FAET` que você clonou e execute o seguinte comando no console R:
    ```R
    install.packages(c(
      'shiny', 'shinydashboard', 'bibliometrix', 'quanteda', 'topicmodels',
      'ggplot2', 'igraph', 'plotly', 'dplyr', 'stringr', 'maps', 'viridis',
      'metagear', 'meta', 'wordcloud', 'RColorBrewer', 'quanteda.textstats',
      'shinyWidgets', 'magrittr'
    ), repos='https://cran.rstudio.com/')
    ```

4.  **Execute o aplicativo Shiny**:
    No RStudio, você pode abrir o arquivo `FAET/inst/app/ui.R` ou `FAET/inst/app/server.R` e clicar no botão "Run App" no canto superior direito. Alternativamente, execute os seguintes comandos no console R:
    ```R
    library(shiny)
    runApp("FAET/inst/app")
    ```

## Como Contribuir

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues para bugs ou sugestões de novas funcionalidades, ou enviar pull requests.

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Contato

Para dúvidas ou sugestões, entre em contato com [Manus AI](mailto:manus.ai@example.com).

