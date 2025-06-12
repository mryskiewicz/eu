# Instalacja pakietu eurlex (odkomentuj jeśli nie jest zainstalowany)
# install.packages("eurlex")

# Załadowanie pakietu
library(eurlex)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)

# Dodanie obsługi błędów
tryCatch({
  # 1. Najpierw pobierzmy propozycje aktów prawnych (sektor 3)
  cat("Pobieranie propozycji aktów prawnych...\n")
  acts_proposals <- elx_make_query(
    resource_type = "any",
    sector = 3,
    include_date = TRUE,
    include_proposal = TRUE
  ) |>
    elx_run_query() |>
    select(-work)
  
  # 2. Filtrujemy tylko akty prawne
  cat("\nFiltrowanie aktów prawnych...\n")
  acts <- acts_proposals |>
    filter(!is.na(celex),
           !date %in% c("1003-03-03")) |>
    distinct(celex, .keep_all = TRUE) |>
    select(-proposal)
  
  # 3. Pobieramy informacje o aktach w mocy
  cat("\nPobieranie informacji o aktach w mocy...\n")
  in_force <- elx_make_query(
    resource_type = "any",
    sector = 3,
    include_force = TRUE,
    include_date_force = TRUE
  ) |>
    elx_run_query() |>
    select(-work) |>
    rename(date_force = dateforce) |>
    arrange(celex, date_force) |>
    distinct(celex, .keep_all = TRUE) |>
    drop_na() |>
    filter(between(as.Date(date_force), 
                  as.Date("1952-01-01"),
                  as.Date(Sys.Date())))
  
  # 4. Dzielimy na główne typy aktów
  cat("\nDzielenie na typy aktów...\n")
  regs <- acts |> filter(str_sub(celex,6,6) == "R")
  decs <- acts |> filter(str_sub(celex,6,6) == "D")
  dirs <- acts |> filter(str_sub(celex,6,6) == "L")
  recs <- acts |> filter(str_sub(celex,6,6) == "H")
  
  # Wyświetlenie podstawowych statystyk
  cat("\nStatystyki:\n")
  cat("Liczba rozporządzeń:", nrow(regs), "\n")
  cat("Liczba decyzji:", nrow(decs), "\n")
  cat("Liczba dyrektyw:", nrow(dirs), "\n")
  cat("Liczba rekomendacji:", nrow(recs), "\n")
  cat("Liczba aktów w mocy:", nrow(in_force), "\n")
  
  # Zapisanie wyników do plików CSV
  cat("\nZapisywanie wyników do plików CSV...\n")
  write.csv(regs, "regulations.csv", row.names = FALSE)
  write.csv(decs, "decisions.csv", row.names = FALSE)
  write.csv(dirs, "directives.csv", row.names = FALSE)
  write.csv(recs, "recommendations.csv", row.names = FALSE)
  write.csv(in_force, "in_force.csv", row.names = FALSE)
  
  cat("Zakończono pomyślnie!\n")
  
}, error = function(e) {
  cat("Wystąpił błąd:\n")
  print(e)
  cat("\nSzczegóły połączenia:\n")
  print(httr::GET("http://publications.europa.eu/webapi/rdf/sparql"))
}) 