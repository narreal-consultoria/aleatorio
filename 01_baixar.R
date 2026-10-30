rm(list = ls())
library(dplyr,warn.conflicts = F)
aa = load("links_ibge_cnefe.RData")
arq.cnefe.br %>% 
  filter(grepl("DF",url)) -> cnefe.df
arq.SC.br %>% 
  filter(grepl("BR",url)) %>% head
arq.SC.br %>% 
  filter(grepl("Agregados_por_setores",url)) -> agg.SC.ibge
ee = 2
lst.baixa = lappy(1:nrow(agg.SC.ibge),function(ee){
  print(ee)
  agg.SC.ibge %>% 
    filter(row_number() == ee) -> x.ee
  l.ee = unlist(strsplit(x.ee$url,split = "/"))
  nome.ee = l.ee[length(l.ee)]
  download.file(url = x.ee$url,destfile = paste0("Dados/",nome.ee))
})