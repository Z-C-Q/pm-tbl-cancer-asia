# Parameter files

- `valuation_settings.json`: exact model settings, VSL, US reference income, price conversion factor, both deflator values, elasticity scenarios, HALE factors, age/cause/risk definitions and country scope.
- `valuation_parameters.csv`: concise numeric parameter table from the frozen revised analysis.
- `tested_R_packages.csv`: R package versions actually used during packaging and verification; not a claim that a complete dependency lockfile exists.

The primary model is explicitly the `epsilon=1`, `hale_factor=0.5` case. Both HALE factors and all three elasticity values are run by the sensitivity pipeline. Country-count labels and the primary-case reference checks describe this frozen study design. If changing that design, update labels, country scope and reference checks together.

HALE is matched by country, year and sex using the external HALE input table. It is not a single global constant. WDI reference income is fixed to US 2023 in the frozen constant-2021 PPP series. GDP per capita is never reconstructed using GBD population.
