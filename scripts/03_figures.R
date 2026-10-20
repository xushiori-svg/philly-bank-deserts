# 03_figures.R
# Maps and charts for the blog post

library(dplyr)
library(sf)
library(ggplot2)
library(plotly)
library(scales)
library(htmlwidgets)

dir.create("results", showWarnings = FALSE)

tracts <- st_read("data/clean/tracts_bank_access.gpkg")
branch_philly <- st_read("data/clean/branches_philly.gpkg")
summary_income <- read.csv("results/summary_by_income.csv")

summary_income$income_group <- factor(
  summary_income$income_group,
  levels = c("Lowest 20%", "2nd", "3rd", "4th", "Highest 20%")
)

source_note <- "Source: ACS 2020-2024 5-year estimates; FDIC BankFind Suite (full-service branches)"

# Figure 1: income map with bank branches (static)
p1 <- ggplot() +
  geom_sf(data = tracts, aes(fill = income), color = "white", linewidth = 0.05) +
  geom_sf(data = branch_philly, shape = 21, size = 1.4, fill = "white", color = "black", stroke = 0.3) +
  scale_fill_viridis_b(
    labels = label_dollar(),
    breaks = c(30000, 50000, 75000, 100000, 150000),
    na.value = "grey85",
    name = "Median household\nincome"
  ) +
  labs(
    title = "Median Household Income and Bank Branches in Philadelphia",
    subtitle = "Each dot is one full-service bank branch",
    caption = source_note
  ) +
  theme_void()



p1
ggsave("results/fig1_income_branches.png", p1, width = 7, height = 7.5, dpi = 300, bg = "white")

# Figure 2: distance to nearest branch (interactive map)
p2 <- ggplot(tracts) +
  geom_sf(
    aes(
      fill = dist_mi,
      text = paste0(
        "<b>", tract, "</b><br>",
        "Median income: ", dollar(income, accuracy = 1), "<br>",
        "Residents: ", comma(pop), "<br>",
        "Households without a car: ", percent(nocar_rate, accuracy = 1), "<br>",
        "Nearest branch: ", round(dist_mi, 2), " mi (", nearest_bank, ")<br>",
        "Branches in tract: ", n_branches
      )
    ),
    color = "white",
    linewidth = 0.05
  ) +
  scale_fill_distiller(palette = "Reds", direction = 1, name = "Miles to\nnearest branch") +
  labs(title = "Distance from Each Tract to the Nearest Bank Branch") +
  theme_void()

p2
ggsave("results/fig2_distance_map.png", p2 + labs(caption = source_note),
       width = 7, height = 7.5, dpi = 300, bg = "white")

p2_int <- ggplotly(p2, tooltip = "text") %>%
  style(hoveron = "fills")

p2_int
saveWidget(p2_int, "results/fig2_distance_map.html", selfcontained = TRUE)
unlink("results/fig2_distance_map_files", recursive = TRUE)

# Figure 3: share of residents in a bank desert, by tract income group
p3 <- ggplot(
  summary_income,
  aes(
    x = income_group,
    y = share_desert_half,
    text = paste0(
      "<b>", income_group, "</b><br>",
      "Share in bank desert: ", percent(share_desert_half, accuracy = 0.1), "<br>",
      "Median income: ", dollar(median_income, accuracy = 1), "<br>",
      "Tracts: ", tracts, "<br>",
      "Residents: ", comma(residents)
    )
  )
) +
  geom_col(fill = "#990000") +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "Share of Residents with No Bank Branch within 0.5 Miles",
    x = "Tract median household income group",
    y = NULL,
    caption = source_note
  ) +
  theme_minimal()

p3
ggsave("results/fig3_desert_by_income.png", p3, width = 7, height = 4.5, dpi = 300, bg = "white")

p3_int <- ggplotly(p3, tooltip = "text")
saveWidget(p3_int, "results/fig3_desert_by_income.html", selfcontained = TRUE)
unlink("results/fig3_desert_by_income_files", recursive = TRUE)

# Figure 4: income vs distance, one dot per tract
p4 <- ggplot(
  st_drop_geometry(tracts) %>% filter(!is.na(income)),
  aes(
    x = income,
    y = dist_mi,
    text = paste0(
      "<b>", tract, "</b><br>",
      "Median income: ", dollar(income, accuracy = 1), "<br>",
      "Nearest branch: ", round(dist_mi, 2), " mi"
    )
  )
) +
  geom_point(alpha = 0.5, color = "#011F5B") +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey40") +
  scale_x_continuous(labels = label_dollar()) +
  labs(
    title = "Tract Income and Distance to the Nearest Bank Branch",
    x = "Median household income",
    y = "Miles to nearest branch",
    caption = source_note
  ) +
  theme_minimal()

p4
ggsave("results/fig4_income_vs_distance.png", p4, width = 7, height = 4.5, dpi = 300, bg = "white")
