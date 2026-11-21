# Data dictionary

## Analysis-ready exports

`analysis_ready_primary.csv`: one valued country-year-sex per row, 4,548 rows.

`valuation_all_scenarios.csv.gz`: one valued country-year-sex-scenario per row, 27,288 rows. There are six combinations of income elasticity and HALE annualization.

| Field | Definition / unit |
|---|---|
| `location_id` | GBD location identifier; join key |
| `location_name` | GBD country name |
| `ISO3` | WDI country code; Palestine uses PSE |
| `region_6` | Study's six-subregion classification; see country mapping |
| `year` | Calendar year, 1990–2023 |
| `sex_id` | GBD identifier: 1 Male, 2 Female, 3 Both |
| `sex_name` | Male, Female, Both |
| `DALYs` | PM-attributable TBL cancer DALY count, all ages, sex-specific |
| `DALYs_lower`, `DALYs_upper` | Marginal bounds supplied with the source DALY estimate; not joint regional draws |
| `HALE` | Country-year-sex healthy life expectancy, years, source all-age row |
| `HALE_lower`, `HALE_upper` | Source HALE bounds, where retained |
| `GDP_per_capita_const2021` | Native WDI `NY.GDP.PCAP.PP.KD`, constant 2021 international dollars per person |
| `GDP_per_capita` | The preceding WDI series multiplied by K, constant 2023 international dollars per person |
| `GDP_const2021` | Native WDI `NY.GDP.MKTP.PP.KD`, constant 2021 international dollars; retained in the primary/Python export |
| `GDP` | Total GDP rebased to constant 2023 international dollars; same total used for every sex |
| `WDI_population` | WDI `SP.POP.TOTL`; audit field, not the GBD population denominator |
| `population` | GBD all-age population for the matching country-year-sex |
| `VSL` | Income-transferred statistical life value, constant 2023 international dollars |
| `VSLY` | VSL divided by `HALE × hale_factor`, constant 2023 international dollars per healthy life year |
| `VLW` | DALYs × VSLY, constant 2023 international dollars |
| `VLW_GDP` | VLW/GDP as a fraction; 0.01 means 1% |
| `VLW_GDP_pct` | 100 × VLW/GDP; 1 means 1% |
| `per_capita_VLW` | VLW/population, constant 2023 international dollars per person |
| `VLW_per_capita` | Original R variable name; same value as `per_capita_VLW` |
| `epsilon` | Income elasticity: 0.5, 1, 1.5 |
| `hale_factor` | 0.5 for primary HALE/2 denominator; 1 for full HALE denominator |
| `hale_convention` | `HALE/2 primary` or `HALE sensitivity` |
| `monetary_unit` | Constant 2023 international dollars |
| `valuation_available` | Whether income and total GDP are available; full input file preserves unavailable rows |
| `VLW_DALY_lower`, `VLW_DALY_upper` | DALY marginal bounds multiplied by central VSLY only; not full valuation uncertainty |

Original intermediate R files retain legacy names: `LE` is HALE, `GDPpc_2023` is `GDP_per_capita`, `GDPpc_const2021` is `GDP_per_capita_const2021`, and `VLW_GDP_ratio` is **a percentage**, not a fraction. Use the standardized final exports above for sharing.

## Input tables

| File | Row key / role |
|---|---|
| `gbd_all_age_dalys.csv` | `location_id, year, sex_id`; 4,590 rows, all-age DALY counts and source marginal bounds |
| `hale_all_age.csv` | `location_id, year, sex_id`; 4,590 rows; HALE with source bounds |
| `population_all_age.csv` | `location_id, year, sex_id`; 4,590 rows; sex-specific all-age population |
| `gbd_burden_both_sexes.csv.gz` | `location_id, year, age_id, metric_name`; 76,500 source rows, both sexes, age-specific and all-age/standardized rows |
| `population_age_specific_both_sexes.csv.gz` | `location_id, year, age_id`; 61,200 source rows, both-sex population |

All health inputs are aggregate modeled country-level estimates, not individual records. Study cause ID is 426, risk ID 86, DALY measure ID 2. Adult decomposition and pooled ASDR use 15 age groups from 25–29 through 95+. The age weights are used as supplied and are **not renormalized** over those adult age groups.

Economic data are missing for Afghanistan in 1990–1999 and Palestine in 1990–1993: 14 country-years × 3 sex categories = 42 rows. Main scenario exports retain the remaining 4,548 valued rows; the separate full input file retains all 4,590.
