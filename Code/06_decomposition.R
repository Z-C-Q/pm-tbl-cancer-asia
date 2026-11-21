suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2)})
out<-getOption('tbl.results_dir');d<-readRDS(file.path(out,'Data/prepared_inputs.rds'))
z<-d$raw %>% filter(year%in%c(1990,2023),metric_name=='Number',age_id%in%d$w1$age_id) %>% select(location_id,location_name,region_6,year,age_id,DALYs=val) %>% left_join(d$pop %>% select(location_id,year,age_id,population),by=c('location_id','year','age_id'))
stopifnot(!anyNA(z$population),all(z$population>0))
pooled<-bind_rows(z %>% group_by(location_name=region_6,year,age_id) %>% summarise(DALYs=sum(DALYs),population=sum(population),.groups='drop'),z %>% group_by(year,age_id) %>% summarise(location_name='Asia',DALYs=sum(DALYs),population=sum(population),.groups='drop')) %>% mutate(level='Region')
all<-bind_rows(z %>% select(location_name,year,age_id,DALYs,population) %>% mutate(level='Country'),pooled)
# Average each factor's incremental effect over all six replacement orders (three-factor Shapley decomposition).
permutations<-list(c('P','A','R'),c('P','R','A'),c('A','P','R'),c('A','R','P'),c('R','P','A'),c('R','A','P'))
calculate<-function(x){
 a<-x %>% filter(year==1990) %>% arrange(age_id);b<-x %>% filter(year==2023) %>% arrange(age_id)
 stopifnot(identical(a$age_id,b$age_id),nrow(a)==15)
 f0<-list(P=sum(a$population),A=a$population/sum(a$population),R=a$DALYs/a$population)
 f1<-list(P=sum(b$population),A=b$population/sum(b$population),R=b$DALYs/b$population)
 value<-function(v)sum(v$P*v$A*v$R)
 effects<-c(P=0,A=0,R=0)
 for(order in permutations){state<-f0;v0<-value(state);for(k in order){state[[k]]<-f1[[k]];v1<-value(state);effects[k]<-effects[k]+(v1-v0)/6;v0<-v1}}
 delta<-sum(b$DALYs)-sum(a$DALYs)
 stopifnot(abs(sum(effects)-delta)<1e-6)
 data.frame(DALYs_1990=sum(a$DALYs),DALYs_2023=sum(b$DALYs),Overall_Difference=delta,Aging=effects['A'],Population=effects['P'],Epidemiological_Change=effects['R'],Aging_Percentage=effects['A']/delta*100,Population_Percentage=effects['P']/delta*100,Epidemiological_Change_Percentage=effects['R']/delta*100)
}
res<-all %>% group_by(level,location_name) %>% group_modify(~calculate(.x)) %>% ungroup()
write_csv(res,file.path(out,'Tables/Table_S2_decomposition_45countries.csv'))
write_csv(all,file.path(out,'Data/decomposition_age_specific_counts_population.csv'))
saveRDS(res,file.path(out,'Data/decomposition_results.rds'))
plotdata<-res %>% pivot_longer(c(Aging,Population,Epidemiological_Change),names_to='Effect',values_to='Value') %>% mutate(Effect=factor(Effect,levels=c('Population','Aging','Epidemiological_Change'),labels=c('Population aged 25+','Age composition within 25+','Age-specific DALY-rate change')))
colors<-c('Population aged 25+'='#E69F00','Age composition within 25+'='#56B4E9','Age-specific DALY-rate change'='#009E73')
savefig<-function(p,name,w,h){for(ext in c('pdf','png','tiff')){args<-list(filename=file.path(out,'Figures',paste0(name,'.',ext)),plot=p,width=w,height=h,bg='white');if(ext!='pdf')args$dpi<-300;if(ext=='tiff')args$compression<-'lzw';do.call(ggsave,args)}}
makeplot<-function(level,title){
 rr<-res %>% filter(.data$level==.env$level) %>% arrange(Overall_Difference)
 if(level=='Region')rr<-rr %>% mutate(location_name=factor(location_name,levels=rev(c('Asia','East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East'))))
 else rr<-rr %>% mutate(location_name=factor(location_name,levels=location_name))
 zz<-plotdata %>% filter(.data$level==.env$level) %>% mutate(location_name=factor(location_name,levels=levels(rr$location_name)))
 stopifnot(nrow(rr)==ifelse(level=='Region',7,45))
 ggplot(zz,aes(location_name,Value/1e3,fill=Effect))+geom_col()+geom_point(data=rr,aes(location_name,Overall_Difference/1e3),inherit.aes=FALSE,color='black',size=1.7)+coord_flip()+scale_fill_manual(values=colors)+labs(x=NULL,y='Change in DALYs, 1990-2023 (thousand)',title=title,caption='Black dots: net change. Rate change is a descriptive decomposition component, not a pollution-specific causal effect.')+theme_bw(base_size=10)+theme(legend.position='bottom',legend.title=element_blank(),panel.grid.minor=element_blank(),plot.caption=element_text(size=8,hjust=0),axis.text.y=element_text(size=ifelse(level=='Country',8,10)))
}
savefig(makeplot('Region','Decomposition of DALY change in the 45-country cohort'),'Figure_4_revision_decomposition',12,6.5)
savefig(makeplot('Country','Country-specific decomposition of DALY change'),'Figure_S4_revision_country_decomposition',10,14)
print(res %>% filter(level=='Region'))
