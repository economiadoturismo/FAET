# Funções para Importação e Pré-processamento de Dados

# Exemplo de função para importar e mesclar dados
# Esta função seria chamada pelo server.R do Shiny
# import_and_merge_data <- function(scopus_path, wos_path) {
#   scopus_df <- bibliometrix::convert2df(file = scopus_path, dbsource = "scopus", format = "bibtex")
#   wos_df <- bibliometrix::convert2df(file = wos_path, dbsource = "wos", format = "plaintext")
#   M <- bibliometrix::mergeDbSources(scopus_df, wos_df, remove.duplicated = TRUE, verbose = FALSE)
#   return(M)
# }

