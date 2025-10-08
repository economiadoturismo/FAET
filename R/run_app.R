#' Lança o aplicativo Shiny do FAET
#'
#' Esta função inicia a interface gráfica do usuário do pacote FAET.
#'
#' @export
#' @examples
#' if (interactive()) {
#'   FAET::run_app()
#' }
run_app <- function() {
  app_dir <- system.file("app", package = "FAET")
  if (app_dir == "") {
    stop("Não foi possível encontrar o diretório do aplicativo Shiny. O pacote FAET está instalado corretamente?")
  }
  shiny::runApp(app_dir)
}

