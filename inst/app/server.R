library(shiny)
library(shinydashboard)
library(shinyWidgets) # Para switchInput
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
library(metagear) # Para triagem de estudos
library(meta)     # Para meta-análise
library(wordcloud) # Para nuvem de palavras
library(RColorBrewer) # Para cores da nuvem de palavras
library(quanteda.textstats) # Para textstat_frequency

# Source R functions (these files will be created in FAET/R/)
# source("../../R/data_import.R")
# source("../../R/bibliometrics.R")
# source("../../R/network_analysis.R")
# source("../../R/qualitative_analysis.R")
# source("../../R/topic_modeling.R")
# source("../../R/meta_analysis.R") # Novo arquivo para meta-análise
# source("../../R/visualization.R")

server <- function(input, output, session) {

  # Reactive value to store the merged dataframe M
  rv <- reactiveValues(M = NULL, corpus = NULL, dfm = NULL, lda_model = NULL, 
                       meta_data = NULL, meta_results = NULL, current_plot = NULL)

  # --- Lógica para o Modo Didático ---
  didactic_text <- reactive({
    if (isTRUE(input$didactic_mode)) {
      list(
        home = p("Bem-vindo ao FAET! Este é o ponto de partida para suas análises. Use o menu lateral para navegar pelas etapas. O \'Modo Didático\' fornece explicações detalhadas em cada seção."),
        import = p("Nesta etapa, você carregará seus dados bibliográficos. O FAET suporta arquivos exportados do Scopus (.bib) e Web of Science (.txt ou .bib). Após o upload, o sistema mesclará e removerá duplicatas automaticamente."),
        bibliometrics = p("As análises bibliométricas e cienciométricas fornecem uma visão quantitativa da sua literatura. Explore a produtividade de autores, periódicos, países e o impacto das publicações através de métricas como o Índice H."),
        networks = p("As redes científicas revelam padrões de colaboração e influência. Visualize coautorias entre autores, instituições e países, além de redes de co-citação e acoplamento bibliográfico para entender a estrutura intelectual da área."),
        qualitative = p("A Análise Qualitativa Investigativa, inspirada em Bardin, permite aprofundar no conteúdo textual dos resumos. Prepare o corpus, remova stopwords e visualize as palavras mais frequentes em nuvens de palavras. Explore também a frequência e co-ocorrência de termos."),
        topic_modeling = p("A Modelagem de Tópicos (LDA) identifica temas latentes em seu corpus textual. Escolha o número de tópicos e descubra os termos mais representativos de cada um, complementando sua análise qualitativa. É possível mapear os tópicos para suas categorias de Bardin."),
        meta_analysis = p("A Meta-análise permite sintetizar resultados de múltiplos estudos. Este módulo guiará você desde a triagem de estudos até a extração de dados e a geração de gráficos de floresta e funil para avaliar o efeito combinado e o viés de publicação."),
        export = p("Nesta etapa final, você pode visualizar e exportar todos os seus resultados. Gere relatórios completos em PDF ou Markdown e salve seus gráficos em alta qualidade para suas publicações.")
      )
    } else {
      list(
        home = NULL, import = NULL, bibliometrics = NULL, networks = NULL,
        qualitative = NULL, topic_modeling = NULL, meta_analysis = NULL, export = NULL
      )
    }
  })

  output$didactic_text_import <- renderUI({ didactic_text()$import })
  output$didactic_text_bibliometrics <- renderUI({ didactic_text()$bibliometrics })
  output$didactic_text_networks <- renderUI({ didactic_text()$networks })
  output$didactic_text_qualitative <- renderUI({ didactic_text()$qualitative })
  output$didactic_text_topic_modeling <- renderUI({ didactic_text()$topic_modeling })
  output$didactic_text_meta_analysis <- renderUI({ didactic_text()$meta_analysis })
  output$didactic_text_export <- renderUI({ didactic_text()$export })

  # --- Lógica para o Cronograma Visual de Etapas ---
  output$progress_timeline <- renderUI({
    current_tab <- input$tabs
    steps <- c("home", "import_preprocess", "bibliometrics", "networks", "qualitative", "topic_modeling", "meta_analysis", "export")
    step_names <- c("Início", "Importação", "Bibliometria", "Redes", "Qualitativa", "Tópicos", "Meta-análise", "Exportação")

    # Determinar o status de cada etapa
    status <- sapply(steps, function(s) {
      if (s == current_tab) {
        return("active")
      } else if (match(s, steps) < match(current_tab, steps)) {
        return("completed")
      } else {
        return("pending")
      }
    })

    # Renderizar a timeline
    div(class = "timeline",
        lapply(seq_along(steps), function(i) {
          div(class = paste0("timeline-item ", status[i]),
              icon(switch(status[i],
                          "completed" = "check-circle",
                          "active" = "arrow-alt-circle-right",
                          "pending" = "circle"
              )),
              span(step_names[i])
          )
        })
    )
  })

  # --- Módulo de Importação e Pré-processamento ---
  observeEvent(input$process_data, {
    req(input$file_scopus, input$file_wos)

    withProgress(message = 'Processando dados...', value = 0, {
      incProgress(0.2, detail = "Importando Scopus...")
      scopus_df <- tryCatch({
        bibliometrix::convert2df(file = input$file_scopus$datapath, dbsource = "scopus", format = "bibtex")
      }, error = function(e) {
        showNotification(paste("Erro ao importar Scopus:", e$message), type = "error")
        return(NULL)
      })

      incProgress(0.4, detail = "Importando Web of Science...")
      wos_df <- tryCatch({
        # Handle multiple WoS files if necessary, for simplicity, taking the first one
        bibliometrix::convert2df(file = input$file_wos$datapath[1], dbsource = "wos", format = "plaintext")
      }, error = function(e) {
        showNotification(paste("Erro ao importar WoS:", e$message), type = "error")
        return(NULL)
      })

      if (!is.null(scopus_df) && !is.null(wos_df)) {
        incProgress(0.6, detail = "Mesclando e deduplicando...")
        rv$M <- tryCatch({
          bibliometrix::mergeDbSources(scopus_df, wos_df, remove.duplicated = TRUE, verbose = FALSE)
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
    bibliometrix::biblioAnalysis(rv$M, sep = ";")
  })

  output$bibliometric_plot <- renderPlot({
    req(results_biblio(), input$bib_analysis_type)
    S <- summary(results_biblio(), k = 10, pause = FALSE)

    plot_obj <- NULL
    if (input$bib_analysis_type == "Produtividade Anual") {
      annual_prod <- S$AnnualProduction
      plot_obj <- ggplot(annual_prod, aes(x = Year, y = Articles)) +
        geom_line(color = "steelblue") + geom_point() +
        labs(title = "Produção Anual de Artigos", x = "Ano", y = "Número de Publicações") +
        theme_minimal()
    } else if (input$bib_analysis_type == "Autores Mais Produtivos") {
      top_authors <- results_biblio()$MostProdAuthors
      plot_obj <- ggplot(top_authors, aes(x = reorder(Author, Articles), y = Articles)) +
        geom_bar(stat = "identity", fill = "steelblue") +
        labs(title = "Autores Mais Produtivos", x = "Autor", y = "Número de Artigos") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Fontes Mais Relevantes") {
      top_sources <- results_biblio()$MostRelSources
      plot_obj <- ggplot(top_sources, aes(x = reorder(Source, Articles), y = Articles)) +
        geom_bar(stat = "identity", fill = "darkgreen") +
        labs(title = "Fontes Mais Relevantes", x = "Fonte", y = "Número de Artigos") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Palavras-chave Mais Frequentes") {
      keywords_freq <- results_biblio()$MostRelKeywords
      plot_obj <- ggplot(keywords_freq, aes(x = reorder(Keyword, Freq), y = Freq)) +
        geom_bar(stat = "identity", fill = "purple") +
        labs(title = "Palavras-chave Mais Frequentes", x = "Palavra-chave", y = "Frequência") +
        coord_flip() +
        theme_minimal()
    } else if (input$bib_analysis_type == "Índice H") {
      h_authors <- bibliometrix::Hindex(rv$M, field = "author", sep = ";")
      top_h_authors <- h_authors$H %>% arrange(desc(h_index)) %>% head(10)
      plot_obj <- ggplot(top_h_authors, aes(x = reorder(Author, h_index), y = h_index)) +
        geom_bar(stat = "identity", fill = "orange") +
        labs(title = "Top 10 Autores por H-index", x = "Autor", y = "H-index") +
        coord_flip() +
        theme_minimal()
    }
    rv$current_plot <- plot_obj # Armazena o plot atual para download
    plot_obj
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
      h_authors <- bibliometrix::Hindex(rv$M, field = "author", sep = ";")
      h_sources <- bibliometrix::Hindex(rv$M, field = "source", sep = ";")
      
      list("Autores com Maior H-index" = h_authors$H %>% arrange(desc(h_index)) %>% head(10),
           "Fontes com Maior H-index" = h_sources$H %>% arrange(desc(h_index)) %>% head(10))
    }
  })

  # --- Módulo de Análise de Redes ---
  network_data <- reactive({
    req(rv$M, input$network_type)
    M_temp <- rv$M
    
    if (input$network_type == "Colaboração (Países)") {
      M_temp <- bibliometrix::metaTagExtraction(M_temp, Field = "AU_CO", sep = ";")
      bibliometrix::biblioNetwork(M_temp, analysis = "collaboration", network = "countries", sep = ";")
    } else if (input$network_type == "Colaboração (Autores)") {
      bibliometrix::biblioNetwork(M_temp, analysis = "collaboration", network = "authors", sep = ";")
    } else if (input$network_type == "Colaboração (Instituições)") {
      M_temp <- bibliometrix::metaTagExtraction(M_temp, Field = "AU_UN", sep = ";")
      bibliometrix::biblioNetwork(M_temp, analysis = "collaboration", network = "universities", sep = ";")
    } else if (input$network_type == "Co-citação (Autores)") {
      bibliometrix::biblioNetwork(M_temp, analysis = "co-citation", network = "authors", sep = ";")
    } else if (input$network_type == "Co-citação (Fontes)") {
      bibliometrix::biblioNetwork(M_temp, analysis = "co-citation", network = "sources", sep = ";")
    } else if (input$network_type == "Acoplamento (Autores)") {
      bibliometrix::biblioNetwork(M_temp, analysis = "coupling", network = "authors", sep = ";")
    } else if (input$network_type == "Acoplamento (Fontes)") {
      bibliometrix::biblioNetwork(M_temp, analysis = "coupling", network = "sources", sep = ";")
    }
  })

  output$network_plot <- renderPlot({
    req(network_data(), input$network_nodes)
    Net <- network_data()
    plot_obj <- bibliometrix::networkPlot(Net, n = input$network_nodes, Title = input$network_type, type = "fruchterman", labelsize = 0.7)
    rv$current_plot <- plot_obj # Armazena o plot atual para download
    plot_obj
  })

  # --- Módulo de Análise Qualitativa (Bardin) ---
  observeEvent(input$prepare_corpus, {
    req(rv$M)
    withProgress(message = 'Preparando corpus...', value = 0, {
      incProgress(0.5, detail = "Extraindo resumos...")
      # Garantir que AB não seja NULL e seja um vetor de caracteres
      abstracts <- rv$M$AB[!is.na(rv$M$AB) & rv$M$AB != ""]
      if (length(abstracts) == 0) {
        showNotification("Nenhum resumo disponível para análise.", type = "warning")
        return(NULL)
      }
      rv$corpus <- quanteda::corpus(abstracts)
      incProgress(0.8, detail = "Criando DFM...")
      rv$dfm <- quanteda::dfm(rv$corpus, remove = quanteda::stopwords(input$stopwords_lang), remove_punct = TRUE, remove_numbers = TRUE, remove_symbols = TRUE)
      showNotification("Corpus preparado com sucesso!", type = "success")
    })
  })

  output$wordcloud_plot <- renderPlot({
    req(rv$dfm)
    withProgress(message = 'Gerando nuvem de palavras...', value = 0, {
      incProgress(0.5, detail = "Calculando frequências...")
      freq_words <- quanteda.textstats::textstat_frequency(rv$dfm, n = 100)
      
      # Gerar nuvem de palavras
      set.seed(123) # para reprodutibilidade
      plot_obj <- wordcloud::wordcloud(words = freq_words$feature, freq = freq_words$frequency, 
                                       min.freq = 1, max.words = 100, random.order = FALSE, 
                                       colors = RColorBrewer::brewer.pal(8, "Dark2"))
      rv$current_plot <- plot_obj # Armazena o plot atual para download
      plot_obj
    })
  })

  observeEvent(input$run_freq_analysis, {
    req(rv$dfm)
    output$qualitative_results_table <- renderTable({
      quanteda.textstats::textstat_frequency(rv$dfm, n = 50) %>% 
        dplyr::select(feature, frequency, rank)
    })
    showNotification("Análise de frequência concluída!", type = "info")
  })

  observeEvent(input$run_cooc_analysis, {
    req(rv$dfm)
    output$qualitative_results_table <- renderTable({
      # Exemplo simples de co-ocorrência, pode ser aprimorado com network plots
      fcm_obj <- quanteda::fcm(rv$dfm, context = "window", window = 5)
      top_features <- names(topfeatures(fcm_obj, 20))
      as.data.frame(quanteda::fcm_select(fcm_obj, pattern = top_features))
    })
    showNotification("Análise de co-ocorrência concluída!", type = "info")
  })

  # --- Módulo de Modelagem de Tópicos ---
  lda_model_reactive <- eventReactive(input$run_lda, {
    req(rv$dfm, input$num_topics)
    withProgress(message = 'Executando Modelagem de Tópicos (LDA)...', value = 0, {
      incProgress(0.5, detail = "Convertendo DFM para formato Topicmodels...")
      # Certificar-se de que o DFM não está vazio e não tem documentos com 0 palavras
      dfm_filtered <- quanteda::dfm_trim(rv$dfm, min_termfreq = 1, min_docfreq = 1)
      if (ndoc(dfm_filtered) == 0 || nfeat(dfm_filtered) == 0) {
        showNotification("DFM vazio ou sem termos após filtragem. Ajuste o pré-processamento.", type = "error")
        return(NULL)
      }
      dtm <- quanteda::convert(dfm_filtered, to = "topicmodels")
      
      incProgress(0.8, detail = "Calculando LDA...")
      rv$lda_model <- topicmodels::LDA(dtm, k = input$num_topics, control = list(seed = 123))
      showNotification("Modelagem de Tópicos concluída!", type = "success")
      rv$lda_model # Retorna o modelo LDA para ser usado por outros reativos
    })
  })

  output$lda_terms_table <- renderTable({
    req(rv$lda_model)
    as.data.frame(topicmodels::terms(rv$lda_model, 10)) # Show top 10 terms per topic
  })

  output$lda_vis_plot <- renderPlot({
    req(rv$lda_model)
    # Placeholder para visualização de tópicos. LDAvis seria ideal, mas requer mais integração.
    # Por enquanto, um gráfico de barras simples da distribuição de tópicos por documento.
    topics_per_doc <- as.data.frame(topicmodels::posterior(rv$lda_model)$topics)
    topic_counts <- colSums(topics_per_doc > 0.1) # Contar documentos onde o tópico é proeminente
    topic_df <- data.frame(Topic = factor(paste("Tópico", 1:length(topic_counts))), Count = topic_counts)
    
    plot_obj <- ggplot(topic_df, aes(x = Topic, y = Count, fill = Topic)) +
      geom_bar(stat = "identity") +
      labs(title = "Distribuição de Tópicos nos Documentos", y = "Número de Documentos Proeminentes") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    rv$current_plot <- plot_obj # Armazena o plot atual para download
    plot_obj
  })

  observeEvent(input$map_topics_bardin, {
    req(rv$lda_model)
    showNotification("Funcionalidade de mapeamento de tópicos para Bardin em desenvolvimento. Requer input manual de categorias.", type = "warning")
    # Lógica para mapear tópicos para categorias de Bardin. 
    # Isso provavelmente envolveria uma interface para o usuário associar manualmente os tópicos.
  })

  # --- Módulo de Meta-análise ---
  observeEvent(input$file_screening, {
    req(input$file_screening)
    rv$meta_data <- read.csv(input$file_screening$datapath, stringsAsFactors = FALSE)
    showNotification("Estudos para triagem carregados com sucesso!", type = "success")
  })

  observeEvent(input$start_screening, {
    req(rv$meta_data)
    showNotification("Iniciando triagem. Esta etapa geralmente envolve revisão manual ou semi-automática. Por favor, revise os dados carregados.", type = "info")
    # Em uma implementação completa, aqui haveria uma UI para triagem interativa (e.g., metagear::screen_abstracts)
    # Por enquanto, apenas um placeholder.
    output$meta_analysis_summary_table <- renderTable({
      head(rv$meta_data)
    })
  })

  observeEvent(input$start_data_extraction, {
    req(rv$meta_data)
    showNotification("Iniciando extração de dados. Esta etapa requer input manual dos tamanhos de efeito. Por favor, insira os dados na tabela abaixo.", type = "info")
    # Placeholder para uma tabela editável para extração de dados
    # Para demonstração, vamos criar dados dummy para meta-análise
    rv$meta_data_extracted <- data.frame(
      study = paste("Estudo", 1:5),
      event.e = c(10, 15, 8, 12, 20),
      n.e = c(100, 120, 90, 110, 150),
      event.c = c(5, 8, 4, 6, 10),
      n.c = c(100, 120, 90, 110, 150)
    )
    output$meta_analysis_summary_table <- renderTable({
      rv$meta_data_extracted
    })
  })

  observeEvent(input$run_meta_analysis, {
    req(rv$meta_data_extracted, input$meta_analysis_model)
    withProgress(message = 'Executando Meta-análise...', value = 0, {
      incProgress(0.5, detail = "Calculando efeitos...")
      
      # Exemplo de meta-análise para dados dicotômicos (Odds Ratio)
      # Adapte conforme o tipo de dados que o usuário irá extrair
      rv$meta_results <- meta::metabin(
        event.e = rv$meta_data_extracted$event.e,
        n.e = rv$meta_data_extracted$n.e,
        event.c = rv$meta_data_extracted$event.c,
        n.c = rv$meta_data_extracted$n.c,
        studlab = rv$meta_data_extracted$study,
        data = rv$meta_data_extracted,
        sm = "OR", # Odds Ratio
        method = "MH", # Mantel-Haenszel
        fixed = (input$meta_analysis_model == "Efeitos Fixos"),
        random = (input$meta_analysis_model == "Efeitos Aleatórios")
      )
      showNotification("Meta-análise concluída!", type = "success")
    })
  })

  output$forest_plot <- renderPlot({
    req(rv$meta_results)
    plot_obj <- meta::forest(rv$meta_results, layout = "RevMan5")
    rv$current_plot <- plot_obj # Armazena o plot atual para download
    plot_obj
  })

  output$funnel_plot <- renderPlot({
    req(rv$meta_results)
    plot_obj <- meta::funnel(rv$meta_results)
    rv$current_plot <- plot_obj # Armazena o plot atual para download
    plot_obj
  })

  output$meta_analysis_summary_table <- renderTable({
    req(rv$meta_results)
    summary(rv$meta_results)$common.effect # Exemplo, pode ser mais detalhado
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
      req(rv$current_plot)
      # ggsave works for ggplot objects, for base R plots, need to use png()
      if ("ggplot" %in% class(rv$current_plot)) {
        ggplot2::ggsave(file, plot = rv$current_plot, device = "png", width = 10, height = 7)
      } else {
        # For base R plots (like from bibliometrix::networkPlot, meta::forest, meta::funnel)
        # Need to re-render the plot to save it correctly
        png(file, width = 1000, height = 700, res = 100)
        if (input$tabs == "bibliometrics") {
          # Re-render bibliometric plot
          S <- summary(results_biblio(), k = 10, pause = FALSE)
          if (input$bib_analysis_type == "Produtividade Anual") {
            annual_prod <- S$AnnualProduction
            print(ggplot(annual_prod, aes(x = Year, y = Articles)) +
              geom_line(color = "steelblue") + geom_point() +
              labs(title = "Produção Anual de Artigos", x = "Ano", y = "Número de Publicações") +
              theme_minimal())
          } # ... (other bibliometric plots)
        } else if (input$tabs == "networks") {
          Net <- network_data()
          bibliometrix::networkPlot(Net, n = input$network_nodes, Title = input$network_type, type = "fruchterman", labelsize = 0.7)
        } else if (input$tabs == "qualitative") {
          # Re-render wordcloud
          freq_words <- quanteda.textstats::textstat_frequency(rv$dfm, n = 100)
          wordcloud::wordcloud(words = freq_words$feature, freq = freq_words$frequency, 
                               min.freq = 1, max.words = 100, random.order = FALSE, 
                               colors = RColorBrewer::brewer.pal(8, "Dark2"))
        } else if (input$tabs == "topic_modeling") {
          # Re-render LDA plot
          topics_per_doc <- as.data.frame(topicmodels::posterior(rv$lda_model)$topics)
          topic_counts <- colSums(topics_per_doc > 0.1) 
          topic_df <- data.frame(Topic = factor(paste("Tópico", 1:length(topic_counts))), Count = topic_counts)
          print(ggplot(topic_df, aes(x = Topic, y = Count, fill = Topic)) +
            geom_bar(stat = "identity") +
            labs(title = "Distribuição de Tópicos nos Documentos", y = "Número de Documentos Proeminentes") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1)))
        } else if (input$tabs == "meta_analysis") {
          if (!is.null(rv$meta_results)) {
            if (input$meta_analysis_model == "Efeitos Fixos" || input$meta_analysis_model == "Efeitos Aleatórios") {
              meta::forest(rv$meta_results, layout = "RevMan5")
            } else {
              meta::funnel(rv$meta_results)
            }
          }
        }
        dev.off()
      }
    }
  )

  output$download_all_plots <- downloadHandler(
    filename = function() {
      paste0("FAET_Todos_Graficos_", Sys.Date(), ".zip")
    },
    content = function(file) {
      # Placeholder for zipping all generated plots
      # This would require saving all plots to temporary files and then zipping them
      # For now, create a dummy zip
      zip(zipfile = file, files = c())
      showNotification("Funcionalidade de download de todos os gráficos em desenvolvimento.", type = "warning")
    }
  )

}

