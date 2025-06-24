# Carregar bibliotecas necessárias
library(rvest)
library(httr)
library(dplyr)
library(stringr)
library(readr)

# Função para extrair informações de uma página FTP
extrair_conteudo_ftp <- function(url) {
  tryCatch({
    cat("  → Acessando:", url, "\n")
    
    # Fazer requisição HTTP com timeout maior
    response <- GET(url, timeout(60))
    
    # Verificar se a requisição foi bem-sucedida
    if (status_code(response) != 200) {
      cat("    ❌ Erro HTTP:", status_code(response), "\n")
      return(data.frame())
    }
    
    # Parsear o HTML
    page <- read_html(response)
    
    # Método 1: Tentar extrair de <pre> (formato típico de FTP)
    pre_content <- page %>% html_nodes("pre") %>% html_text()
    
    if (length(pre_content) > 0 && nchar(pre_content[1]) > 100) {
      return(processar_pre_ftp(pre_content[1], url))
    }
    
    # Método 2: Extrair links diretamente
    links <- page %>% html_nodes("a") %>% html_attr("href")
    texts <- page %>% html_nodes("a") %>% html_text()
    
    if (length(links) > 0) {
      # Filtrar links válidos
      valid_indices <- !is.na(links) & 
        !links %in% c("../", "./", "/") & 
        !str_detect(links, "^http") &
        !str_detect(links, "^mailto") &
        !str_detect(links, "\\?")
      
      links <- links[valid_indices]
      texts <- texts[valid_indices]
      
      if (length(links) > 0) {
        df <- data.frame(
          nome = texts,
          tipo = ifelse(str_detect(links, "/$"), "diretorio", "arquivo"),
          data_modificacao = NA,
          tamanho = NA,
          url_completa = paste0(url, links),
          stringsAsFactors = FALSE
        )
        
        cat("    ✅ Encontrados", nrow(df), "itens\n")
        return(df)
      }
    }
    
    cat("    ⚠️ Nenhum conteúdo encontrado\n")
    return(data.frame())
    
  }, error = function(e) {
    cat("    ❌ Erro:", e$message, "\n")
    return(data.frame())
  })
}

# Função para processar conteúdo de <pre> do FTP
processar_pre_ftp <- function(pre_text, base_url) {
  lines <- strsplit(pre_text, "\n")[[1]]
  lines <- lines[!str_detect(lines, "^\\s*$|Parent Directory|Index of|Busque no|Portal IBGE|Downloads")]
  lines <- lines[str_detect(lines, "\\S")]  # Linhas não vazias
  
  dados <- data.frame()
  
  for (line in lines) {
    # Tentar diferentes padrões de parsing
    if (str_detect(line, "\\d{4}-\\d{2}-\\d{2}")) {
      # Formato: Nome Data Tamanho Descrição
      parts <- str_split(str_trim(line), "\\s+")[[1]]
      
      if (length(parts) >= 3) {
        nome <- parts[1]
        data_mod <- paste(parts[2], ifelse(length(parts) >= 3, parts[3], ""))
        tamanho <- ifelse(length(parts) >= 4 && parts[4] != "-", parts[4], NA)
        
        # Detectar se é diretório
        tipo <- ifelse(str_detect(nome, "/$") || str_detect(line, "<DIR>"), "diretorio", "arquivo")
        
        dados <- rbind(dados, data.frame(
          nome = nome,
          tipo = tipo,
          data_modificacao = str_trim(data_mod),
          tamanho = tamanho,
          url_completa = paste0(base_url, nome),
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  if (nrow(dados) > 0) {
    cat("    ✅ Processadas", nrow(dados), "linhas do FTP\n")
  }
  
  return(dados)
}

# Função recursiva ILIMITADA para mapear toda a árvore
mapear_arvore_ftp_completa <- function(url_base, visitados = character(), profundidade_atual = 0) {
  
  # Evitar loops infinitos
  if (url_base %in% visitados) {
    cat("🔄 URL já visitada, pulando:", url_base, "\n")
    return(data.frame())
  }
  
  # Adicionar à lista de visitados
  visitados <- c(visitados, url_base)
  
  # Log de progresso
  indent <- paste(rep("  ", profundidade_atual), collapse = "")
  cat(indent, "📁 Nível", profundidade_atual, ":", url_base, "\n")
  
  # Extrair conteúdo da URL atual
  conteudo <- extrair_conteudo_ftp(url_base)
  
  if (nrow(conteudo) == 0) {
    cat(indent, "  ⚠️ Nenhum conteúdo encontrado\n")
    return(data.frame())
  }
  
  # Adicionar metadados
  conteudo$profundidade <- profundidade_atual
  conteudo$caminho_pai <- url_base
  conteudo$timestamp_coleta <- Sys.time()
  
  # Contador de progresso
  total_itens <- nrow(conteudo)
  cat(indent, "  📊 Total de itens:", total_itens, "\n")
  
  # Identificar diretórios para recursão
  subdiretorios <- conteudo[conteudo$tipo == "diretorio", ]
  
  resultado_completo <- conteudo
  
  # Processar TODOS os subdiretórios recursivamente
  if (nrow(subdiretorios) > 0) {
    cat(indent, "  📂 Processando", nrow(subdiretorios), "subdiretórios...\n")
    
    for (i in 1:nrow(subdiretorios)) {
      subdir_nome <- subdiretorios$nome[i]
      subdir_url <- subdiretorios$url_completa[i]
      
      cat(indent, "    [", i, "/", nrow(subdiretorios), "] Processando:", subdir_nome, "\n")
      
      # Pausa para não sobrecarregar o servidor
      Sys.sleep(0.5)
      
      # Recursão com lista de visitados atualizada
      sub_resultado <- mapear_arvore_ftp_completa(
        subdir_url, 
        visitados, 
        profundidade_atual + 1
      )
      
      if (nrow(sub_resultado) > 0) {
        resultado_completo <- rbind(resultado_completo, sub_resultado)
        cat(indent, "    ✅ Adicionados", nrow(sub_resultado), "itens do subdiretório\n")
      }
      
      # Atualizar visitados para próximas iterações
      visitados <- unique(c(visitados, sub_resultado$caminho_pai))
    }
  }
  
  cat(indent, "✅ Concluído nível", profundidade_atual, "- Total coletado:", nrow(resultado_completo), "itens\n")
  return(resultado_completo)
}

# Função principal otimizada
main_completo <- function() {
  # URL base do FTP do IBGE
  url_base <- "https://ftp.ibge.gov.br/"
  
  cat("🚀 Iniciando mapeamento COMPLETO do FTP do IBGE...\n")
  cat("⚠️  ATENÇÃO: Este processo pode levar HORAS dependendo do tamanho do FTP!\n")
  cat("📊 Progresso será mostrado em tempo real...\n\n")
  
  # Registrar tempo de início
  inicio <- Sys.time()
  
  # Mapear TODA a árvore sem limitação de profundidade
  arvore_completa <- mapear_arvore_ftp_completa(url_base)
  
  # Tempo total
  tempo_total <- Sys.time() - inicio
  
  if (nrow(arvore_completa) > 0) {
    cat("\n🎉 MAPEAMENTO CONCLUÍDO!\n")
    cat("⏱️  Tempo total:", round(tempo_total, 2), attr(tempo_total, "units"), "\n")
    cat("📊 Total de itens mapeados:", nrow(arvore_completa), "\n")
    
    # Enriquecer dados
    arvore_completa <- arvore_completa %>%
      mutate(
        # Calcular nível baseado na URL
        nivel = str_count(url_completa, "/") - 3, # Ajustar contagem
        
        # Categorização mais detalhada
        categoria = case_when(
          str_detect(nome, "(?i)censo") ~ "Censos",
          str_detect(nome, "(?i)economia|pib|renda") ~ "Economia",
          str_detect(nome, "(?i)estatistica") ~ "Estatísticas",
          str_detect(nome, "(?i)populacao|demografia") ~ "Demografia",
          str_detect(nome, "(?i)perfil") ~ "Perfis",
          str_detect(nome, "(?i)educacao") ~ "Educação",
          str_detect(nome, "(?i)saude") ~ "Saúde",
          str_detect(nome, "(?i)trabalho|emprego") ~ "Trabalho",
          str_detect(nome, "(?i)industria") ~ "Indústria",
          str_detect(nome, "(?i)agricultura|agro") ~ "Agropecuária",
          TRUE ~ "Outros"
        ),
        
        # Extensão do arquivo
        extensao = ifelse(tipo == "arquivo", 
                          str_extract(nome, "\\.[^.]+$"), 
                          NA),
        
        # Tamanho da URL (indicador de profundidade)
        profundidade_url = nchar(url_completa)
      ) %>%
      arrange(profundidade, caminho_pai, nome)
    
    # Salvar arquivo principal
    nome_arquivo <- paste0("arvore_ftp_ibge_COMPLETA_", 
                           format(Sys.Date(), "%Y%m%d_%H%M"), 
                           ".csv")
    
    # write_csv(arvore_completa, nome_arquivo, locale = locale(encoding = "UTF-8"))
    write.csv2(x = arvore_completa,file = nome_arquivo,fileEncoding = "UTF-8",row.names = F)
    cat("💾 Arquivo principal salvo:", nome_arquivo, "\n")
    
    # Estatísticas detalhadas
    cat("\n📈 ESTATÍSTICAS DETALHADAS:\n")
    
    # Por tipo
    estatisticas_tipo <- arvore_completa %>%
      count(tipo, name = "quantidade") %>%
      mutate(percentual = round(quantidade/sum(quantidade)*100, 1))
    
    cat("\n📁 Por tipo:\n")
    print(estatisticas_tipo)
    
    # Por categoria
    estatisticas_categoria <- arvore_completa %>%
      count(categoria, sort = TRUE) %>%
      mutate(percentual = round(n/sum(n)*100, 1))
    
    cat("\n🏷️  Por categoria:\n")
    print(head(estatisticas_categoria, 10))
    
    # Por profundidade
    estatisticas_profundidade <- arvore_completa %>%
      count(profundidade, name = "quantidade") %>%
      arrange(profundidade)
    
    cat("\n📊 Por nível de profundidade:\n")
    print(estatisticas_profundidade)
    
    # Salvar estatísticas
    write_csv(estatisticas_tipo, paste0("stats_tipo_", nome_arquivo))
    write_csv(estatisticas_categoria, paste0("stats_categoria_", nome_arquivo))
    write_csv(estatisticas_profundidade, paste0("stats_profundidade_", nome_arquivo))
    
    # Top 20 diretórios com mais arquivos
    top_diretorios <- arvore_completa %>%
      filter(tipo == "arquivo") %>%
      count(caminho_pai, sort = TRUE) %>%
      head(20)
    
    cat("\n🏆 Top 20 diretórios com mais arquivos:\n")
    print(top_diretorios)
    
    return(arvore_completa)
    
  } else {
    cat("\n❌ FALHA: Nenhum dado foi coletado!\n")
    cat("🔍 Verifique:\n")
    cat("   - Conexão com internet\n")
    cat("   - Disponibilidade do servidor IBGE\n")
    cat("   - Estrutura do site (pode ter mudado)\n")
    return(NULL)
  }
}

# EXECUTAR O MAPEAMENTO COMPLETO
cat("⚠️  ÚLTIMO AVISO: Este processo pode ser MUITO longo!\n")
cat("💡 Pressione Ctrl+C a qualquer momento para parar.\n")
cat("🔄 Iniciando em 5 segundos...\n\n")

Sys.sleep(5)

resultado_completo <- main_completo()

# Análise rápida se houver dados
if (!is.null(resultado_completo) && nrow(resultado_completo) > 0) {
  cat("\n🔍 PRÉVIA DOS RESULTADOS:\n")
  
  # Mostrar estrutura
  cat("\n📋 Estrutura dos dados:\n")
  str(resultado_completo)
  
  # Primeiras e últimas linhas
  cat("\n🔝 Primeiras 5 linhas:\n")
  print(head(resultado_completo, 5))
  
  cat("\n🔚 Últimas 5 linhas:\n")
  print(tail(resultado_completo, 5))
  
  # Arquivo mais profundo
  mais_profundo <- resultado_completo[which.max(resultado_completo$profundidade), ]
  cat("\n🏔️  Item mais profundo (nível", mais_profundo$profundidade, "):\n")
  cat("   📁", mais_profundo$nome, "\n")
  cat("   🔗", mais_profundo$url_completa, "\n")
}