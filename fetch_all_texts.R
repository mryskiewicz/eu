# Skrypt do pobierania tekstów wszystkich aktów z pliku regulations.csv
library(eurlex)
library(dplyr)
library(purrr)
library(readr)
library(tidyr)

# Wczytujemy funkcję fetch_eu_act_text z poprzedniego skryptu
source("fetch_eu_texts.R")

# Wczytujemy dane z pliku CSV
cat("Wczytywanie danych z pliku regulations.csv...\n")
regulations_data <- read_csv("regulations.csv")

# Sprawdzamy, czy kolumna celex istnieje
if (!"celex" %in% colnames(regulations_data)) {
  stop("Kolumna 'celex' nie została znaleziona w pliku regulations.csv")
}

# Pobieramy unikalne numery CELEX
celex_numbers <- unique(regulations_data$celex)
cat(sprintf("Znaleziono %d unikalnych numerów CELEX\n", length(celex_numbers)))

# Tworzymy katalog na wyniki, jeśli nie istnieje
dir.create("data", showWarnings = FALSE)

# Funkcja do zapisywania wyników
save_results <- function(results, batch_number) {
  # Zapisujemy do osobnych plików tekstowych
  for (i in seq_along(results)) {
    if (!is.na(results[[i]]$text)) {
      text_file <- sprintf("data/%s.txt", results[[i]]$celex)
      writeLines(results[[i]]$text, text_file)
    }
  }
}

# Pobieramy teksty w partiach po 10 aktów
batch_size <- 10
total_batches <- ceiling(length(celex_numbers) / batch_size)

for (batch in 1:total_batches) {
  start_idx <- (batch - 1) * batch_size + 1
  end_idx <- min(batch * batch_size, length(celex_numbers))
  
  cat(sprintf("\nPobieranie partii %d z %d (akty %d-%d)...\n", 
              batch, total_batches, start_idx, end_idx))
  
  # Pobieramy teksty dla aktualnej partii
  batch_results <- map(celex_numbers[start_idx:end_idx], fetch_eu_act_text)
  
  # Zapisujemy wyniki
  save_results(batch_results, batch)
  
  # Dodajemy małe opóźnienie między partiami, aby nie przeciążać API
  if (batch < total_batches) {
    Sys.sleep(2)
  }
}

cat("\nZakończono pobieranie tekstów!\n")
cat("Wyniki zostały zapisane w katalogu 'data'\n") 