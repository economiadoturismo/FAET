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
library(metagear)
library(meta)

# Carregar todas as funções do pacote FAET (quando o pacote estiver instalado)
# Por enquanto, as funções estão embutidas no server.R para o protótipo

# Definir opções globais, se necessário
options(shiny.maxRequestSize = 30*1024^2) # Aumenta o limite de upload para 30MB

