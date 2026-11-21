# Third-party data and attribution

Checked on 2026-11-20. This file identifies upstream notices; it does not grant rights owned by third parties.

## IHME / GBD

Source: Institute for Health Metrics and Evaluation (IHME), University of Washington. Underlying study estimates are GBD 2023 country-level aggregate estimates. Official access: https://vizhub.healthdata.org/gbd-results/ and https://ghdx.healthdata.org/gbd-2023.

The [IHME Free-of-Charge Non-Commercial User Agreement](https://www.healthdata.org/sites/default/files/files/free-of-charge_non-commercial_user_agreement.pdf) distinguishes publishing analytical results from providing IHME datasets for download through third-party hosting. This release does not presume that the author's download access establishes permission for public dataset rehosting. The GBD inputs and row-level derived files are therefore kept in the separate local data bundle until the applicable redistribution scope is confirmed. Retain the source attribution required by the agreement in publications and shared materials. No IHME endorsement is implied.

## World Bank

Attribution: The World Bank: World Development Indicators: `NY.GDP.PCAP.PP.KD`, `NY.GDP.MKTP.PP.KD`, `SP.POP.TOTL`, and US `NY.GDP.DEFL.ZS`. Frozen API responses were retrieved 2026-11-06. WDI is provided under CC BY 4.0 with the additional conditions and indicator-specific qualifications in the [World Bank dataset terms](https://data.worldbank.org/summary-terms-of-use); see the [WDI catalog](https://datacatalog.worldbank.org/infrastructure-data/search/dataset/0037712/world-development-indicators).

Changes made here: conversion of JSON records to long-form CSV; filtering and joining country-year records; conversion of 2021 constant-price outputs to 2023 prices using the specified US deflator ratio; construction of income-transferred valuations. Original API JSON bytes are retained with original SHA-256 hashes. The World Bank does not endorse this independent analysis.

## Maps and study parameters

The exact archived polygon dataset is optional and kept with the local data. Its original acquisition record and redistribution license were not established in the materials available for packaging. The code does not label it as open data or assign it a new license.

VSL, income elasticities, HALE annualization convention and study cohort are model settings documented in `Parameters/`; they do not change the rights applying to source data. GBD standard age weights and location identifiers are preserved as necessary methodological metadata with IHME attribution.
