# Run explicitly once. The analysis never installs packages or refreshes data.
packages <- c('dplyr','tidyr','readr','jsonlite','ggplot2','patchwork','scales','forecast','ragg','data.table')
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,repos='https://cloud.r-project.org')
cat('Required packages are available. Tested versions are listed in Parameters/tested_R_packages.csv.\n')
