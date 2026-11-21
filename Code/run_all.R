#!/usr/bin/env Rscript
# Resolves all paths from this file; works from any current working directory.
argv <- commandArgs(trailingOnly=FALSE)
options(warn=1)
script_arg <- grep('^--file=',argv,value=TRUE)
if(!length(script_arg)) stop('Run with Rscript Code/run_all.R')
repo <- dirname(dirname(normalizePath(sub('^--file=','',script_arg[1]),mustWork=TRUE)))
args <- commandArgs(trailingOnly=TRUE)
value <- function(flag,default) {
 i <- match(flag,args)
 if(is.na(i)) return(default)
 if(i==length(args)) stop('Missing value for ',flag)
 normalizePath(args[i+1],mustWork=FALSE)
}
inputs <- value('--input-dir',file.path(repo,'Data/Inputs'))
results <- value('--output-dir',file.path(repo,'Results'))
has <- function(flag) flag%in%args
packages <- c('dplyr','tidyr','readr','jsonlite','ggplot2','patchwork','scales','forecast')
if(has('--publication-figures')) packages <- c(packages,'ragg')
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Install required packages with Rscript Code/install_packages.R. Missing: ',paste(missing,collapse=', '))
required <- c('gbd_all_age_dalys.csv','hale_all_age.csv','population_all_age.csv','gbd_burden_both_sexes.csv.gz','population_age_specific_both_sexes.csv.gz')
if(any(!file.exists(file.path(inputs,required)))) stop('Missing licensed input files in ',inputs,'. See Documentation/DATA_ACCESS.md. Required: ',paste(required,collapse=', '))
options(tbl.repo_root=repo,tbl.results_dir=results,tbl.input_dir=inputs)
for(folder in c('Data','Tables','Figures','QA','PublicationFigures')) dir.create(file.path(results,folder),recursive=TRUE,showWarnings=FALSE)
scripts <- c('01_prepare_data.R','02_epidemiology_sensitivity.R','03_forecast_validation.R','04_pandemic_model_sensitivity.R','05_economic_figures.R','06_decomposition.R','08_population_denominator_sensitivity.R','09_export_analysis_data.R')
if(has('--publication-figures')) {
 if(!file.exists(file.path(inputs,'map_and_location_archive.rds'))) stop('Publication maps require the archived map file; see DATA_ACCESS.md.')
 scripts <- c(scripts,'07_publication_figures.R')
}
for(script in scripts) {
 cat('\nRUN',script,'\n')
 source(file.path(repo,'Code',script),local=new.env(parent=globalenv()))
}
writeLines(capture.output(sessionInfo()),file.path(results,'QA/R_session_info.txt'))
cat('\nDONE. Results:',results,'\n')
