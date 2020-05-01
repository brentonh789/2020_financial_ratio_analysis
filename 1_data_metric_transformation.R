library(readr)
library(tidyverse)
tag <- read_delim("input_data/2020q1/tag.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
num <- read_delim("input_data/2020q1/num.txt", 
                  "\t", escape_double = FALSE, trim_ws = TRUE)
#pre <- read_delim("input_data/2020q1/pre.txt", 
#                  "\t", escape_double = FALSE, trim_ws = TRUE)
#sub <- read_delim("input_data/2020q1/sub.txt", 
 #                 "\t", escape_double = FALSE, trim_ws = TRUE)


#filter for California businss address and 10K reports
#filter for latest data based on year if their are duplicates
cal_companies <- sub %>%
  filter(form == '10-K') %>%
  filter(countryba == 'US' & stprba == 'CA') %>%
  group_by(name) %>%
  top_n(1, fy)

#tags of interest: Revenue, Assets , StockholdersEquity, NetIncomeLoss, Netincome
#filter for measures of interest
#ignore coreg entities, coregistrant of the parent company registrant

measures_ofi_list <- c('Revenues', 'Assets','StockholdersEquity','NetIncomeLoss','Netincome')

measures_ofi <- num %>%
  filter(tag %in% measures_ofi_list) %>%
  filter(ddate == 20191231, qtrs %in% c(0, 4)) %>%
  filter(is.na(coreg))

#tag


##remove companies that didn;t report 10-K in 2020Q1 for now
dp_measures <- inner_join(cal_companies, measures_ofi, by='adsh')

dp_measures <- dp_measures %>% 
  select(-c(qtrs)) %>%
  spread(tag, value)

