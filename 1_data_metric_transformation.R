library(readr)
library(tidyverse)
library(tidyquant)
#rm(list=ls())

###import data
tag <- read_delim("1_input_data/2020q1/tag.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
num <- read_delim("1_input_data/2020q1/num.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
pre <- read_delim("1_input_data/2020q1/pre.txt", 
                 "\t", escape_double = FALSE, trim_ws = TRUE)
sub <- read_delim("1_input_data/2020q1/sub.txt", 
                 "\t", escape_double = FALSE, trim_ws = TRUE)


###filter for US businss address and 10K reports and latest data based on year if their are duplicates
cal_companies <- sub %>%
  filter(form == '10-K') %>%
  filter(countryba == 'US') %>%
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
#filter out company 1761940, because it had duplicated net loss

dp_measures <- inner_join(cal_companies, measures_ofi, by='adsh')
dp_measures <- dp_measures %>% 
  filter(!cik %in% c(1761940)) %>%
  select(-c(qtrs)) %>%
  spread(tag, value)


###Use RevenueFromContractWithCustomerExcludingAssessedTax, but if null use Revenue for final revenue value
dp_measures$Final_revenue <- ifelse(is.na(dp_measures$RevenueFromContractWithCustomerExcludingAssessedTax), dp_measures$Revenues, dp_measures$RevenueFromContractWithCustomerExcludingAssessedTax)


#modify columns names in DuPont nameclature and calculate financial ratios
dp_financial_ratios <- dp_measures %>%
  select(name, 
         cik,
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

######Import and calculaute stock data for s&p100 list for data
cik_ticker <- read_delim("1_input_data/cik_ticker.csv", 
                         "|", escape_double = FALSE, trim_ws = TRUE)
#get list of 100 to filter out low stocks. Unable to pull all stock data for all tickers
sp100_list <- read_csv("1_input_data/s&p100_list.csv")

cik_ticker <- cik_ticker %>%
  select('CIK','Ticker') %>%
  filter(Ticker %in% sp100_list$Symbol) %>%
  top_n(1, 'CIK')



#filter out for CIK that are not in mapping file and not in sp100 list. Generally null company names
#dp_financial_ratios <- inner_join(dp_financial_ratios, cik_ticker, by=c("cik"="CIK"))
dp_financial_ratios <- inner_join(dp_financial_ratios, cik_ticker, by=c("cik"="CIK"))

# set tickers
tickers <- dp_financial_ratios$Ticker

#get stock prices from covid start to current date
prices <- tq_get(tickers,
           from = "2020-03-01",
           to = "2020-05-15",
           get = "stock.prices")

prices <- prices %>%
  select(symbol,
         date,
         close) 

#calculate standard deviation of % daily change
#% daily change is used to easily compare between companies
prices_agg<-prices  %>%
  group_by(symbol) %>%
  mutate(lag_close = lag(close, n = 1, default = NA)) %>%
  mutate(perc_change = close/lag_close - 1) %>%
  group_by(symbol) %>%
  summarise(volatility = sd(perc_change, na.rm=TRUE))


######join financial ratio and stock data
dp_financial_ratios_vol <- inner_join(dp_financial_ratios, prices_agg, by = c("Ticker" = "symbol"))


write.csv(dp_financial_ratios_vol, '2_output_data/dp_financial_ratios_vol.csv', row.names=FALSE)


