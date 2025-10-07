# Funções auxiliares para geração de gráficos

# Exemplo de função para plotar mapa de produtividade
# plot_country_productivity <- function(results_biblio) {
#   prod_countries <- results_biblio$MostProdCountries
#   prod_countries$region <- tolower(prod_countries$Country)
#   world_map <- maps::map_data("world")
#   map_prod <- dplyr::left_join(world_map, prod_countries, by = "region")
#   
#   ggplot2::ggplot(map_prod, ggplot2::aes(x = long, y = lat, group = group, fill = Articles)) +
#     ggplot2::geom_polygon(color = "gray", size = 0.1) +
#     ggplot2::coord_fixed(1.3) +
#     viridis::scale_fill_viridis(name = "Artigos", na.value = "lightgray") +
#     ggplot2::labs(title = "Mapa de Produtividade Científica por País") +
#     ggplot2::theme_void()
# }

