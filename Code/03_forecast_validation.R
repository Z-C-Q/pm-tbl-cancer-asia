suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2);library(forecast);library(patchwork)})
out<-getOption('tbl.results_dir');d<-readRDS(file.path(out,'Data/prepared_inputs.rds'));s<-readRDS(file.path(out,'Data/supplementary_results.rds'))
regs<-c('East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East')
models<-c('Naive','Drift','Linear','Quadratic','Cubic','Log-linear','Damped ETS (log)')
hist<-s$regsens %>% filter(epsilon==1,hale_convention=='HALE/2 primary',region%in%c('Asia',regs)) %>% select(panel,region,year,value=VLW_billion)
# Each comparison model is fit on the same origin data. t is centered before powers.
project<-function(train,newyears,model){
 y<-train$value;tt<-train$year-min(train$year);newt<-newyears-min(train$year);h<-max(newyears)-max(train$year)
 z<-data.frame(y=y,t=tt)
 ans<-tryCatch({
 if(model=='Naive')return(rep(tail(y,1),length(newyears)))
 if(model=='Drift')return(tail(y,1)+(newyears-max(train$year))*(tail(y,1)-head(y,1))/(length(y)-1))
 if(model=='Damped ETS (log)'){
  fit<-ets(ts(log(y),frequency=1),model='AAN',damped=TRUE,restrict=TRUE)
  fc<-forecast(fit,h=h);return(exp(as.numeric(fc$mean)[newyears-max(train$year)]))
 }
 form<-switch(model,Linear=y~t,Quadratic=y~t+I(t^2),Cubic=y~t+I(t^2)+I(t^3),`Log-linear`=log(y)~t)
 fit<-lm(form,data=z);p<-as.numeric(predict(fit,newdata=data.frame(t=newt)))
 if(model=='Log-linear')p<-exp(p)
 p
 },error=function(e){warning(paste(model,conditionMessage(e)));rep(NA_real_,length(newyears))})
 ans
}
# Rolling validation: expanding origins 2004-2018; horizons 1,3,5,10; targets <=2019.
origins<-2004:2018;horizons<-c(1,3,5,10)
roll<-list();hold<-list();fut<-list();ii<-jj<-kk<-0
for(basis in unique(hist$panel)){
 cat('PRICE BASIS',basis,'\n')
 for(r in regs){
  z<-hist %>% filter(panel==basis,region==r) %>% arrange(year)
  for(m in models){
   for(o in origins){
    hs<-horizons[o+horizons<=2019];if(!length(hs))next
    train<-z %>% filter(year<=o);ny<-o+hs;pred<-project(train,ny,m)
    ii<-ii+1;roll[[ii]]<-data.frame(panel=basis,region=r,model=m,origin=o,horizon=hs,year=ny,predicted=pred,actual=z$value[match(ny,z$year)],scale=mean(abs(diff(train$value))))
   }
   for(o in c(2013,2019)){
    end<-ifelse(o==2013,2019,2023);ny<-(o+1):end;train<-z %>% filter(year<=o);pred<-project(train,ny,m)
    jj<-jj+1;hold[[jj]]<-data.frame(panel=basis,region=r,model=m,origin=o,year=ny,horizon=ny-o,predicted=pred,actual=z$value[match(ny,z$year)],scale=mean(abs(diff(train$value))))
   }
   pred<-project(z,2024:2050,m);kk<-kk+1;fut[[kk]]<-data.frame(panel=basis,region=r,model=m,year=2024:2050,predicted=pred)
  }
 }
}
roll<-bind_rows(roll);hold<-bind_rows(hold);fut<-bind_rows(fut)
# Aggregate Asia from the six subregional outputs; never fit an inconsistent independent total.
add_asia<-function(x,actual=TRUE){
 keys<-intersect(c('panel','model','origin','horizon','year'),names(x))
 if(actual){
  asia<-x %>% group_by(across(all_of(keys))) %>% summarise(region='Asia',predicted=if(all(is.finite(predicted)))sum(predicted) else NA_real_,actual=sum(actual),.groups='drop')
  scaling<-hist %>% filter(region=='Asia') %>% group_by(panel) %>% group_modify(~bind_rows(lapply(unique(x$origin),function(o)data.frame(origin=o,scale=mean(abs(diff(.x$value[.x$year<=o]))))))) %>% ungroup()
  asia<-asia %>% left_join(scaling,by=c('panel','origin'))
 }else asia<-x %>% group_by(across(all_of(keys))) %>% summarise(region='Asia',predicted=if(all(is.finite(predicted)))sum(predicted)else NA_real_,.groups='drop')
 bind_rows(x,asia)
}
roll<-add_asia(roll);hold<-add_asia(hold);fut<-add_asia(fut,FALSE)
metrics<-function(x){x %>% group_by(panel,region,model) %>% summarise(n_errors=n(),n_valid=sum(is.finite(predicted)),RMSE=sqrt(mean((predicted-actual)^2)),MAE=mean(abs(predicted-actual)),MAPE_pct=mean(abs(predicted-actual)/actual)*100,MASE=mean(abs(predicted-actual)/scale),bias=mean(predicted-actual),.groups='drop')}
rmet<-metrics(roll);hmet<-hold %>% group_by(origin) %>% group_modify(~metrics(.x)) %>% ungroup()
horizonmet<-roll %>% group_by(horizon) %>% group_modify(~metrics(.x)) %>% ungroup()
selected<-rmet %>% filter(region!='Asia',n_valid==n_errors) %>% group_by(panel,region) %>% slice_min(MASE,n=1,with_ties=FALSE) %>% ungroup() %>% select(panel,region,selected_model=model,rolling_MASE=MASE)
selproj<-fut %>% inner_join(selected,by=c('panel','region')) %>% filter(model==selected_model) %>% mutate(component_model=model,model='CV-selected subregional models') %>% select(-selected_model,-rolling_MASE)
asiasel<-selproj %>% group_by(panel,model,year) %>% summarise(region='Asia',predicted=sum(predicted),component_model='Sum of selected subregional central paths',.groups='drop')
fut<-bind_rows(fut,selproj %>% select(-component_model),asiasel %>% select(-component_model)) %>% mutate(negative_central_projection=predicted<0,HALF_if_VSLY_equals_VSL_over_HALE=predicted/2)
invalid_components<-fut %>% filter(region!='Asia') %>% group_by(panel,model,year) %>% summarise(any_negative_subregion=any(predicted<0),.groups='drop')
fut<-fut %>% left_join(invalid_components,by=c('panel','model','year')) %>% mutate(admissible_nonnegative_path=ifelse(region=='Asia',!any_negative_subregion,predicted>=0))
write_csv(roll,file.path(out,'Data/rolling_origin_predictions.csv'))
write_csv(hold,file.path(out,'Data/temporal_holdout_predictions.csv'))
write_csv(fut,file.path(out,'Data/scenario_projections_2024_2050.csv'))
write_csv(rmet,file.path(out,'Tables/Table_S8_rolling_validation_metrics.csv'))
write_csv(hmet,file.path(out,'Tables/Table_S9_temporal_holdout_metrics.csv'))
write_csv(horizonmet,file.path(out,'Tables/Table_S10_validation_by_horizon.csv'))
write_csv(selected,file.path(out,'Tables/Table_S11_model_selection.csv'))
write_csv(fut %>% filter(year%in%c(2024,2030,2040,2050)),file.path(out,'Tables/Table_S12_projection_scenarios.csv'))
# Stable AIC comparison for pandemic models includes the log-transform Jacobian.
caic<-list();ci<-0
for(r in c('Asia',regs)){
 z<-hist %>% filter(panel=='Available countries',region==r,year<=2019) %>% arrange(year) %>% mutate(t=year-1990,y=value)
 for(m in c('Linear','Quadratic','Cubic','Log-linear')){
  ff<-switch(m,Linear=y~t,Quadratic=y~t+I(t^2),Cubic=y~t+I(t^2)+I(t^3),`Log-linear`=log(y)~t)
  f<-lm(ff,z);pr<-if(m=='Log-linear')exp(predict(f))else predict(f);ci<-ci+1
  caic[[ci]]<-data.frame(region=r,model=m,AIC_response_scale=AIC(f)+ifelse(m=='Log-linear',2*sum(log(z$y)),0),RMSE_response_scale=sqrt(mean((pr-z$y)^2)),model_rank=f$rank,n_parameters=length(coef(f)))
 }
}
write_csv(bind_rows(caic),file.path(out,'Tables/Table_S1_candidate_model_metrics_corrected_AIC.csv'))
# Exploratory scenario paths: no unsupported 95% band and no claim of 27-year validation.
theme_p<-theme_bw(base_size=10)+theme(panel.grid.minor=element_blank(),legend.position='bottom',legend.title=element_blank(),strip.background=element_blank(),strip.text=element_text(face='bold'))
savefig<-function(p,name,w=12,h=12){for(ext in c('pdf','png','tiff')){args<-list(filename=file.path(out,'Figures',paste0(name,'.',ext)),plot=p,width=w,height=h,bg='white');if(ext!='pdf')args$dpi<-300;if(ext=='tiff')args$compression<-'lzw';do.call(ggsave,args)}}
fcols<-c('Naive'='#999999','Drift'='#E69F00','Linear'='#56B4E9','Quadratic'='#009E73','Cubic'='#CC79A7','Log-linear'='#D55E00','Damped ETS (log)'='#0072B2','CV-selected subregional models'='#111111','Original v3 (trained through 2019)'='#777777')
fp<-fut %>% filter(panel=='Available countries',model!='Original v3 (trained through 2019)') %>% mutate(predicted=ifelse(admissible_nonnegative_path,predicted,NA_real_),region=factor(region,levels=c('Asia',regs)))
hp<-hist %>% filter(panel=='Available countries') %>% mutate(region=factor(region,levels=c('Asia',regs)))
p<-ggplot()+geom_line(data=hp,aes(year,value),color='#222222',linewidth=.65)+geom_line(data=fp,aes(year,predicted,color=model,linewidth=model=='CV-selected subregional models'),na.rm=TRUE)+scale_color_manual(values=fcols)+scale_linewidth_manual(values=c('TRUE'=1,'FALSE'=.55),guide='none')+geom_vline(xintercept=2023.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2)+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Exploratory projections under alternative specifications',subtitle='Observed through 2023; projections from 2024; invalid negative paths omitted; no 95% interval claimed')+theme_p
savefig(p,'Figure_S5_revision_exploratory_model_scenarios',12,13)
# Present original-model vs alternative forecasts in 2020-2023 holdout.
hp2<-hold %>% filter(panel=='Available countries',origin==2019,model%in%c('Linear','Quadratic','Log-linear','Damped ETS (log)')) %>% mutate(region=factor(region,levels=c('Asia',regs)))
obs<-hist %>% filter(panel=='Available countries',year>=2008) %>% mutate(region=factor(region,levels=c('Asia',regs)))
ph<-ggplot()+geom_line(data=obs,aes(year,value),color='black',linewidth=.7)+geom_point(data=obs %>% filter(year>=2020),aes(year,value),color='black',size=1)+geom_line(data=hp2,aes(year,predicted,color=model),linetype=2)+geom_vline(xintercept=2019.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2)+scale_color_manual(values=fcols)+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Temporal holdout during 2020-2023',subtitle='All candidate models trained on 1990-2019 only')+theme_p
savefig(ph,'Figure_S9_temporal_holdout_validation',12,12)
heat<-rmet %>% filter(panel=='Available countries') %>% mutate(region=factor(region,levels=rev(c('Asia',regs))),model=factor(model,levels=models))
pm<-ggplot(heat,aes(model,region,fill=log10(MASE)))+geom_tile(color='white')+geom_text(aes(label=sprintf('%.2f',MASE)),size=3)+scale_fill_gradient(low='#FFF7BC',high='#D7301F',name='log10(MASE)')+labs(x=NULL,y=NULL,title='Rolling-origin forecast accuracy',subtitle='MASE values shown; origins 2004-2018; horizons 1, 3, 5 and 10 years; targets through 2019')+theme_p+theme(axis.text.x=element_text(angle=25,hjust=1),legend.position='right')
savefig(pm,'Figure_S10_rolling_validation_accuracy',12,5.5)
# Model choice sensitivity to the country panel.
price2050<-fut %>% filter(region=='Asia',year==2050,model!='Original v3 (trained through 2019)')
write_csv(price2050,file.path(out,'Tables/Table_S13_2050_country_panel_sensitivity.csv'))
saveRDS(list(hist=hist,rolling=roll,holdout=hold,rolling_metrics=rmet,holdout_metrics=hmet,selected=selected,projections=fut),file.path(out,'Data/forecast_results.rds'))
cat('SELECTED\n');print(selected);cat('ASIA ROLLING\n');print(rmet %>% filter(panel=='Available countries',region=='Asia'));cat('ASIA 2050\n');print(fut %>% filter(region=='Asia',year==2050));cat('ALL DONE\n')
