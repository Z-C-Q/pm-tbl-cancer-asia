suppressPackageStartupMessages({library(dplyr);library(readr)})
out <- getOption('tbl.results_dir')
standardize <- function(x) {
 x <- x %>% rename(HALE=LE,GDP_per_capita_const2021=GDPpc_const2021,GDP_per_capita=GDPpc_2023,ISO3=Country.Code)
 if('LE_lower'%in%names(x)) x <- x %>% rename(HALE_lower=LE_lower,HALE_upper=LE_upper)
 if('VLW_GDP_ratio'%in%names(x)) x <- x %>% rename(VLW_GDP_pct=VLW_GDP_ratio)
 x %>% mutate(VLW_GDP=VLW/GDP,per_capita_VLW=VLW_per_capita,monetary_unit='Constant 2023 international dollars')
}
a <- read_csv(file.path(out,'Data/analysis_ready_primary_valuation.csv'),show_col_types=FALSE) %>% standardize() %>% mutate(epsilon=1,hale_factor=.5,hale_convention='HALE/2 primary')
s <- read_csv(file.path(out,'Data/elasticity_sensitivity_all_country_year_sex_scenarios.csv.gz'),show_col_types=FALSE) %>% standardize()
write_csv(a,file.path(out,'Data/analysis_ready_primary.csv'))
write_csv(s,file.path(out,'Data/valuation_all_scenarios.csv.gz'))
for(e in c(.5,1,1.5)) for(h in c(.5,1)) write_csv(s %>% filter(epsilon==e,hale_factor==h),file.path(out,'Data',paste0('valuation_epsilon_',e,'_',if(h==.5)'half_HALE' else 'full_HALE','.csv.gz')))
cat('Exported',nrow(a),'primary rows and',nrow(s),'six-scenario rows.\n')
