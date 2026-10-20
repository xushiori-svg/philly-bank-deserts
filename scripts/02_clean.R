library(dplyr)
library(sf)

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

tracts <- st_read("data/raw/philly_tracts.gpkg")
branches <- read.csv("data/raw/fdic_branches.csv")

# 11 = brick and mortar, 12 = retail office
table(branches$SERVTYPE_DESC)

branches <- branches %>%
  filter(SERVTYPE %in% c(11, 12), !is.na(LATITUDE))

branch_pts <- branches %>%
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) %>%
  st_transform(2272)

branch_philly <- branch_pts %>%
  filter(COUNTY == "Philadelphia")

nrow(branch_philly)

tracts <- tracts %>%
  st_transform(2272) %>%
  transmute(
    GEOID,
    tract = sub("[;,].*", "", NAME),
    income = incomeE,
    pop = popE,
    nocar_rate = hh_nocarE / hh_totalE,
    poverty_rate = pov_belowE / pov_totalE
  ) %>%
  filter(pop > 0) 

centers <- st_centroid(tracts)
nearest <- st_nearest_feature(centers, branch_pts)

tracts <- tracts %>%
  mutate(
    dist_mi = as.numeric(st_distance(centers, branch_pts[nearest, ], by_element = TRUE)) / 5280,
    nearest_bank = branch_pts$NAME[nearest],
    n_branches = lengths(st_intersects(tracts, branch_pts)),
    desert_half = dist_mi > 0.5,
    desert_one = dist_mi > 1,
    income_group = ntile(income, 5)
  )

# income quintile labels
tracts$income_group <- factor(
  tracts$income_group,
  levels = 1:5,
  labels = c("Lowest 20%", "2nd", "3rd", "4th", "Highest 20%")
)

# summary by income group
summary_income <- tracts %>%
  st_drop_geometry() %>%
  filter(!is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(
    tracts = n(),
    residents = sum(pop),
    median_income = median(income),
    avg_dist_mi = weighted.mean(dist_mi, pop),
    share_desert_half = sum(pop[desert_half]) / sum(pop),
    share_desert_one = sum(pop[desert_one]) / sum(pop),
    branches_per_10k = sum(n_branches) / sum(pop) * 10000,
    .groups = "drop"
  )

summary_income

st_write(tracts, "data/clean/tracts_bank_access.gpkg", delete_dsn = TRUE)
st_write(branch_philly, "data/clean/branches_philly.gpkg", delete_dsn = TRUE)
write.csv(summary_income, "results/summary_by_income.csv", row.names = FALSE)
