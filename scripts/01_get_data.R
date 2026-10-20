#install.packages("tidycensus")
library(tidycensus)
library(dplyr)
library(sf)
library(jsonlite)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

# needs a Census API key
tracts <- get_acs(
  geography = "tract",
  state = "PA",
  county = "Philadelphia",
  variables = c(
    income = "B19013_001",
    pop = "B01003_001",
    pov_total = "B17001_001",
    pov_below = "B17001_002",
    hh_total = "B08201_001",
    hh_nocar = "B08201_002"
  ),
  year = 2024,
  survey = "acs5",
  geometry = TRUE,
  output = "wide"
)

nrow(tracts)
st_write(tracts, "data/raw/philly_tracts.gpkg", delete_dsn = TRUE)

fdic_filter <- "STALP:PA AND STCNTY:(42101 OR 42091 OR 42045 OR 42017)"

fdic_fields <- paste(
  c("NAME", "OFFNAME", "ADDRESS", "CITY", "ZIP", "COUNTY", "STCNTY",
    "LATITUDE", "LONGITUDE", "SERVTYPE", "SERVTYPE_DESC", "ESTYMD", "CERT"),
  collapse = ","
)

fdic_url <- paste0(
  "https://api.fdic.gov/banks/locations",
  "?filters=", URLencode(fdic_filter, reserved = TRUE),
  "&fields=", fdic_fields,
  "&limit=10000"
)

res <- fromJSON(fdic_url)
branches <- res$data$data

# check
nrow(branches)
table(branches$COUNTY)

write.csv(branches, "data/raw/fdic_branches.csv", row.names = FALSE)
