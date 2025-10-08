library(shiny)
library(shinydashboard)
library(shinyWidgets) # Para switchInput

dashboardPage(
  dashboardHeader(title = "FAET - Análise de Turismo",
                  # Adicionar um seletor para o modo didático/avançado no cabeçalho
                  tags$li(class = "dropdown",
                          switchInput(
                            inputId = "didactic_mode",
                            label = "Modo Didático",
                            value = TRUE, # Iniciar no modo didático por padrão
                            onStatus = "success", offStatus = "danger",
                            size = "mini", labelWidth = "80px"
                          )
                  )
  ),
  dashboardSidebar(
    sidebarMenu(id = "tabs",
      menuItem("Início", tabName = "home", icon = icon("home"), selected = TRUE),
      menuItem("1. Importação & Pré-processamento", tabName = "import_preprocess", icon = icon("upload")),
      menuItem("2. Análise Bibliométrica & Cienciométrica", tabName = "bibliometrics", icon = icon("chart-bar")),
      menuItem("3. Análise de Redes", tabName = "networks", icon = icon("project-diagram")),
      menuItem("4. Análise Qualitativa (Bardin)", tabName = "qualitative", icon = icon("comment-dots")),
      menuItem("5. Modelagem de Tópicos", tabName = "topic_modeling", icon = icon("tags")),
      menuItem("6. Meta-análise", tabName = "meta_analysis", icon = icon("chart-pie")),
      menuItem("7. Visualização & Exportação", tabName = "export", icon = icon("download"))
    ),
    # Placeholder para o cronograma visual de etapas (exemplo simplificado)
    div(style = "padding: 15px;",
        h4("Progresso da Análise"),
        uiOutput("progress_timeline")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "home",
              h2("Bem-vindo ao FAET - Ferramenta de Análise e Exploração de Turismo"),
              p("Este aplicativo é projetado para auxiliar pesquisadores de turismo na realização de revisões sistemáticas, meta-análises, análises bibliométricas, cienciométricas, qualitativas e modelagem de tópicos, de forma intuitiva e didática."),
              p("Utilize o menu lateral para navegar entre os módulos de análise, seguindo o cronograma de etapas. Ative o 'Modo Didático' para obter explicações e dicas contextuais."),
              h3("Como Começar:"),
              tags$ol(
                tags$li("Vá para '1. Importação & Pré-processamento' para carregar seus dados."),
                tags$li("Siga as etapas sequencialmente para realizar suas análises."),
                tags$li("No 'Modo Didático', você encontrará explicações e dicas úteis em cada seção.")
              )
      ),
      tabItem(tabName = "import_preprocess",
              h2("1. Importação e Pré-processamento de Dados"),
              uiOutput("didactic_text_import"), # Placeholder para texto didático
              wellPanel(
                fileInput("file_scopus", "Escolha o arquivo Scopus (.bib)", accept = ".bib"),
                fileInput("file_wos", "Escolha o arquivo Web of Science (.txt ou .bib)", accept = c(".txt", ".bib"), multiple = TRUE),
                actionButton("process_data", "Processar Dados", icon = icon("cogs"))
              ),
              h3("Dados Importados"),
              tableOutput("imported_data_summary")
      ),
      tabItem(tabName = "bibliometrics",
              h2("2. Análise Bibliométrica e Cienciométrica"),
              uiOutput("didactic_text_bibliometrics"), # Placeholder para texto didático
              wellPanel(
                selectInput("bib_analysis_type", "Tipo de Análise",
                            choices = c("Produtividade Anual", "Autores Mais Produtivos", "Fontes Mais Relevantes", "Palavras-chave Mais Frequentes", "Índice H"))
              ),
              plotOutput("bibliometric_plot"),
              tableOutput("bibliometric_table")
      ),
      tabItem(tabName = "networks",
              h2("3. Análise de Redes Científicas"),
              uiOutput("didactic_text_networks"), # Placeholder para texto didático
              wellPanel(
                selectInput("network_type", "Tipo de Rede",
                            choices = c("Colaboração (Países)", "Colaboração (Autores)", "Colaboração (Instituições)", "Co-citação (Autores)", "Co-citação (Fontes)", "Acoplamento (Autores)", "Acoplamento (Fontes)")),
                numericInput("network_nodes", "Número de Nós (Top N)", value = 30, min = 5, max = 100)
              ),
              plotOutput("network_plot")
      ),
      tabItem(tabName = "qualitative",
              h2("4. Análise Qualitativa Investigativa (Bardin)"),
              uiOutput("didactic_text_qualitative"), # Placeholder para texto didático
              wellPanel(
                actionButton("prepare_corpus", "Preparar Corpus de Resumos", icon = icon("file-alt")),
                selectInput("stopwords_lang", "Idioma das Stopwords", choices = c("pt", "en"), selected = "pt")
              ),
              h3("Nuvem de Palavras"),
              plotOutput("wordcloud_plot")
      ),
      tabItem(tabName = "topic_modeling",
              h2("5. Modelagem de Tópicos (LDA)"),
              uiOutput("didactic_text_topic_modeling"), # Placeholder para texto didático
              wellPanel(
                numericInput("num_topics", "Número de Tópicos (k)", value = 5, min = 2, max = 20),
                actionButton("run_lda", "Executar LDA", icon = icon("brain"))
              ),
              h3("Termos por Tópico"),
              tableOutput("lda_terms_table")
      ),
      tabItem(tabName = "meta_analysis",
              h2("6. Meta-análise"),
              uiOutput("didactic_text_meta_analysis"), # Placeholder para texto didático
              wellPanel(
                p("Este módulo permitirá a triagem de estudos, extração de dados e execução de meta-análises. Funcionalidades a serem implementadas."),
                actionButton("start_meta_analysis", "Iniciar Meta-análise (Em Desenvolvimento)", icon = icon("flask"))
              ),
              h3("Resultados da Meta-análise"),
              plotOutput("forest_plot"),
              plotOutput("funnel_plot")
      ),
      tabItem(tabName = "export",
              h2("7. Visualização e Exportação"),
              uiOutput("didactic_text_export"), # Placeholder para texto didático
              wellPanel(
                downloadButton("download_report", "Baixar Relatório Completo (PDF)", icon = icon("file-pdf")),
                downloadButton("download_plot", "Baixar Gráfico Atual (PNG)", icon = icon("image"))
              )
      )
    )
  )
)

