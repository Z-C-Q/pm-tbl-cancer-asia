# Run from the project root. Reuse frozen results; write only to this new folder.
suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2);library(patchwork);library(scales)})
src <- getOption('tbl.results_dir')
out <- file.path(src,'PublicationFigures')
for (p in c('Main','Supplementary','PNG/Main','PNG/Supplementary','PDF/Main','PDF/Supplementary','Verification')) dir.create(file.path(out,p),recursive=TRUE,showWarnings=FALSE)
d <- readRDS(file.path(src,'Data/prepared_inputs.rds'))
s <- readRDS(file.path(src,'Data/supplementary_results.rds'))
f <- readRDS(file.path(src,'Data/forecast_results.rds'))
dep <- readRDS(file.path(getOption('tbl.input_dir'),'map_and_location_archive.rds'))
res <- readRDS(file.path(src,'Data/decomposition_results.rds'))
input_files <- list.files(file.path(src,'Data'),full.names=TRUE)
input_md5 <- tools::md5sum(input_files)
reglevels <- c('Asia','East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East')
regs <- reglevels[-1]
cols <- c('Asia'='#222222','East Asia'='#D55E00','Southeast Asia'='#009E73','South Asia'='#0072B2','Central Asia'='#CC79A7','High-income Asia Pacific'='#E69F00','Middle East'='#56B4E9')
fcols <- c('Naive'='#999999','Drift'='#E69F00','Linear'='#56B4E9','Quadratic'='#009E73','Cubic'='#CC79A7','Log-linear'='#D55E00','Damped ETS (log)'='#0072B2','CV-selected subregional models'='#111111','Original v3 (trained through 2019)'='#777777')
models <- c('Naive','Drift','Linear','Quadratic','Cubic','Log-linear','Damped ETS (log)')
wrap <- function(x,width) vapply(x,function(z) paste(strwrap(z,width=width),collapse='\n'),character(1))
region_labels <- function(x) ifelse(x=='High-income Asia Pacific','High-income\nAsia Pacific',x)
model_labels <- function(x) ifelse(x=='CV-selected subregional models','CV-selected subregional\nmodels',x)

# Point sizes; every textual element uses an actual bold font face.
theme_large <- theme_bw(base_size=14,base_family='sans') + theme(
 text=element_text(family='sans',face='bold',colour='black'),
 axis.title=element_text(size=14,face='bold'),
 axis.text=element_text(size=12.5,face='bold',colour='black'),
 axis.title.x=element_text(margin=margin(t=9)),axis.title.y=element_text(margin=margin(r=9)),
 plot.title=element_text(size=18,face='bold',lineheight=1.08,margin=margin(b=9)),
 plot.subtitle=element_text(size=12.5,face='bold',lineheight=1.12,margin=margin(b=10)),
 plot.caption=element_text(size=11,face='bold',hjust=0,lineheight=1.12,margin=margin(t=10)),
 strip.background=element_blank(),strip.text=element_text(size=13.5,face='bold',margin=margin(t=5,b=7)),
 legend.position='bottom',legend.title=element_blank(),
 legend.text=element_text(size=12.5,face='bold',lineheight=1.05),
 legend.key.width=grid::unit(23,'pt'),legend.key.height=grid::unit(19,'pt'),
 legend.spacing.x=grid::unit(5,'pt'),legend.margin=margin(t=5,b=3),
 panel.grid.minor=element_blank(),panel.spacing=grid::unit(15,'pt'),
 plot.margin=margin(t=13,r=17,b=13,l=13))
cap_theme <- theme(plot.caption=element_text(size=11,face='bold',hjust=0,lineheight=1.12,margin=margin(t=10)),plot.margin=margin(13,17,13,13))
legend_regions <- guides(colour=guide_legend(nrow=2,byrow=TRUE))
manifest <- list()
savefig <- function(p,id,w,h,source_name) {
 sub <- if(grepl('^Figure_S',id)) 'Supplementary' else 'Main'
 paths <- c(pdf=file.path(out,'PDF',sub,paste0(id,'.pdf')),png=file.path(out,'PNG',sub,paste0(id,'.png')),tiff=file.path(out,sub,paste0(id,'.tiff')))
 ggsave(paths[['pdf']],p,width=w,height=h,device=grDevices::cairo_pdf,bg='white',limitsize=FALSE)
 ggsave(paths[['png']],p,width=w,height=h,dpi=300,device=ragg::agg_png,bg='white',limitsize=FALSE)
 ggsave(paths[['tiff']],p,width=w,height=h,dpi=300,device=ragg::agg_tiff,compression='lzw',bg='white',limitsize=FALSE)
 manifest[[length(manifest)+1]] <<- data.frame(figure=id,source_figure=source_name,width_in=w,height_in=h,dpi=300,base_font_pt=14,axis_text_pt=12.5,font_face='bold',TIFF=paths[['tiff']],PNG=paths[['png']],PDF=paths[['pdf']])
 cat('SAVED',id,'\n')
}

# Figure 1: use the previously validated health and valuation result objects.
primary <- s$primary
epi <- s$epi
pa <- ggplot(primary,aes(year,VLW_billion,color=factor(region,levels=reglevels)))+geom_line(linewidth=.85)+scale_color_manual(values=cols,labels=region_labels)+labs(title='A  Monetized welfare loss',x='Year',y='VLW (billion, constant 2023 Int$)')+theme_large+legend_regions
pb <- ggplot(primary,aes(year,VLW_GDP_pct,color=factor(region,levels=reglevels)))+geom_line(linewidth=.85)+scale_color_manual(values=cols,labels=region_labels)+labs(title='B  Welfare loss relative to GDP',x='Year',y='VLW / GDP (%)')+theme_large+legend_regions
pc <- ggplot(epi,aes(year,DALYs/1e6,color=region))+geom_line(linewidth=.85)+scale_color_manual(values=cols,labels=region_labels)+labs(title='C  Epidemiological burden',x='Year',y='DALYs (million)')+theme_large+legend_regions
pd <- ggplot(epi,aes(year,ASDR,color=region))+geom_line(linewidth=.85)+scale_color_manual(values=cols,labels=region_labels)+labs(title='D  Age-standardized DALY rate',x='Year',y='DALYs per 100,000 population')+theme_large+legend_regions
p1 <- (((pa+pb)/(pc+pd))+plot_layout(guides='collect')+plot_annotation(caption='A-B: 43 countries in 1990, 44 from 1994, 45 from 2000. C-D: the same 45-country health cohort throughout.\nFixed-country comparisons are provided separately.',theme=cap_theme)) & theme(legend.position='bottom')
savefig(p1,'Figure_1',13,11.8,'Figure_1_revision_health_and_welfare')

# Figure 2: same polygon archive, category cuts and cohort as the submitted figure.
ct <- s$ct2023 %>% filter(epsilon==1,hale_convention=='HALE/2 primary')
mp <- dep$mapdf_2024_China %>% filter(location_id%in%c(d$locs$location_id,7,8,153,157)) %>% left_join(ct %>% select(location_id,VLW,VLW_GDP_pct),by='location_id')
mapplot <- function(v,breaks,title,legend) {
 labs <- paste0(head(breaks,-1),'-',tail(breaks,-1));labs[length(labs)] <- paste0('>',breaks[length(breaks)-1])
 z <- mp %>% mutate(category=cut(v,breaks=breaks,labels=labs,include.lowest=TRUE,right=TRUE))
 ggplot(z)+geom_polygon(aes(long,lat,group=group,fill=category),colour='#555555',linewidth=.18,show.legend=TRUE)+coord_quickmap()+scale_fill_manual(values=c('#FFF7BC','#FEE391','#FEC44F','#FE9929','#EC7014','#CC4C02','#8C2D04'),na.value='#D9D9D9',drop=FALSE,name=legend)+labs(title=title,caption='Grey: no estimate in this analysis.')+theme_void(base_size=15,base_family='sans')+theme(text=element_text(family='sans',face='bold',colour='black'),legend.position='right',legend.title=element_text(size=15,face='bold',lineheight=1.1),legend.text=element_text(size=15,face='bold'),legend.key.height=grid::unit(21,'pt'),legend.key.width=grid::unit(21,'pt'),plot.title=element_text(size=18,face='bold',margin=margin(b=7)),plot.caption=element_text(size=12,face='bold',hjust=0,margin=margin(t=7)),plot.margin=margin(12,15,10,12))
}
ma <- mapplot(mp$VLW/1e9,c(0,.1,.5,1,5,10,50,Inf),'A  Absolute welfare valuation','VLW (billion,\nconstant 2023 Int$)')
mb <- mapplot(mp$VLW_GDP_pct,c(0,.2,.4,.6,.8,1,1.5,Inf),'B  Welfare valuation relative to GDP','VLW / GDP (%)')
savefig((ma/mb)+plot_annotation(caption='Country estimates follow the 45-country analytical cohort.\nBoundaries are taken from the archived plotting dataset.',theme=cap_theme),'Figure_2',11,11.2,'Figure_2_revision_country_maps')

# Figure 3: read the frozen model sensitivity table rather than rerun forecasting.
ccols <- c('Linear'='#56B4E9','Quadratic'='#009E73','Log-linear'='#D55E00','Damped ETS (log)'='#0072B2','CV-selected subregional models'='#111111')
covid <- read_csv(file.path(src,'Tables/Table_S14_pandemic_deviation_model_sensitivity.csv'),show_col_types=FALSE)
z <- covid %>% filter(panel=='Available countries',model%in%names(ccols)) %>% mutate(region=factor(region,levels=rev(reglevels)))
p3 <- ggplot(z,aes(deviation_pct,region,color=model,shape=model))+geom_vline(xintercept=0,color='grey50',linetype=2)+geom_point(position=position_dodge(width=.6),size=2.4)+scale_color_manual(values=ccols,labels=model_labels)+scale_shape_discrete(labels=model_labels)+scale_y_discrete(labels=region_labels)+labs(x='Cumulative observed minus expected VLW, 2020-2023 (%)',y=NULL,title='Pandemic-period deviations depend on the counterfactual model',subtitle='All models use pre-2020 data; deviations do not establish a causal COVID-19 effect')+theme_large+guides(colour=guide_legend(nrow=2,byrow=TRUE),shape=guide_legend(nrow=2,byrow=TRUE))
savefig(p3,'Figure_3',12.5,6.8,'Figure_3_revision_descriptive_model_sensitivity')

# Figure 4 and S4: keep the frozen decomposition effects and ordering.
plotdata <- res %>% pivot_longer(c(Aging,Population,Epidemiological_Change),names_to='Effect',values_to='Value') %>% mutate(Effect=factor(Effect,levels=c('Population','Aging','Epidemiological_Change'),labels=c('Population aged 25+','Age composition within 25+','Age-specific DALY-rate change')))
colors <- c('Population aged 25+'='#E69F00','Age composition within 25+'='#56B4E9','Age-specific DALY-rate change'='#009E73')
makeplot <- function(level,title) {
 rr <- res %>% filter(.data$level==.env$level) %>% arrange(Overall_Difference)
 if(level=='Region') rr <- rr %>% mutate(location_name=factor(location_name,levels=rev(reglevels))) else rr <- rr %>% mutate(location_name=factor(location_name,levels=location_name))
 zz <- plotdata %>% filter(.data$level==.env$level) %>% mutate(location_name=factor(location_name,levels=levels(rr$location_name)))
 ggplot(zz,aes(location_name,Value/1e3,fill=Effect))+geom_col()+geom_point(data=rr,aes(location_name,Overall_Difference/1e3),inherit.aes=FALSE,color='black',size=1.7)+coord_flip()+scale_fill_manual(values=colors,labels=function(x) wrap(x,26))+scale_x_discrete(labels=if(level=='Region') region_labels else identity)+labs(x=NULL,y='Change in DALYs, 1990-2023 (thousand)',title=title,caption='Black dots: net change. Rate change is a descriptive decomposition component,\nnot a pollution-specific causal effect.')+theme_large+theme(axis.text.y=element_text(size=ifelse(level=='Country',11.5,12.5),face='bold'))+guides(fill=guide_legend(nrow=1))
}
savefig(makeplot('Region','Decomposition of DALY change in the 45-country cohort'),'Figure_4',12,7,'Figure_4_revision_decomposition')
savefig(makeplot('Country','Country-specific decomposition of DALY change'),'Figure_S4',11,14,'Figure_S4_revision_country_decomposition')

# S1: identical illustrative regressions on the frozen pre-2020 historical series.
paths <- list();k <- 0
for(r in reglevels) {
 z <- f$hist %>% filter(panel=='Available countries',region==r,year<=2019) %>% mutate(t=year-1990,y=value)
 for(m in c('Linear','Quadratic','Log-linear')) {
  ff <- switch(m,Linear=y~t,Quadratic=y~t+I(t^2),`Log-linear`=log(y)~t);fit <- lm(ff,data=z)
  pp <- predict(fit,newdata=data.frame(t=(1990:2023)-1990));if(m=='Log-linear') pp <- exp(pp)
  k <- k+1;paths[[k]] <- data.frame(region=r,model=m,year=1990:2023,predicted=as.numeric(pp))
 }
}
paths <- bind_rows(paths) %>% mutate(region=factor(region,levels=reglevels))
obs <- f$hist %>% filter(panel=='Available countries') %>% mutate(region=factor(region,levels=reglevels))
ps1 <- ggplot()+geom_line(data=paths,aes(year,predicted,color=model),linetype=2,linewidth=.65)+geom_line(data=obs,aes(year,value),color='black',linewidth=.7)+geom_point(data=obs%>%filter(year>=2020),aes(year,value),size=1,color='black')+geom_vline(xintercept=2019.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2,labeller=labeller(region=region_labels))+scale_color_manual(values=ccols)+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Candidate pre-pandemic trend specifications',subtitle='Illustrative in-sample fits and 2020-2023 extrapolations;\nuse validation metrics for model assessment')+theme_large
savefig(ps1,'Figure_S1',12,12.5,'Figure_S1_revision_candidate_trend_models')

# S2 and S3: frozen economic values, with more space for long labels.
z <- primary %>% filter(year==2023,region!='Asia') %>% mutate(region=factor(region,levels=regs),share=VLW/sum(VLW)*100)
share <- ggplot(z,aes(region,share,fill=region))+geom_col(width=.7)+geom_text(aes(label=sprintf('%.1f%%',share)),hjust=-.1,size=4.2,family='sans',fontface='bold')+coord_flip()+scale_fill_manual(values=cols)+scale_x_discrete(labels=region_labels)+scale_y_continuous(expand=expansion(mult=c(0,.18)))+labs(x=NULL,y='Share of 2023 VLW (%)',title='A  Subregional distribution')+theme_large+theme(legend.position='none')
ppc <- ggplot(primary,aes(year,VLW_per_capita,color=factor(region,levels=reglevels)))+geom_line(linewidth=.8)+scale_color_manual(values=cols,labels=region_labels)+labs(x='Year',y='Per-capita VLW (constant 2023 Int$)',title='B  Per-capita welfare valuation')+theme_large+guides(colour=guide_legend(ncol=2,byrow=TRUE))
savefig((share+ppc)+plot_annotation(caption='2023: all 45 countries. Historical valuation coverage rises from 43 to 45;\nsee the fixed 43-country comparison.',theme=cap_theme),'Figure_S2',13.5,7,'Figure_S2_revision_distribution_percapita')
sx <- read_csv(file.path(src,'Tables/sex_specific_valuation_1990_2023.csv'),show_col_types=FALSE) %>% mutate(sex_name=factor(sex_name,levels=c('Both','Male','Female')))
sc <- c('Both'='#222222','Male'='#0072B2','Female'='#D55E00')
psx1 <- ggplot(sx,aes(year,VLW_billion,color=sex_name))+geom_line(linewidth=.85)+scale_color_manual(values=sc)+labs(x='Year',y='VLW (billion, constant 2023 Int$)',title='A  Welfare valuation by sex')+theme_large
psx2 <- ggplot(sx,aes(year,VLW_GDP_pct,color=sex_name))+geom_line(linewidth=.85)+scale_color_manual(values=sc)+labs(x='Year',y='VLW / total GDP (%)',title='B  Valuation relative to total GDP')+theme_large
savefig(((psx1+psx2)+plot_layout(guides='collect')+plot_annotation(caption='HALE is matched by sex. Male and female valuations need not sum exactly\nto the independently calculated both-sex valuation.',theme=cap_theme)) & theme(legend.position='bottom'),'Figure_S3',13,6.5,'Figure_S3_revision_sex_specific_valuation')

# S5 and S9: use saved forecast paths without refitting the forecast models.
fp <- f$projections %>% filter(panel=='Available countries',model!='Original v3 (trained through 2019)') %>% mutate(predicted=ifelse(admissible_nonnegative_path,predicted,NA_real_),region=factor(region,levels=reglevels))
hp <- f$hist %>% filter(panel=='Available countries') %>% mutate(region=factor(region,levels=reglevels))
pf <- ggplot()+geom_line(data=hp,aes(year,value),color='#222222',linewidth=.65)+geom_line(data=fp,aes(year,predicted,color=model,linewidth=model=='CV-selected subregional models'),na.rm=TRUE)+scale_color_manual(values=fcols,labels=model_labels)+scale_linewidth_manual(values=c('TRUE'=1,'FALSE'=.55),guide='none')+geom_vline(xintercept=2023.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2,labeller=labeller(region=region_labels))+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Exploratory projections under alternative specifications',subtitle='Observed through 2023; projections from 2024; invalid negative paths omitted;\nno 95% interval claimed')+theme_large+guides(colour=guide_legend(ncol=3,byrow=TRUE))
savefig(pf,'Figure_S5',12,13.5,'Figure_S5_revision_exploratory_model_scenarios')
hp2 <- f$holdout %>% filter(panel=='Available countries',origin==2019,model%in%c('Linear','Quadratic','Log-linear','Damped ETS (log)')) %>% mutate(region=factor(region,levels=reglevels))
obs2 <- hp %>% filter(year>=2008)
ph <- ggplot()+geom_line(data=obs2,aes(year,value),color='black',linewidth=.7)+geom_point(data=obs2 %>% filter(year>=2020),aes(year,value),color='black',size=1)+geom_line(data=hp2,aes(year,predicted,color=model),linetype=2)+geom_vline(xintercept=2019.5,linetype=3,color='grey50')+facet_wrap(~region,scales='free_y',ncol=2,labeller=labeller(region=region_labels))+scale_color_manual(values=fcols)+labs(x='Year',y='VLW (billion; constant 2023 Int$)',title='Temporal holdout during 2020-2023',subtitle='All candidate models trained on 1990-2019 only')+theme_large+guides(colour=guide_legend(nrow=1))
savefig(ph,'Figure_S9',12,12.5,'Figure_S9_temporal_holdout_validation')

# S6 and S7: keep all original values and groupings.
pindex <- ggplot(s$index,aes(year,index,color=series,linetype=series))+geom_line(linewidth=1)+scale_color_manual(values=c('#222222','#D55E00','#0072B2'))+labs(x='Year',y='Index (1990 = 100)',title='Health loss and monetary valuation',subtitle='Fixed 43-country panel; holding 1990 VSLY constant\nis a descriptive valuation comparison')+theme_large+guides(colour=guide_legend(nrow=2,byrow=TRUE),linetype=guide_legend(nrow=2,byrow=TRUE))
savefig(pindex,'Figure_S6',11,6.5,'Figure_S6_health_vs_valuation_index')
plotreg <- s$reg2023 %>% filter(panel=='Available countries',hale_convention=='HALE/2 primary',region!='Asia') %>% mutate(region=factor(region,levels=regs),epsilon=factor(epsilon))
pe1 <- ggplot(plotreg,aes(epsilon,VLW_billion,group=region,color=region))+geom_line()+geom_point(size=2)+scale_color_manual(values=cols,labels=region_labels)+scale_y_log10()+labs(x='Income elasticity',y='VLW (billion, constant 2023 Int$)',title='A  Subregional welfare valuation')+theme_large+legend_regions
pe2 <- ggplot(plotreg,aes(epsilon,VLW_GDP_pct,group=region,color=region))+geom_line()+geom_point(size=2)+scale_color_manual(values=cols,labels=region_labels)+labs(x='Income elasticity',y='VLW / GDP (%)',title='B  Relative welfare valuation')+theme_large+legend_regions
savefig(((pe1+pe2)+plot_layout(guides='collect')) & theme(legend.position='bottom'),'Figure_S7',13,6.3,'Figure_S7_elasticity_sensitivity')

# S8: allow 45 bold country names and bold in-cell rank labels.
prank <- s$ct2023 %>% filter(hale_convention=='HALE/2 primary') %>% mutate(epsilon=factor(epsilon),location_name=factor(location_name,levels=s$ct2023 %>% filter(hale_convention=='HALE/2 primary',epsilon==1) %>% arrange(desc(VLW_rank)) %>% pull(location_name)))
pr <- ggplot(prank,aes(epsilon,location_name,fill=VLW_rank))+geom_tile(color='white')+geom_text(aes(label=VLW_rank),size=3.7,fontface='bold',family='sans')+scale_fill_gradient(low='#FFFFD9',high='#225EA8',name='VLW rank')+labs(x='Income elasticity',y=NULL,title='Country ranking under alternative\nincome elasticities',subtitle='45 countries in 2023; primary HALE/2 convention')+theme_large+theme(legend.position='right',axis.text.y=element_text(size=11.5,face='bold'))
savefig(pr,'Figure_S8',8.5,13,'Figure_S8_country_rank_sensitivity')

# S10: bold cell values; long region and model names get deliberate line breaks.
heat <- f$rolling_metrics %>% filter(panel=='Available countries') %>% mutate(region=factor(region,levels=rev(reglevels)),model=factor(model,levels=models))
pm <- ggplot(heat,aes(model,region,fill=log10(MASE)))+geom_tile(color='white')+geom_text(aes(label=sprintf('%.2f',MASE)),size=4.2,fontface='bold',family='sans')+scale_fill_gradient(low='#FFF7BC',high='#D7301F',name='log10(MASE)')+scale_y_discrete(labels=region_labels)+scale_x_discrete(labels=function(x) ifelse(x=='Damped ETS (log)','Damped ETS\n(log)',x))+labs(x=NULL,y=NULL,title='Rolling-origin forecast accuracy',subtitle='MASE values shown; origins 2004-2018; horizons 1, 3, 5 and 10 years;\ntargets through 2019')+theme_large+theme(axis.text.x=element_text(angle=25,hjust=1,size=12.5,face='bold'),legend.position='right')
savefig(pm,'Figure_S10',12.5,6.2,'Figure_S10_rolling_validation_accuracy')

# Verify that source data and all 14 original TIFF files were untouched.
stopifnot(identical(input_md5,tools::md5sum(input_files)),length(manifest)==14,nrow(ct)==45,n_distinct(prank$location_id)==45,nrow(heat)==49)
write_csv(bind_rows(manifest),file.path(out,'figure_manifest.csv'))
write_csv(data.frame(path=names(input_md5),md5=unname(input_md5),unchanged=TRUE),file.path(out,'Verification/input_integrity.csv'))
cat('ALL 14 FIGURES SAVED; ORIGINALS AND INPUTS UNCHANGED\n')
