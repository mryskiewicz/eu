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

# Sprawdzamy, które dokumenty są już pobrane
existing_files <- list.files("data", pattern = "\\.txt$")
existing_celex <- gsub("\\.txt$", "", existing_files)
celex_to_fetch <- celex_numbers[!celex_numbers %in% existing_celex]

cat(sprintf("Znaleziono %d już pobranych dokumentów\n", length(existing_celex)))
cat(sprintf("Pozostało do pobrania: %d dokumentów\n", length(celex_to_fetch)))

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
total_batches <- ceiling(length(celex_to_fetch) / batch_size)

# Inicjalizacja zmiennych do mierzenia czasu
start_time <- Sys.time()
last_batch_time <- start_time

for (batch in 1:total_batches) {
  batch_start_time <- Sys.time()
  start_idx <- (batch - 1) * batch_size + 1
  end_idx <- min(batch * batch_size, length(celex_to_fetch))
  
  cat(sprintf("\nPobieranie partii %d z %d (akty %d-%d)...\n", 
              batch, total_batches, start_idx, end_idx))
  
  # Pobieramy teksty dla aktualnej partii
  batch_celex <- celex_to_fetch[start_idx:end_idx]
  batch_results <- map(batch_celex, fetch_eu_act_text)
  
  # Zapisujemy wyniki
  save_results(batch_results, batch)
  
  # Obliczamy szacowany pozostały czas
  batch_end_time <- Sys.time()
  batch_duration <- as.numeric(difftime(batch_end_time, batch_start_time, units = "mins"))
  remaining_batches <- total_batches - batch
  estimated_remaining_time <- batch_duration * remaining_batches
  
  cat(sprintf("Czas wykonania partii: %.1f minut\n", batch_duration))
  cat(sprintf("Szacowany pozostały czas: %.1f minut\n", estimated_remaining_time))
  
  # Dodajemy małe opóźnienie między partiami, aby nie przeciążać API
  if (batch < total_batches) {
    Sys.sleep(.5)
  }
}

end_time <- Sys.time()
total_duration <- as.numeric(difftime(end_time, start_time, units = "mins"))

cat("\nZakończono pobieranie tekstów!\n")
cat(sprintf("Całkowity czas wykonania: %.1f minut\n", total_duration))
cat("Wyniki zostały zapisane w katalogu 'data'\n") 