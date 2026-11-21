suppressPackageStartupMessages({library(dplyr);library(tidyr);library(readr);library(ggplot2);library(patchwork);library(scales)})
out<-getOption('tbl.results_dir');d<-readRDS(file.path(out,'Data/prepared_inputs.rds'));s<-readRDS(file.path(out,'Data/supplementary_results.rds'))
reglevels<-c('Asia','East Asia','Southeast Asia','South Asia','Central Asia','High-income Asia Pacific','Middle East')
cols<-c('Asia'='#222222','East Asia'='#D55E00','Southeast Asia'='#009E73','South Asia'='#0072B2','Central Asia'='#CC79A7','High-income Asia Pacific'='#E69F00','Middle East'='#56B4E9')
theme_p<-theme_bw(base_size=10)+theme(panel.grid.minor=element_blank(),legend.position='bottom',legend.title=element_blank(),plot.title=element_text(face='bold'))
savefig<-function(p,name,w=12,h=7){for(ext in c('pdf','png','tiff')){args<-list(filename=file.path(out,'Figures',paste0(name,'.',ext)),plot=p,width=w,height=h,bg='white');if(ext!='pdf')args$dpi<-300;if(ext=='tiff')args$compression<-'lzw';do.call(ggsave,args)}}
if(file.exists(file.path(getOption('tbl.input_dir'),'map_and_location_archive.rds'))){
dep<-readRDS(file.path(getOption('tbl.input_dir'),'map_and_location_archive.rds'))
ct<-s$ct2023 %>% filter(epsilon==1,hale_convention=='HALE/2 primary')
write_csv(ct,file.path(out,'Data/Figure_2_country_valuation_2023.csv'))
mp<-dep$mapdf_2024_China %>% filter(location_id%in%c(d$locs$location_id,7,8,153,157)) %>% left_join(ct %>% select(location_id,VLW,VLW_GDP_pct),by='location_id')
mapplot<-function(v,breaks,title,legend){
 labs<-paste0(head(breaks,-1),'-',tail(breaks,-1));labs[length(labs)]<-paste0('>',breaks[length(breaks)-1])
 z<-mp %>% mutate(category=cut(v,breaks=breaks,labels=labs,include.lowest=TRUE,right=TRUE))
 ggplot(z)+geom_polygon(aes(long,lat,group=group,fill=category),colour='#555555',linewidth=.18,show.legend=TRUE)+coord_quickmap()+scale_fill_manual(values=c('#FFF7BC','#FEE391','#FEC44F','#FE9929','#EC7014','#CC4C02','#8C2D04'),na.value='#D9D9D9',drop=FALSE,name=legend)+labs(title=title,caption='Grey: no estimate in this analysis.')+theme_void(base_size=13)+theme(legend.position='right',legend.title=element_text(size=12),legend.text=element_text(size=12),plot.title=element_text(face='bold'),plot.caption=element_text(size=10,hjust=0))
}
ma<-mapplot(mp$VLW/1e9,c(0,.1,.5,1,5,10,50,Inf),'A  Absolute welfare valuation','VLW (billion,\nconstant 2023 Int$)')
mb<-mapplot(mp$VLW_GDP_pct,c(0,.2,.4,.6,.8,1,1.5,Inf),'B  Welfare valuation relative to GDP','VLW / GDP (%)')
savefig((ma/mb)+plot_annotation(caption='Country estimates follow the 45-country analytical cohort.\nBoundaries are taken from the archived plotting dataset.'),'Figure_2_revision_country_maps',11,11.2)
} else message('Archived map file not supplied: Figure 2 skipped; all numeric analyses continue.')
z<-s$primary %>% filter(year==2023,region!='Asia') %>% mutate(region=factor(region,levels=reglevels[-1]),share=VLW/sum(VLW)*100)
share<-ggplot(z,aes(region,share,fill=region))+geom_col(width=.7)+geom_text(aes(label=sprintf('%.1f%%',share)),hjust=-.1,size=3)+coord_flip()+scale_fill_manual(values=cols)+scale_y_continuous(expand=expansion(mult=c(0,.15)))+labs(x=NULL,y='Share of 2023 VLW (%)',title='A  Subregional distribution')+theme_p+theme(legend.position='none')
pc<-ggplot(s$primary,aes(year,VLW_per_capita,color=factor(region,levels=reglevels)))+geom_line(linewidth=.8)+scale_color_manual(values=cols)+labs(x='Year',y='Per-capita VLW (constant 2023 Int$)',title='B  Per-capita welfare valuation')+theme_p
savefig(share+pc+plot_annotation(caption='2023: all 45 countries. Historical valuation coverage rises from 43 to 45; see the fixed 43-country comparison.'),'Figure_S2_revision_distribution_percapita',13,6)
sx<-d$legacy %>% group_by(sex_name,year) %>% summarise(VLW_billion=sum(VLW)/1e9,GDP=sum(GDP),population=sum(population),.groups='drop') %>% mutate(VLW_GDP_pct=100*VLW_billion*1e9/GDP,per_capita=VLW_billion*1e9/population,sex_name=factor(sex_name,levels=c('Both','Male','Female')))
write_csv(sx,file.path(out,'Tables/sex_specific_valuation_1990_2023.csv'))
sc<-c('Both'='#222222','Male'='#0072B2','Female'='#D55E00')
ps1<-ggplot(sx,aes(year,VLW_billion,color=sex_name))+geom_line(linewidth=.85)+scale_color_manual(values=sc)+labs(x='Year',y='VLW (billion, constant 2023 Int$)',title='A  Welfare valuation by sex')+theme_p
ps2<-ggplot(sx,aes(year,VLW_GDP_pct,color=sex_name))+geom_line(linewidth=.85)+scale_color_manual(values=sc)+labs(x='Year',y='VLW / total GDP (%)',title='B  Valuation relative to total GDP')+theme_p
savefig(((ps1+ps2)+plot_layout(guides='collect')+plot_annotation(caption='HALE is matched by sex. Male and female valuations need not sum exactly to the independently calculated both-sex valuation.')) & theme(legend.position='bottom',plot.caption=element_text(size=8,hjust=0)),'Figure_S3_revision_sex_specific_valuation',13,6)
check<-sx %>% select(year,sex_name,VLW_billion) %>% pivot_wider(names_from=sex_name,values_from=VLW_billion) %>% mutate(sex_sum_relative_difference_pct=100*((Male+Female)/Both-1))
write_csv(check,file.path(out,'QA/sex_specific_HALE_aggregation_audit.csv'))
cat('Maps and economic supplementary figures saved.\n');print(sx %>% filter(year==2023));print(check %>% filter(year==2023))
