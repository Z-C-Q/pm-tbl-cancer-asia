# Validation of the 2026-11-20 release

The portable package was executed using R 4.5.0 and the package versions in `Parameters/tested_R_packages.csv`, from a working directory outside the original project. The full R run completed without warnings after PDF labels were made compatible with the default encoding. All 14 enlarged, bold publication figures were generated.

Checks completed:

- **21 independent checks passed**, including frozen WDI hashes, the US deflator ratio, valuation equations, all six sensitivity scenarios, full-HALE versus half-HALE scaling, country coverage, fixed-valuation products, regional sums, age-standardization, decomposition and temporal target dates.
- **4,548 primary records** and **27,288 scenario records** were compared with the frozen reference files by country-year-sex-scenario. Numeric comparisons passed with the tolerances stated in `REPRODUCIBILITY.md`.
- All **21 generated result CSV tables** matched the frozen revised-study tables. Comparisons allow normal floating-point differences; they do not claim byte-identical gzip streams or identical binary R objects.
- A separate Python standard-library implementation independently recalculated all valuations. Its 4,548 primary records matched the corresponding R fields, including GDP ratios and per-capita estimates.
- The five compact input tables were independently regenerated from the author's original burden, HALE and population exports and compared by their record keys. All matched.
- Every R file parsed successfully and every Python file passed syntax parsing. The public code/documentation/source files were scanned for original machine paths and private discussion identifiers.

The code and data were not uploaded to a remote repository during packaging. No new upstream WDI or GBD data were downloaded for the numerical run. GBD redistribution rights and the code license remain separate from numerical reproducibility; see `DATA_USE.md` and `LICENSE_SCOPE.md`.

The detailed local audit outputs are retained outside the public repository in the delivery folder's `Verification/`. Future runs generate their own report in `Results/QA/validation_checks.json`.
