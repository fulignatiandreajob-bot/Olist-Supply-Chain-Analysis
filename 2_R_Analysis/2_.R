#Set up the working library
install.packages("tidyverse")
install.packages("psych")
install.packages("ggplot2")
install.packages("skimr")
install.packages("visreg")
install.packages("stargazer")
install.packages("sjPlot")
install.packages("car")
install.packages("gtsummary")

library(tidyverse)
library(psych) 
library(ggplot2) 
library(skimr)
library(visreg)
library(stargazer)
library(sjPlot)
library(car)
library(gtsummary)

df <- read_csv("mini_dataset.csv", show_col_types = FALSE)

df <- df %>% 
  mutate(
    delivery_gap = as.numeric(delivery_gap), 
    seller_rank = as.numeric(seller_rank), 
    peso_kg = as.numeric(peso_totale_grammi) / 1000, #weight in kg
    customer_state = as.factor(customer_state)
  ) 

skim(df) 

# Control missing value
sum(is.na(df))

# clean the dataset remouving NA
df <- na.omit(df)


#eliminate the extreme value
df_clean <- df %>%
  filter(seller_rank > -160)

# CHECK: Verifichiamo che il minimo non sia più -171
cat("Nuovo valore minimo:", min(df_clean$seller_rank, na.rm = TRUE), "\n")


# -----------------------------------------------------------------------------
# 4. regression
# -----------------------------------------------------------------------------

model_olist <- lm(delivery_gap ~ seller_rank + peso_kg + customer_state, data = df)

summary(model_olist) 

# -----------------------------------------------------------------------------
# 5. Results
# -----------------------------------------------------------------------------
table_results <- tbl_regression(model_olist, intercept = TRUE,
                                label = list(
                                  seller_rank ~ "Seller Lead Time (Days)", 
                                  peso_kg ~ "Package Weight (Kg)"
                                )) %>% 
  add_glance_table(include = c(adj.r.squared)) %>% 
  add_significance_stars(hide_ci = FALSE, hide_p = FALSE) %>% 
  modify_header(label = "**Variable**", p.value = "**P**") %>%
  modify_caption("**Regression Analysis: Drivers of Delivery Delay** (N = {N})") %>%
  as_gt() %>%
  gt::tab_options(table.font.names = "Times New Roman")

print(table_results)
gt::gtsave(table_results, file = "Table_Olist_Regression.png")

# -----------------------------------------------------------------------------
# 6. Diagnostic
# -----------------------------------------------------------------------------

# Controllo Outliers (Distanza di Cook)
CooksD <- cooks.distance(model_olist)
sort(CooksD, decreasing = TRUE) %>% head() 

# Grafici diagnostici 4-in-1
par(mfrow = c(2, 2)) 
plot(model_olist)
par(mfrow = c(1, 1))


# -----------------------------------------------------------------------------
# 7. Seller responsability
# -----------------------------------------------------------------------------

#I first calculate the mean of the seller_rank of order that was on time

df_mini1 <- df %>% 
  filter(delivery_gap <= 0)
standard_rank <- mean(df_mini1$seller_rank, na.rm = TRUE)

#then I found the delay that was caused by a seller that sent the order later than the standard rank
df_mini2 <- df %>%
  filter(seller_rank > standard_rank, delivery_gap>0)
seller_delate <- nrow(df_mini2)

print(seller_delate)



# 9. Final Export for Tableau (Custom Columns)

df_export <- df %>%

  mutate(
    # 1 se in ritardo, 0 se puntuale.
    # Su Tableau farai: SUM(is_late) / COUNT(order_id)
    is_late = ifelse(delivery_gap > 0, 1, 0),

    # 1 se il ritardo è colpa del venditore, 0 altrimenti (puntuale o colpa logistica)
    seller_fault_flag = ifelse(delivery_gap > 0 & seller_rank > standard_rank, 1, 0),
  
    # Questa colonna contiene la "Linea" matematica calcolata da R.
    # Rappresenta il ritardo PREVISTO dal modello in base a peso, rank e stato.
    #la colonna non contiene la formula, ma il RISULTATO della formula per quella specifica riga
    regression_prediction = predict(model_olist, newdata = df)
  ) %>%
  # B. Calcoli raggruppati per Stato (Per la Mappa - Grafico B)
  group_by(customer_state) %>%
  mutate(
    state_avg_gap = mean(delivery_gap, na.rm = TRUE)
  ) %>%
  ungroup() # Importante: sblocca il raggruppamento

# 3. è un check molto utile se per vedere se le colonne ci sono tutte, nel caso ci siano troppe colonne ne potrebbe tagliare alcune, questo le mette sulle righe e ti garantisce che non vengano tagliate
glimpse(df_export)

# 4. Esportazione CSV
write_csv(df_export, "Olist_Final_Export1.csv")






