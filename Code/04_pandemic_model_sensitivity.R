suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2)})
out<-getOption('tbl.results_dir');f<-readRDS(file.path(out,'Data/forecast_results.rds'));s<-readRDS(file.path(out,'Data/supplementary_results.rds'))
# Pandemic-period comparisons use only models fit before 2020; outcomes remain descriptive.
h<-f$holdout %>% filter(origin==2019)
covid<-h %>% group_by(panel,region,model) %>% summarise(observed_2020_2023=sum(actual),expected_2020_2023=sum(predicted),deviation_pct=(sum(actual)/sum(predicted)-1)*100,.groups='drop')
sel<-h %>% inner_join(f$selected,by=c('panel','region')) %>% filter(model==selected_model) %>% mutate(model='CV-selected subregional models')
selasia<-sel %>% group_by(panel,year,model) %>% summarise(region='Asia',actual=sum(actual),predicted=sum(predicted),.groups='drop')
cs<-bind_rows(sel %>% select(panel,region,model,year,actual,predicted),selasia) %>% group_by(panel,region,model) %>% summarise(observed_2020_2023=sum(actual),expected_2020_2023=sum(predicted),deviation_pct=(sum(actual)/sum(predicted)-1)*100,.groups='drop')
covid<-bind_rows(covid,cs)
write_csv(covid,file.path(out,'Tables/Table_S14_pandemic_deviation_model_sensitivity.csv'))
cols<-c('Linear'='#56B4E9','Quadratic'='#009E73','Log-linear'='#D55E00','Damped ETS (log)'='#0072B2','CV-selected subregional models'='#111111')
keep<-names(cols);reglevels<-c('Asia','East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East')
theme_p<-theme_bw(base_size=11)+theme(panel.grid.minor=element_blank(),legend.position='bottom',legend.title=element_blank(),plot.title=element_text(face='bold'))
savefig<-function(p,name,w,h){for(ext in c('pdf','png','tiff')){args<-list(filename=file.path(out,'Figures',paste0(name,'.',ext)),plot=p,width=w,height=h,bg='white');if(ext!='pdf')args$dpi<-300;if(ext=='tiff')args$compression<-'lzw';do.call(ggsave,args)}}
z<-covid %>% filter(panel=='Available countries',model%in%keep) %>% mutate(region=factor(region,levels=rev(reglevels)))
p<-ggplot(z,aes(deviation_pct,region,color=model,shape=model))+geom_vline(xintercept=0,color='grey50',linetype=2)+geom_point(position=position_dodge(width=.6),size=2.4)+scale_color_manual(values=cols)+labs(x='Cumulative observed minus expected VLW, 2020-2023 (%)',y=NULL,title='Pandemic-period deviations depend on the counterfactual model',subtitle='All models use pre-2020 data; deviations do not establish a causal COVID-19 effect')+theme_p
savefig(p,'Figure_3_revision_descriptive_model_sensitivity',12,6)
# S1 shows fitted pre-pandemic regression trajectories and model extrapolations, avoiding mixed AIC scales.
paths<-list();k<-0
for(r in reglevels){
 z<-f$hist %>% filter(panel=='Available countries',region==r,year<=2019) %>% mutate(t=year-1990,y=value)
 for(m in c('Linear','Quadratic','Log-linear')){
  ff<-switch(m,Linear=y~t,Quadratic=y~t+I(t^2),`Log-linear`=log(y)~t);fit<-lm(ff,data=z)
  pp<-predict(fit,newdata=data.frame(t=(1990:2023)-1990));if(m=='Log-linear')pp<-exp(pp)
  k<-k+1;paths[[k]]<-data.frame(region=r,model=m,year=1990:2023,predicted=as.numeric(pp))
 }
}
paths<-bind_rows(paths)%>%mutate(region=factor(region,levels=reglevels));obs<-f$hist%>%filter(panel=='Available countries')%>%mutate(region=factor(region,levels=reglevels))
# The regional total is labelled as an independently fitted illustration here, not used for coherent scenario totals.
pp<-ggplot()+geom_line(data=paths,aes(year,predicted,color=model),linetype=2,linewidth=.65)+geom_line(data=obs,aes(year,value),color='black',linewidth=.7)+geom_point(data=obs%>%filter(year>=2020),aes(year,value),size=1,color='black')+geom_vline(xintercept=2019.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2)+scale_color_manual(values=cols)+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Candidate pre-pandemic trend specifications',subtitle='Illustrative in-sample fits and 2020-2023 extrapolations; use validation metrics for model assessment')+theme_p+theme(strip.background=element_blank(),strip.text=element_text(face='bold'))
savefig(pp,'Figure_S1_revision_candidate_trend_models',12,12)
cat('ASIA PANDEMIC DEVIATIONS\n');print(covid %>% filter(panel=='Available countries',region=='Asia'));cat('ALL DONE\n')
