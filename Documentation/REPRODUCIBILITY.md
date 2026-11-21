# Reproducibility guide

## Frozen inputs and price basis

The WDI responses were retrieved on **2026-11-06 15:05:41 UTC**; their reported update date is **2026-10-08**. Original URLs, record counts and SHA-256 hashes are preserved in `Sources/provenance.json`. Reproduction reads these snapshots. It never calls the live WDI API.

The original full GBD extracts are not necessary once the five compact input tables have been obtained legitimately. These contain the health estimates and population values used in this study. They can also be recreated from the author's source files using `Code/prepare_external_inputs.R`.

US 2023 reference VSL: **13,200,000**. US 2023 reference income in the same constant-2021 PPP series: **74351.6718197429**. US GDP deflators: **104.562972826319** in 2021 and **116.144257693854** in 2023. Their ratio is **1.110758947976467**. The corresponding rebased reference income is **82586.78477078915**.

The VSL reference is an inherited, author-confirmed model input from the revised study. This code release does not represent a fresh verification of the external VSL source. The selected HALE/2 approximation is described as an assumption; no universal validity claim is made.

## Pipeline

| Stage | Script | Output |
|---|---|---|
| Input harmonization and valuation | `01_prepare_data.R` | Joins GBD DALYs, HALE and population with frozen WDI; keeps missingness; produces prepared result object |
| Health trends and sensitivity | `02_epidemiology_sensitivity.R` | DALYs, pooled ASDR, six valuation cases, ranks, fixed-43 comparisons |
| Forecast validation | `03_forecast_validation.R` | Seven models, rolling origins 2004–2018, horizons 1/3/5/10 years, temporal holdouts, exploratory 2024–2050 paths |
| Pandemic-period comparisons | `04_pandemic_model_sensitivity.R` | Pre-2020 model comparisons and descriptive deviations |
| Economic presentation | `05_economic_figures.R` | Country maps if archive supplied, subregional and sex-specific figures |
| Decomposition | `06_decomposition.R` | Three-factor Shapley decomposition across all six replacement orders |
| Population denominator sensitivity | `08_population_denominator_sensitivity.R` | Supplied versus rate-implied population comparison |
| Shareable final exports | `09_export_analysis_data.R` | Standardized primary file, combined scenarios and six individual scenario files |
| Enlarged bold graphics, optional | `07_publication_figures.R` | 4 main + 10 supplementary figures, PDF/PNG/TIFF, publication typography |
| Independent verification | `validate_results.py` | Equations, source hashes, country coverage, aggregation, decomposition, fixed valuation and reference checks |
| Independent Python valuation | `reproduce_valuation.py` | Recomputes primary and six cases directly from input CSVs and WDI JSON |

The runner invokes stages in dependency order, including stage 07 after the numeric analyses. Stage numbers preserve the historical analysis structure.

## Validation

```sh
python3 Code/validate_results.py --results-dir Results
```

When the full local derived reference files are available:

```sh
python3 Code/validate_results.py --results-dir Results --reference-dir /path/to/local-reproduction-data/Derived
```

The latter compares every primary and six-scenario row with the frozen reference. An independently executed Python calculation provides an additional check of the arithmetic. Reference headline results are in `Documentation/reference_results.json`; execution-specific checks and session information are written under `Results/QA/`.

Full execution was tested from a working directory outside the repository. The original manuscript, reviewer correspondence, desktop R workspace and the 681 MB population source are not required at runtime. Exact map reproduction needs the supplied archived map data; its original provider and redistribution rights were not established by this release, so it is kept with the local data, not in the public code repository.

## Scope of numerical reproducibility

Validated row comparisons allow relative differences up to `1e-9`, with an absolute floor of `1e-6`, to accommodate CSV round trips and floating-point summation. Dependencies are recorded rather than falsely represented as a complete lockfile. Small fitted-model differences can occur with different R or package versions; use the recorded tested versions when assessing them.

No joint draw-level uncertainty analysis is implemented. Forecast scenarios are not validated 27-year forecasts. Both-sex and separate male/female annualized valuations need not be strictly additive. ASDR and health decomposition use 45 countries for all years; monetary series distinguish changing coverage from a balanced panel.
