library(eurlex)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)

result <- elx_fetch_data(
    url = "http://publications.europa.eu/resource/celex/32002D0580",
    type = "text"
)