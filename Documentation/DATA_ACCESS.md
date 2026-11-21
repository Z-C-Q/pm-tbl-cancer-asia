# Obtaining and arranging health inputs

Download health estimates through the official [GBD Results Tool](https://vizhub.healthdata.org/gbd-results/) and consult the [GBD data portal](https://ghdx.healthdata.org/gbd-2023). Accept the applicable IHME terms and use the release corresponding to this study. The repository does not automate access to an authenticated IHME service.

For exact reproduction, use the study's frozen files where their sharing is authorized. A fresh upstream download may have revised estimates and should not be assumed to match this release.

## Source selection

- Release: GBD 2023; calendar years 1990–2023.
- Cause: tracheal, bronchus, and lung cancer, ID 426.
- Risk: ambient particulate matter pollution, ID 86.
- Measure: DALYs, ID 2.
- Locations: the 45 countries listed in `Sources/country_region_mapping_45.csv`.
- All-age valuation: Male, Female and Both; all-age DALY counts, corresponding HALE in years, and corresponding all-age population.
- Age-specific analyses: Both sexes, Number and Rate, including 25–29 through 95+, all ages and provided age-standardized rates. Preserve source `val, lower, upper` where available.
- Population: all-age and age-specific population counts for the same country-year-sex definitions.

The source labels and metadata must be checked when downloading. The code expects the archived all-age HALE convention, not a newly inferred age-specific remaining life expectancy.

## Compact files expected by the runner

Place the following together in one input directory:

```text
Inputs/
  gbd_all_age_dalys.csv
  hale_all_age.csv
  population_all_age.csv
  gbd_burden_both_sexes.csv.gz
  population_age_specific_both_sexes.csv.gz
  map_and_location_archive.rds          # optional for maps / bold figure collection
```

Column layouts are in `Data/Inputs/*_schema.csv`. The schemas have **headers only**, not fabricated example observations. Use `--input-dir` to point to the actual files. The supplied local reproduction data bundle already has this structure and also includes primary and six-scenario reference datasets.

If starting from original author extracts with compatible GBD columns:

```sh
Rscript Code/prepare_external_inputs.R --burden /path/48.csv --hale /path/hale_90-23.csv --population /path/population.csv --output-dir /path/new-compact-inputs
```

This preprocessing script writes a new compact directory and does not alter the source files. It requires `data.table`, `dplyr`, and `readr`. The raw population export is large; allow sufficient memory. Source-input SHA-256 hashes and known dates are recorded in `Sources/gbd_input_provenance.json`. Original download timestamps and upstream export job IDs were not available and are not invented.

## Public data scope

WDI snapshots are included with attribution and source terms. The GBD raw extracts, compact source-value subsets, row-level derived valuation data and map archive are supplied separately for local reproduction pending confirmation of applicable redistribution permission. Do not treat the absence of an open code license restriction as a new license for third-party data.
