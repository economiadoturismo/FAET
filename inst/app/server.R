library(shiny)
library(shinydashboard)
library(bibliometrix)
library(quanteda)
library(topicmodels)
library(ggplot2)
library(igraph)
library(plotly)
library(dplyr)
library(stringr)
library(maps)
library(viridis)

# Source R functions (these files will be created in FAET/R/)
# source("../../R/data_import.R")
# source("../../R/bibliometrics.R")
# source("../../R/network_analysis.R")
# source("../../R/qualitative_analysis.R")
# source("../../R/topic_modeling.R")
# source("../../R/visualization.R")

server <- function(input, output, session) {

  # Reactive value to store the merged dataframe M
  rv <- reactiveValues(M = NULL, corpus = NULL, dfm = NULL)

  # --- Módulo de Importação e Pré-processamento ---
  observeEvent(input$process_data, {
    req(input$file_scopus, input$file_wos)

    # Placeholder for data import and merge logic
    # In a real package, these would call functions from data_import.R
    withProgress(message = 'Processando dados...', value = 0, {
      incProgress(0.2, detail = "Importando Scopus...")
      scopus_df <- tryCatch({
        convert2df(file = input$file_scopus$datapath, dbsource = "scopus", format = "bibtex")
      }, error = function(e) {
        showNotification(paste("Erro ao importar Scopus:", e$message), type = "error")
        return(NULL)
      })

      incProgress(0.4, detail = "Importando Web of Science...")
      wos_df <- tryCatch({
        # Handle multiple WoS files if necessary, for simplicity, taking the first one
        convert2df(file = input$file_wos$datapath[1], dbsource = "wos", format = "plaintext")
      }, error = function(e) {
        showNotification(paste("Erro ao importar WoS:", e$message), type = "error")
        return(NULL)
      })

      if (!is.null(scopus_df) && !is.null(wos_df)) {
        incProgress(0.6, detail = "Mesclando e deduplicando...")
        rv$M <- tryCatch({
          mergeDbSources(scopus_df, wos_df, remove.duplicated = TRUE, verbose = FALSE)
        }, error = function(e) {
          showNotification(paste("Erro ao mesclar dados:", e$message), type = "error")
          return(NULL)
        })
        if (!is.null(rv$M)) {
          showNotification("Dados importados e processados com sucesso!", type = "success")
        }
      } else if (!is.null(scopus_df)) {
        rv$M <- scopus_df
        showNotification("Apenas dados Scopus importados e processados com sucesso!", type = "warning")
      } else if (!is.null(wos_df)) {
        rv$M <- wos_df
        showNotification("Apenas dados Web of Science importados e processados com sucesso!", type = "warning")
      }
    })
  })

  output$imported_data_summary <- renderTable({
    req(rv$M)
    data.frame(
      Métrica = c("Número de Documentos", "Número de Fontes", "Número de Autores"),
      Valor = c(nrow(rv$M), length(unique(rv$M$SO)), length(unique(unlist(strsplit(rv$M$AU, ";")))))
    )
  })

  # --- Módulo de Análise Bibliométrica e Cienciométrica ---
  results_biblio <- reactive({
    req(rv$M)
    biblioAnalysis(rv$M, sep = ";")
  })

  output$bibliometric_plot <- renderPlot({
    req(results_biblio(), input$bib_analysis_type)
    S <- summary(results_biblio(), k = 10, pause = FALSE)

    if (input$bib_analysis_type == "Produtividade Anual") {
      annual_prod <- S$AnnualProduction
      ggplot(annual_prod, aes(x = Year, y = Articles)) +
        geom_line(color = "steelblue") + geom_point() +
        labs(title = "Produção Anual de Artigos", x = "Ano", y = "Número de Publicações") +
        theme_minimal()
    } else if (input$bib_analysis_type == "Autores Mais Produtivos") {
      top_authors <- results_biblio()$MostProdAuthors
      ggplot(top_authors, aes(x = reorder(Author, Articles), y = Articles)) +
        geom_bar(stat = "identity", fill = "steelblue") +
        labs(title = "Autores Mais Produtivos", x = "Autor", y = "Número de Artigos") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Fontes Mais Relevantes") {
      top_sources <- results_biblio()$MostRelSources
      ggplot(top_sources, aes(x = reorder(Source, Articles), y = Articles)) +
        geom_bar(stat = "identity", fill = "darkgreen") +
        labs(title = "Fontes Mais Relevantes", x = "Fonte", y = "Número de Artigos") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Palavras-chave Mais Frequentes") {
      keywords_freq <- results_biblio()$MostRelKeywords
      ggplot(keywords_freq, aes(x = reorder(Keyword, Freq), y = Freq)) +
        geom_bar(stat = "identity", fill = "purple") +
        labs(title = "Palavras-chave Mais Frequentes", x = "Palavra-chave", y = "Frequência") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Índice H") {
      h_authors <- Hindex(rv$M, field = "author", sep = ";")
      h_sources <- Hindex(rv$M, field = "source", sep = ";")
      
      # Combine top authors and sources by H-index for display
      top_h_authors <- h_authors$H %>% arrange(desc(h_index)) %>% head(10)
      top_h_sources <- h_sources$H %>% arrange(desc(h_index)) %>% head(10)
      
      # Simple plot for top H-index authors
      ggplot(top_h_authors, aes(x = reorder(Author, h_index), y = h_index)) +
        geom_bar(stat = "identity", fill = "orange") +
        labs(title = "Top 10 Autores por H-index", x = "Autor", y = "H-index") +
        coord_flip() +
        theme_minimal()
    }
  })

  output$bibliometric_table <- renderTable({
    req(results_biblio(), input$bib_analysis_type)
    S <- summary(results_biblio(), k = 10, pause = FALSE)

    if (input$bib_analysis_type == "Produtividade Anual") {
      S$AnnualProduction
    } else if (input$bib_analysis_type == "Autores Mais Produtivos") {
      results_biblio()$MostProdAuthors
    } else if (input$bib_analysis_type == "Fontes Mais Relevantes") {
      results_biblio()$MostRelSources
    } else if (input$bib_analysis_type == "Palavras-chave Mais Frequentes") {
      results_biblio()$MostRelKeywords
    } else if (input$bib_analysis_type == "Índice H") {
      h_authors <- Hindex(rv$M, field = "author", sep = ";")
      h_sources <- Hindex(rv$M, field = "source", sep = ";")
      
      list("Autores com Maior H-index" = h_authors$H %>% arrange(desc(h_index)) %>% head(10),
           "Fontes com Maior H-index" = h_sources$H %>% arrange(desc(h_index)) %>% head(10))
    }
  })

  # --- Módulo de Análise de Redes ---
  network_data <- reactive({
    req(rv$M, input$network_type)
    M_temp <- rv$M
    
    if (input$network_type == "Colaboração (Países)") {
      M_temp <- metaTagExtraction(M_temp, Field = "AU_CO", sep = ";")
      biblioNetwork(M_temp, analysis = "collaboration", network = "countries", sep = ";")
    } else if (input$network_type == "Colaboração (Autores)") {
      biblioNetwork(M_temp, analysis = "collaboration", network = "authors", sep = ";")
    } else if (input$network_type == "Colaboração (Instituições)") {
      M_temp <- metaTagExtraction(M_temp, Field = "AU_UN", sep = ";")
      biblioNetwork(M_temp, analysis = "collaboration", network = "universities", sep = ";")
    } else if (input$network_type == "Co-citação (Autores)") {
      biblioNetwork(M_temp, analysis = "co-citation", network = "authors", sep = ";")
    } else if (input$network_type == "Co-citação (Fontes)") {
      biblioNetwork(M_temp, analysis = "co-citation", network = "sources", sep = ";")
    } else if (input$network_type == "Acoplamento (Autores)") {
      biblioNetwork(M_temp, analysis = "coupling", network = "authors", sep = ";")
    } else if (input$network_type == "Acoplamento (Fontes)") {
      biblioNetwork(M_temp, analysis = "coupling", network = "sources", sep = ";")
    }
  })

  output$network_plot <- renderPlot({
    req(network_data(), input$network_nodes)
    Net <- network_data()
    networkPlot(Net, n = input$network_nodes, Title = input$network_type, type = "fruchterman", labelsize = 0.7)
  })

  # --- Módulo de Análise Qualitativa (Bardin) ---
  observeEvent(input$prepare_corpus, {
    req(rv$M)
    withProgress(message = 'Preparando corpus...', value = 0, {
      incProgress(0.5, detail = "Extraindo resumos...")
      rv$corpus <- corpus(rv$M$AB)
      incProgress(0.8, detail = "Criando DFM...")
      rv$dfm <- dfm(rv$corpus, remove = stopwords(input$stopwords_lang), remove_punct = TRUE)
      showNotification("Corpus preparado com sucesso!", type = "success")
    })
  })

  output$wordcloud_plot <- renderPlot({
    req(rv$dfm)
    # Placeholder for wordcloud plot, requires 'wordcloud' package
    # For simplicity, just showing a bar plot of top features for now
    top_features <- textstat_frequency(rv$dfm) %>% 
      arrange(desc(frequency)) %>% 
      head(50)
    
    ggplot(top_features, aes(x = reorder(feature, frequency), y = frequency)) +
      geom_bar(stat = "identity", fill = "darkblue") +
      labs(title = "Top 50 Palavras Mais Frequentes", x = "Palavra", y = "Frequência") +
      coord_flip() +
      theme_minimal()
  })

  # --- Módulo de Modelagem de Tópicos ---
  lda_model_reactive <- eventReactive(input$run_lda, {
    req(rv$dfm, input$num_topics)
    withProgress(message = 'Executando Modelagem de Tópicos (LDA)...', value = 0, {
      incProgress(0.5, detail = "Calculando LDA...")
      LDA(rv$dfm, k = input$num_topics)
    })
  })

  output$lda_terms_table <- renderTable({
    req(lda_model_reactive())
    terms(lda_model_reactive(), 10) # Show top 10 terms per topic
  })

  # --- Módulo de Visualização e Exportação ---
  output$download_report <- downloadHandler(
    filename = function() {
      "FAET_Relatorio_Analise.pdf"
    },
    content = function(file) {
      # Placeholder for report generation logic
      # This would typically involve RMarkdown or a custom PDF generation
      # For now, create a dummy PDF
      pdf(file)
      plot(1,1, main = "Relatório de Análise FAET")
      text(1, 1.2, "Este é um relatório de exemplo gerado pelo FAET.")
      dev.off()
    }
  )

  output$download_plot <- downloadHandler(
    filename = function() {
      paste0("FAET_Grafico_", Sys.Date(), ".png")
    },
    content = function(file) {
      # This will download the last plot rendered. 
      # In a real app, you'd want to capture the specific plot.
      ggsave(file, plot = last_plot(), device = "png", width = 10, height = 7)
    }
  )

}

# Run the application
# shinyApp(ui = ui, server = server)

