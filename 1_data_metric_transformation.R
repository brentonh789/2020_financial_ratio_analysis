library(readr)
library(tidyverse)

###import data
tag <- read_delim("input_data/2020q1/tag.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
num <- read_delim("input_data/2020q1/num.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
pre <- read_delim("input_data/2020q1/pre.txt", 
                 "\t", escape_double = FALSE, trim_ws = TRUE)
sub <- read_delim("input_data/2020q1/sub.txt", 
                 "\t", escape_double = FALSE, trim_ws = TRUE)


###filter for California businss address and 10K reports and latest data based on year if their are duplicates
cal_companies <- sub %>%
  filter(form == '10-K') %>%
  filter(countryba == 'US' & stprba == 'CA') %>%
  group_by(name) %>%
  top_n(1, fy)


###filter for financial measures that are in interest in DuPont anlaysis
#tags of interest: Revenue, Assets , StockholdersEquity, NetIncomeLoss
#ignore coreg entities, coregistrant of the parent company registrant

measures_ofi_list <- c('Revenues','RevenueFromContractWithCustomerExcludingAssessedTax', 'Assets','StockholdersEquity','NetIncomeLoss','Netincome')
measures_ofi <- num %>%
  filter(tag %in% measures_ofi_list) %>%
  filter(ddate == 20191231, qtrs %in% c(0, 4)) %>%
  filter(is.na(coreg))


###filter out companies that didnt report 10-K in 2020Q1 (may change for 2019Q4 also)
dp_measures <- inner_join(cal_companies, measures_ofi, by='adsh')
dp_measures <- dp_measures %>% 
  select(-c(qtrs)) %>%
  spread(tag, value)

###Use RevenueFromContractWithCustomerExcludingAssessedTax, but if null use Revenue for final revenue value
dp_measures$Final_revenue <- ifelse(is.na(dp_measures$RevenueFromContractWithCustomerExcludingAssessedTax), dp_measures$Revenues, dp_measures$RevenueFromContractWithCustomerExcludingAssessedTax)

#modify columns names in DuPont nameclature and calculate financial ratios
dp_financial_ratios <- dp_measures %>%
  select(name, 
         cityba,
         zipba,
         Final_revenue , 
         Assets,
         StockholdersEquity,
         NetIncomeLoss)  %>%
  rename(company = name,
         city_business_address = cityba,
         zip_business_address = zipba,
         revenue = Final_revenue,
         assets = Assets,
         stockholders_equity = StockholdersEquity,
         net_income = NetIncomeLoss
  ) %>%
  mutate(roe = net_income/stockholders_equity,
         net_profit_margin = net_income/revenue,
         return_on_assets = revenue/assets,
         leverage = assets/stockholders_equity)


write.csv(dp_financial_ratios, '2_output_data/dp_financial_ratios.csv', row.names=FALSE)

