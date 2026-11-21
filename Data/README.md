# Data layout

`Inputs/` contains header-only schemas in the public code release. Point the runner to legitimately obtained compact health tables using `--input-dir`.

`Derived/analysis_ready_schema.csv` documents the core sharing fields. Actual outputs are created in `Results/Data/` or supplied separately in the local reproduction bundle:

- `analysis_ready_primary.csv`: 4,548 primary records.
- `valuation_all_scenarios.csv.gz`: 27,288 records across six complete scenarios.
- `valuation_epsilon_{0.5,1,1.5}_{half_HALE,full_HALE}.csv.gz`: six separate files, 4,548 records each.
- `all_country_year_sex_inputs_with_missingness.csv`: all 4,590 country-year-sex records before removing unavailable economic estimates, in the local bundle.

`VLW_GDP` is a fraction; `VLW_GDP_pct` is a percentage. Full variable definitions are in `Documentation/DATA_DICTIONARY.md`.
