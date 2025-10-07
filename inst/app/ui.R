library(shiny)
library(shinydashboard)

dashboardPage(
  dashboardHeader(title = "FAET - Análise de Turismo"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Início", tabName = "home", icon = icon("home")),
      menuItem("Importação & Pré-processamento", tabName = "import_preprocess", icon = icon("upload")),
      menuItem("Análise Bibliométrica & Cienciométrica", tabName = "bibliometrics", icon = icon("chart-bar")),
      menuItem("Análise de Redes", tabName = "networks", icon = icon("project-diagram")),
      menuItem("Análise Qualitativa (Bardin)", tabName = "qualitative", icon = icon("comment-dots")),
      menuItem("Modelagem de Tópicos", tabName = "topic_modeling", icon = icon("tags")),
      menuItem("Visualização & Exportação", tabName = "export", icon = icon("download"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "home",
              h2("Bem-vindo ao FAET - Ferramenta de Análise e Exploração de Turismo"),
              p("Este aplicativo é projetado para auxiliar pesquisadores de turismo na realização de revisões sistemáticas, meta-análises, análises bibliométricas, cienciométricas, qualitativas e modelagem de tópicos, de forma intuitiva e didática."),
              p("Utilize o menu lateral para navegar entre os módulos de análise.")
      ),
      tabItem(tabName = "import_preprocess",
              h2("Importação e Pré-processamento de Dados"),
              wellPanel(
                fileInput("file_scopus", "Escolha o arquivo Scopus (.bib)", accept = ".bib"),
                fileInput("file_wos", "Escolha o arquivo Web of Science (.txt ou .bib)", accept = c(".txt", ".bib"), multiple = TRUE),
                actionButton("process_data", "Processar Dados")
              ),
              h3("Dados Importados"),
              tableOutput("imported_data_summary")
      ),
      tabItem(tabName = "bibliometrics",
              h2("Análise Bibliométrica e Cienciométrica"),
              wellPanel(
                selectInput("bib_analysis_type", "Tipo de Análise",
                            choices = c("Produtividade Anual", "Autores Mais Produtivos", "Fontes Mais Relevantes", "Palavras-chave Mais Frequentes", "Índice H"))
              ),
              plotOutput("bibliometric_plot"),
              tableOutput("bibliometric_table")
      ),
      tabItem(tabName = "networks",
              h2("Análise de Redes Científicas"),
              wellPanel(
                selectInput("network_type", "Tipo de Rede",
                            choices = c("Colaboração (Países)", "Colaboração (Autores)", "Colaboração (Instituições)", "Co-citação (Autores)", "Co-citação (Fontes)", "Acoplamento (Autores)", "Acoplamento (Fontes)")),
                numericInput("network_nodes", "Número de Nós (Top N)", value = 30, min = 5, max = 100)
              ),
              plotOutput("network_plot")
      ),
      tabItem(tabName = "qualitative",
              h2("Análise Qualitativa Investigativa (Bardin)"),
              wellPanel(
                actionButton("prepare_corpus", "Preparar Corpus de Resumos"),
                selectInput("stopwords_lang", "Idioma das Stopwords", choices = c("pt", "en"), selected = "pt")
              ),
              h3("Nuvem de Palavras"),
              plotOutput("wordcloud_plot")
      ),
      tabItem(tabName = "topic_modeling",
              h2("Modelagem de Tópicos (LDA)"),
              wellPanel(
                numericInput("num_topics", "Número de Tópicos (k)", value = 5, min = 2, max = 20),
                actionButton("run_lda", "Executar LDA")
              ),
              h3("Termos por Tópico"),
              tableOutput("lda_terms_table")
      ),
      tabItem(tabName = "export",
              h2("Visualização e Exportação"),
              wellPanel(
                downloadButton("download_report", "Baixar Relatório (PDF)"),
                downloadButton("download_plot", "Baixar Gráfico Atual (PNG)")
              )
      )
    )
  )
)

