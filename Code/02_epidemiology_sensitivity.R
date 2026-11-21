suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2);library(patchwork);library(scales)})
out<-getOption('tbl.results_dir');d<-readRDS(file.path(out,'Data/prepared_inputs.rds'));a<-d$legacy
reglevels<-c('Asia','East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East')
cols<-c('Asia'='#222222','East Asia'='#D55E00','Southeast Asia'='#009E73','South Asia'='#0072B2','Central Asia'='#CC79A7','High-income Asia Pacific'='#E69F00','Middle East'='#56B4E9')
theme_p<-theme_bw(base_size=11)+theme(panel.grid.minor=element_blank(),legend.position='bottom',legend.title=element_blank(),plot.title=element_text(face='bold'))
savefig<-function(p,name,w=12,h=7){for(ext in c('pdf','png','tiff')){args<-list(filename=file.path(out,'Figures',paste0(name,'.',ext)),plot=p,width=w,height=h,bg='white');if(ext!='pdf')args$dpi<-300;if(ext=='tiff')args$compression<-'lzw';do.call(ggsave,args)}}
num<-d$raw %>% filter(age_id%in%d$w1$age_id,metric_name=='Number') %>% select(location_id,region_6,year,age_id,DALYs=val) %>% left_join(d$pop %>% select(location_id,year,age_id,population),by=c('location_id','year','age_id'))
stopifnot(!anyNA(num$population))
pooled<-bind_rows(num %>% group_by(region=region_6,year,age_id) %>% summarise(DALYs=sum(DALYs),population=sum(population),.groups='drop'),num %>% group_by(year,age_id) %>% summarise(region='Asia',DALYs=sum(DALYs),population=sum(population),.groups='drop'))
asdr<-pooled %>% left_join(d$w1,by='age_id') %>% group_by(region,year) %>% summarise(ASDR=sum(DALYs/population*1e5*w),.groups='drop')
epi<-d$epi %>% left_join(asdr,by=c('region','year')) %>% mutate(region=factor(region,levels=reglevels))
write_csv(epi,file.path(out,'Data/Figure_1CD_DALYs_ASDR_source.csv'))
ends<-epi %>% filter(year%in%c(1990,2023)) %>% pivot_wider(names_from=year,values_from=c(DALYs,ASDR)) %>% mutate(DALYs_change_pct=(DALYs_2023/DALYs_1990-1)*100,ASDR_change_pct=(ASDR_2023/ASDR_1990-1)*100)
write_csv(ends,file.path(out,'Tables/Table_S3_DALY_ASDR_changes.csv'))
write_csv(d$w1 %>% left_join(d$raw %>% select(age_id,age_name) %>% distinct(),by='age_id'),file.path(out,'Tables/GBD_standard_weights_used.csv'))
# Complete valuation sensitivity; the primary model and currency basis have been confirmed by the author.
sens<-crossing(epsilon=d$cfg$income_elasticity_scenarios,hale_convention=c('HALE/2 primary','HALE sensitivity')) %>% mutate(hale_factor=ifelse(hale_convention=='HALE/2 primary',.5,1)) %>% crossing(a %>% select(location_id,location_name,Country.Code,region_6,year,sex_id,sex_name,DALYs,DALYs_lower,DALYs_upper,LE,GDPpc_const2021,GDPpc_2023,GDP,population)) %>% mutate(VSL=d$cfg$VSL_USA_2023*(GDPpc_const2021/d$usa_ref)^epsilon,VSLY=VSL/(LE*hale_factor),VLW=DALYs*VSLY,VLW_DALY_lower=DALYs_lower*VSLY,VLW_DALY_upper=DALYs_upper*VSLY,VLW_GDP_pct=100*VLW/GDP,VLW_per_capita=VLW/population,monetary_unit='Constant 2023 international dollars')
write_csv(sens,file.path(out,'Data/elasticity_sensitivity_all_country_year_sex_scenarios.csv.gz'))
both<-sens %>% filter(sex_name=='Both')
panelboth<-bind_rows(both %>% mutate(panel='Available countries'),both %>% filter(location_id%in%d$fullids) %>% mutate(panel='Fixed 43 countries'))
regsens<-bind_rows(panelboth %>% group_by(panel,hale_convention,epsilon,region=region_6,year) %>% summarise(VLW=sum(VLW),GDP=sum(GDP),population=sum(population),n_countries=n_distinct(location_id),.groups='drop'),panelboth %>% group_by(panel,hale_convention,epsilon,year) %>% summarise(region='Asia',VLW=sum(VLW),GDP=sum(GDP),population=sum(population),n_countries=n_distinct(location_id),.groups='drop')) %>% mutate(VLW_billion=VLW/1e9,VLW_GDP_pct=100*VLW/GDP,VLW_per_capita=VLW/population)
write_csv(regsens,file.path(out,'Data/elasticity_sensitivity_region_year.csv'))
reg2023<-regsens %>% filter(year==2023) %>% group_by(panel,hale_convention,epsilon) %>% mutate(VLW_rank=ifelse(region=='Asia',NA,rank(-replace(VLW_billion,region=='Asia',NA),na.last='keep',ties.method='min')),GDP_ratio_rank=ifelse(region=='Asia',NA,rank(-replace(VLW_GDP_pct,region=='Asia',NA),na.last='keep',ties.method='min'))) %>% ungroup()
write_csv(reg2023,file.path(out,'Tables/Table_S4_elasticity_region_2023.csv'))
ct2023<-both %>% filter(year==2023) %>% group_by(hale_convention,epsilon) %>% mutate(VLW_rank=rank(-VLW,ties.method='min'),GDP_ratio_rank=rank(-VLW_GDP_pct,ties.method='min'),per_capita_rank=rank(-VLW_per_capita,ties.method='min')) %>% ungroup()
write_csv(ct2023,file.path(out,'Tables/Table_S5_elasticity_country_2023.csv'))
rankrobust<-ct2023 %>% filter(epsilon!=1) %>% left_join(ct2023 %>% filter(epsilon==1) %>% select(hale_convention,location_id,base_VLW_rank=VLW_rank,base_ratio_rank=GDP_ratio_rank,base_pc_rank=per_capita_rank),by=c('hale_convention','location_id')) %>% group_by(hale_convention,epsilon) %>% summarise(Spearman_VLW=cor(VLW_rank,base_VLW_rank,method='spearman'),Spearman_GDP_ratio=cor(GDP_ratio_rank,base_ratio_rank,method='spearman'),Spearman_per_capita=cor(per_capita_rank,base_pc_rank,method='spearman'),max_VLW_rank_shift=max(abs(VLW_rank-base_VLW_rank)),top10_overlap=sum(VLW_rank<=10&base_VLW_rank<=10),.groups='drop')
write_csv(rankrobust,file.path(out,'Tables/Table_S6_ranking_robustness.csv'))
pricecheck<-regsens %>% filter(region=='Asia',epsilon==1,year%in%c(1990,2023))
write_csv(pricecheck,file.path(out,'Tables/Table_S7_HALE_and_country_panel_sensitivity.csv'))
primary<-regsens %>% filter(panel=='Available countries',epsilon==1,hale_convention=='HALE/2 primary')
write_csv(primary %>% filter(year%in%c(1990,2023)),file.path(out,'Tables/Table1_revision_primary.csv'))
write_csv(regsens %>% filter(panel=='Fixed 43 countries',epsilon==1,hale_convention=='HALE/2 primary',year%in%c(1990,2023)),file.path(out,'Tables/Table_S16_fixed43_country_panel.csv'))
# Equal-country comparison is deliberately restricted to the 43-country complete panel.
fixed<-both %>% filter(location_id%in%d$fullids,epsilon==1,hale_convention=='HALE/2 primary')
basevals<-fixed %>% filter(year==1990) %>% select(location_id,VSLY_1990=VSLY)
index<-fixed %>% left_join(basevals,by='location_id') %>% group_by(year) %>% summarise(`VLW constant 2023 prices`=sum(VLW),`VLW fixed 1990 VSLY`=sum(DALYs*VSLY_1990),DALYs=sum(DALYs),.groups='drop') %>% pivot_longer(-year,names_to='series',values_to='value') %>% group_by(series) %>% mutate(index=value/value[year==1990]*100) %>% ungroup()
write_csv(index,file.path(out,'Data/Figure_S6_index_comparison_fixed43.csv'))
pa<-ggplot(primary,aes(year,VLW_billion,color=factor(region,levels=reglevels)))+geom_line(linewidth=.85)+scale_color_manual(values=cols)+labs(title='A  Monetized welfare loss',x='Year',y='VLW (billion, constant 2023 Int$)')+theme_p
pb<-ggplot(primary,aes(year,VLW_GDP_pct,color=factor(region,levels=reglevels)))+geom_line(linewidth=.85)+scale_color_manual(values=cols)+labs(title='B  Welfare loss relative to GDP',x='Year',y='VLW / GDP (%)')+theme_p
pc<-ggplot(epi,aes(year,DALYs/1e6,color=region))+geom_line(linewidth=.85)+scale_color_manual(values=cols)+labs(title='C  Epidemiological burden',x='Year',y='DALYs (million)')+theme_p
pd<-ggplot(epi,aes(year,ASDR,color=region))+geom_line(linewidth=.85)+scale_color_manual(values=cols)+labs(title='D  Age-standardized DALY rate',x='Year',y='DALYs per 100,000 population')+theme_p
savefig((((pa+pb)/(pc+pd))+plot_layout(guides='collect')+plot_annotation(caption='A-B: 43 countries in 1990, 44 from 1994, 45 from 2000. C-D: the same 45-country health cohort throughout.\nFixed-country comparisons are provided separately.')) & theme(legend.position='bottom',plot.caption=element_text(size=8,hjust=0)),'Figure_1_revision_health_and_welfare',12,10.8)
savefig(((pc+pd)+plot_layout(guides='collect')) & theme(legend.position='bottom'),'Figure_1CD_revision_DALYs_ASDR',12,5.7)
pindex<-ggplot(index,aes(year,index,color=series,linetype=series))+geom_line(linewidth=1)+scale_color_manual(values=c('#222222','#D55E00','#0072B2'))+labs(x='Year',y='Index (1990 = 100)',title='Health loss and monetary valuation',subtitle='Fixed 43-country panel; holding 1990 VSLY constant is a descriptive valuation comparison')+theme_p
savefig(pindex,'Figure_S6_health_vs_valuation_index',11,6)
plotreg<-reg2023 %>% filter(panel=='Available countries',hale_convention=='HALE/2 primary',region!='Asia') %>% mutate(region=factor(region,levels=reglevels[-1]),epsilon=factor(epsilon))
pe1<-ggplot(plotreg,aes(epsilon,VLW_billion,group=region,color=region))+geom_line()+geom_point(size=2)+scale_color_manual(values=cols)+scale_y_log10()+labs(x='Income elasticity',y='VLW (billion, constant 2023 Int$)',title='A  Subregional welfare valuation')+theme_p
pe2<-ggplot(plotreg,aes(epsilon,VLW_GDP_pct,group=region,color=region))+geom_line()+geom_point(size=2)+scale_color_manual(values=cols)+labs(x='Income elasticity',y='VLW / GDP (%)',title='B  Relative welfare valuation')+theme_p
savefig(((pe1+pe2)+plot_layout(guides='collect')) & theme(legend.position='bottom'),'Figure_S7_elasticity_sensitivity',12,5.7)
prank<-ct2023 %>% filter(hale_convention=='HALE/2 primary') %>% mutate(epsilon=factor(epsilon),location_name=factor(location_name,levels=ct2023 %>% filter(hale_convention=='HALE/2 primary',epsilon==1) %>% arrange(desc(VLW_rank)) %>% pull(location_name)))
ph<-ggplot(prank,aes(epsilon,location_name,fill=VLW_rank))+geom_tile(color='white')+geom_text(aes(label=VLW_rank),size=2.7)+scale_fill_gradient(low='#FFFFD9',high='#225EA8',name='VLW rank')+labs(x='Income elasticity',y=NULL,title='Country ranking under alternative income elasticities',subtitle='45 countries in 2023; primary HALE/2 convention')+theme_p+theme(legend.position='right',axis.text.y=element_text(size=8))
savefig(ph,'Figure_S8_country_rank_sensitivity',7,12)
saveRDS(list(epi=epi,ends=ends,index=index,regsens=regsens,reg2023=reg2023,ct2023=ct2023,rankrobust=rankrobust,pricecheck=pricecheck,primary=primary),file.path(out,'Data/supplementary_results.rds'))
cat('EPIDEMIOLOGY\n');print(ends);cat('ELASTICITY\n');print(reg2023 %>% filter(panel=='Available countries',hale_convention=='HALE/2 primary',region=='Asia'));cat('INDEX\n');print(index %>% filter(year==2023));cat('PRIMARY\n');print(primary %>% filter(region=='Asia',year%in%c(1990,2023)))
