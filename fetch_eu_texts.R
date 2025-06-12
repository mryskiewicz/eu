# Skrypt do pobierania tekstów aktów UE po numerze CELEX
library(eurlex)
library(dplyr)
library(purrr)

#' Pobiera tekst aktu UE po numerze CELEX
#' @param celex_number Numer CELEX aktu (np. "32019R0123")
#' @return Lista zawierająca tytuł i tekst aktu w języku angielskim
fetch_eu_act_text <- function(celex_number) {
  tryCatch({
    # Tworzymy pełny URL do zasobu
    url <- paste0("http://publications.europa.eu/resource/celex/", celex_number)
    
    # Pobieramy tytuł
    title <- elx_fetch_data(url = url, type = "title", language_1 = "en")
    
    # Pobieramy tekst
    text <- elx_fetch_data(url = url, type = "text", language_1 = "en")
    
    return(list(
      celex = celex_number,
      title = title,
      text = text,
      status = "success"
    ))
  }, error = function(e) {
    return(list(
      celex = celex_number,
      title = NA,
      text = NA,
      status = paste("error:", e$message)
    ))
  })
}

#' Przykład użycia:
#' celex_numbers <- c("32019R0123", "32019L0790")
#' results <- map(celex_numbers, fetch_eu_act_text)
#' 
#' # Zapisanie wyników do pliku CSV
#' results_df <- bind_rows(results)
#' write.csv(results_df, "eu_acts_texts.csv", row.names = FALSE)

# Test funkcji
result <- fetch_eu_act_text("32019R0123")
print(result)