library(readr)
library(tidyverse)
#rm(list=ls())

df_fin <- read_csv("2_output_data/dp_financial_ratios_vol.csv")

##filter out any NA financial ratios, this was generally caused by lack of standarnization in naming each measure in the financial statement. This would require heavy and intenstive data validation into each financial statement and how it maps to the sec data. 
df_fin <- df_fin %>%
  drop_na() %>%
  filter_all(all_vars(!is.infinite(.)))


###run init regression model
fit <- lm(volatility ~ return_on_assets + net_profit_margin + leverage, data = df_fin)


###Outliers
#Remvove outliers based on cook distance 
df_fin_mod <- df_fin[!as.numeric(cooks.distance(fit) >= 4/length(df_fin$cik)),]


###run regression model v2 (remove profit margin and leverage since insigificant)
fit <- lm(volatility ~ return_on_assets, data = df_fin_mod)
ggplot(data = df_fin_mod, aes(x=return_on_assets, y=volatility)) + geom_point() + geom_smooth(method = 'lm')
summary(fit)


###run regression model v3 (high levefrage points can be making model return on assets signficant)
df_fin_mod_remove_hl <- df_fin_mod %>%
  filter(return_on_assets < 2)
fit <- lm(volatility ~ return_on_assets, data = df_fin_mod_remove_hl)
summary(fit)
ggplot(data = df_fin_mod_remove_hl, aes(x=return_on_assets, y=volatility)) + geom_point() + geom_smooth(method = 'lm')


###run final regression model (high leverage point did not make the return_on_assets model insigficant anymore, so it is kept in final regression model)
fit <- lm(volatility ~ return_on_assets, data = df_fin_mod)
summary(fit)
ggplot(data = df_fin_mod, aes(x=return_on_assets, y=volatility)) + geom_point() + geom_smooth(method = 'lm')  + xlab('Return on Assets (ROA)') + ylab ('Volatility (Standard Deviation % Stock Change)')


        