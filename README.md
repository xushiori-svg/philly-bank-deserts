# Bank Branch Deserts in Philadelphia

Question: Are bank branches concentrated in high-income neighborhoods of Philadelphia, and which low-income areas have no branch nearby?

## Data

- **ACS 5-year estimates (2020-2024), census tracts, Philadelphia County**, downloaded with `tidycensus`: median household income (B19013), total population (B01003), poverty status (B17001), households without a vehicle (B08201), and tract boundaries.
- **ZIP Code Tabulation Areas (2020)**, downloaded with `tigris`, used only for the ZIP code search box.
- **FDIC BankFind Suite API** (`https://api.fdic.gov/banks/locations`): locations of FDIC-insured bank offices in Philadelphia, Montgomery, Delaware and Bucks counties. Only full-service branches (SERVTYPE 11 and 12) are used. No API key is needed.

Credit unions (NCUA) and ATMs are not included.

## Folder structure

```
philly-bank-deserts/
├── scripts/
│   ├── 01_get_data.R   download ACS tracts and FDIC branches
│   ├── 02_clean.R      distance to nearest branch, desert flags, summary by income
│   ├── 03_figures.R    maps and charts
│   └── 04_zip_map.R    interactive map with a ZIP code search box
├── data/
│   ├── raw/            created by 01
│   └── clean/          created by 02
└── results/            figures and summary table
```

## How to reproduce

1. Install packages once:

   ```r
   install.packages(c("tidycensus", "dplyr", "sf", "jsonlite", "ggplot2",
                      "plotly", "scales", "htmlwidgets", "tigris",
                      "leaflet", "leaflet.extras", "htmltools"))
   ```

2. Get a free Census API key at https://api.census.gov/data/key_signup.html and save it once:

   ```r
   tidycensus::census_api_key("YOUR_KEY", install = TRUE)
   ```

   Restart R after this step.

3. Open the project folder as the working directory and run the scripts in order:

   ```r
   source("scripts/01_get_data.R")
   source("scripts/02_clean.R")
   source("scripts/03_figures.R")
   source("scripts/04_zip_map.R")
   ```

All figures and `results/summary_by_income.csv` are written by the code.

## Definitions

- Distance is measured from the tract's geographic center to the nearest full-service branch (straight line, in miles).
- A tract is a **bank desert** if it has no full-service branch within 0.5 miles. A 1-mile version is also reported.
- Income groups are quintiles of tract median household income.
