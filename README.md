# PM-attributable TBL cancer welfare burden in Asia, 1990–2023

Reproducibility code for **Economic burden of ambient particulate matter pollution–attributable tracheal, bronchus, and lung cancer in Asia, 1990–2023: a GBD 2023 analysis**.

The repository separates epidemiological burden (DALYs and age-standardized DALY rates) from income-dependent monetized welfare loss. Monetary outputs use **constant 2023 international dollars**.

## Contents

| Directory | Contents |
|---|---|
| `Code/` | Portable R analysis pipeline, independent Python valuation, validation, optional WDI snapshot downloader, publication figure styling |
| `Data/Inputs/` | Input schemas; licensed GBD input files are obtained separately |
| `Data/Derived/` | Schema for the analysis-ready dataset; the pipeline produces primary and all six scenario files |
| `Sources/` | Frozen WDI API JSON/CSV, US GDP deflator, original retrieval metadata and hashes, country mapping, age weights |
| `Parameters/` | Explicit VSL, reference income, currency conversion, elasticities, HALE conventions, tested package versions |
| `Documentation/` | Data dictionary, calculation steps, data access, GitHub upload guide and reference results |

This public code bundle contains WDI snapshots and data schemas. **It does not bundle the licensed GBD extracts, row-level GBD-derived datasets, or the map archive.** Those files are kept in the separate local reproduction data bundle. See [data access](Documentation/DATA_ACCESS.md) and [data-use notices](Documentation/DATA_USE.md).

## Reproduce the analysis

Tested with **R 4.5.0**. See `Parameters/tested_R_packages.csv` for the actual package versions. Package installation requires internet access; the analysis uses frozen local inputs and does not download data.

```sh
Rscript Code/install_packages.R
Rscript Code/run_all.R --input-dir /path/to/local-reproduction-data/Inputs
python3 Code/validate_results.py
```

The input directory must contain five files described in [DATA_ACCESS.md](Documentation/DATA_ACCESS.md). These commands write analysis data, tables and original-style figures into `Results/`. `Results/` is ignored by Git. A different output directory can be supplied with `--output-dir`; supply the same directory to `validate_results.py --results-dir`.

To regenerate all **14 enlarged, bold publication figures**, provide the archived map file in the same input directory and add:

```sh
Rscript Code/run_all.R --input-dir /path/to/local-reproduction-data/Inputs --publication-figures
```

Publication figures are written to `Results/PublicationFigures/` as PDF, 300 dpi TIFF and PNG. The portable version uses the system sans-serif font; exact letter shapes may differ across operating systems.

For a quick independent check of valuation, Python requires **no external packages**:

```sh
python3 Code/reproduce_valuation.py --input-dir /path/to/local-reproduction-data/Inputs
```

Scripts resolve repository paths from their own location. They can also be invoked with an absolute script path from another working directory.

## Valuation and scenarios

For country `c`, year `t`, sex `s`, income elasticity `epsilon`, and HALE multiplier `h`:

```text
VSL(c,t)       = 13,200,000 × [q(c,t) / q(USA,2023)]^epsilon
VSLY(c,t,s)    = VSL(c,t) / [HALE(c,t,s) × h]
VLW(c,t,s)     = DALYs(c,t,s) × VSLY(c,t,s)
GDP_2023(c,t)  = GDP_const2021(c,t) × K
VLW_GDP       = VLW / GDP_2023
VLW_GDP_pct   = 100 × VLW_GDP
per_capita_VLW = VLW / population
```

`q` is WDI native GDP per capita in constant 2021 international dollars. The frozen US 2023 reference income is `74351.6718197429`. `K = 1.110758947976467` converts 2021 prices to 2023 prices. The common conversion factor cancels in the income ratio. GDP per capita is the native WDI series, not GDP divided by GBD population.

The primary case uses `epsilon = 1`, `h = 0.5`. All combinations of `epsilon ∈ {0.5, 1, 1.5}` and `h ∈ {0.5, 1}` are produced. `HALE/2` is an explicitly stated annualization approximation; the full-HALE case is a sensitivity analysis.

The main dataset has **4,548 valued country-year-sex records**. The full input grid has **4,590 records**, including 42 records without sufficient economic data. The six-scenario dataset has **27,288 records**. The primary export includes all 13 fields requested for replication, with `VLW_GDP` reported as a fraction and `VLW_GDP_pct` reported as a percentage.

## Cohort and interpretation

- 45 study countries; Syria is excluded because the frozen WDI release lacks 2023 inputs.
- Economic coverage: 43 countries in 1990–1993, 44 in 1994–1999, 45 in 2000–2023. Missing economic values are not replaced with zero.
- Afghanistan and Palestine remain in 2023 estimates. The balanced historical panel contains 43 countries.
- Health results and decomposition use the same 45-country cohort throughout 1990–2023. Population decomposition refers to people aged 25 and over.
- Long-term paths are exploratory model scenarios. Model disagreement is not a 95% interval. Joint draw-level uncertainty propagation is not implemented.
- GBD-attributable burden and descriptive decomposition do not identify a pollution-specific causal effect. Sex-specific valuations need not add exactly to the independently annualized both-sex valuation.

The frozen 2023 result is **616.4735886069384 billion** constant 2023 international dollars, **0.7076988253961719%** of GDP. See [reference results](Documentation/reference_results.json).

中文使用说明见 [README_zh.md](README_zh.md)。代码和数据的许可范围见 [LICENSE_SCOPE.md](Documentation/LICENSE_SCOPE.md)。
