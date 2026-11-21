# CPI Inflation Analysis: India, 2013 to 2023

An Excel case study on India's Consumer Price Index. It covers raw data, documented cleaning, five analyses, a PivotTable cross-check and a dashboard.

## Problem

What drove inflation in India, and where should someone watching prices look? The analysis explains how inflation moved from 2018 to 2023, what makes up the price basket, and how COVID-19 and fuel prices affected it.

## Data

- Monthly Consumer Price Index for rural, urban and combined (Rural+Urban) sectors
- 125 months, January 2013 to May 2023 (124 published, 1 estimated)
- 24 priced categories grouped into 10 broad buckets
- All analyses use the Rural+Urban sector

## Approach

1. **Kept the raw data untouched** and logged five data issues before fixing any.
2. **Cleaned with formulas, not pasted values**, so every number traces back to the source.
3. **Filled gaps by interpolation** and flagged every estimated value.
4. **Built five analyses** with live formulas: AVERAGEIFS, SUMPRODUCT, INDEX/MATCH, CORREL.
5. **Cross-checked the results** with PivotTables.
6. **Summarised** the findings in a dashboard.

## Data quality issues found

| # | Issue | How it was handled |
|---|-------|--------------------|
| 1 | Two month-name typos | Fixed with a formula |
| 2 | Rural Housing is "NA" or "-" in every row (rents are not surveyed in rural India) | Left as "N/A", not imputed |
| 3 | 13 categories missing in April 2020 (lockdown) | Straight-line interpolation |
| 4 | All categories missing in May 2020 | Interpolation, or average of April and June |
| 5 | April 2019 missing from the source | Added 3 rows (average of March and May) |

## Key findings

- **Inflation peaked at 6.6% in 2022.** It was 3.95% in 2018, 3.72% in 2019, 6.19% in 2020, 5.63% in 2021 and 3.18% in Jan-May 2023.
- **The basket is balanced.** Every bucket holds between 9.2% and 11.2% of the index.
- **Food prices moved unevenly.** Spices rose 30.9 index points while oils and fats fell 30.9 (Jun 2022 to May 2023).
- **COVID-19 lifted transport and food most.** Transport rose 14.7% and food 12.7%.
- **Fuel tracks transport, not food.** Monthly fuel price changes correlate 0.67 with transport and 0.08 with food.

## Validation

- A PivotTable counting rows per year showed 2019 with 33 rows instead of 36, which exposed the missing April 2019.
- Annual inflation was rebuilt with a PivotTable and matches the formulas to 0.00%.

## Limitations

- Bucket shares are index-level shares, not official MoSPI expenditure weights.
- 2023 covers January to May only.
- Fuel & Energy CPI is a proxy for oil prices, and correlation is not causation.
- Some months repeat the previous month's value in the source (for example June-July 2020) and were left as published.

## Tools

Excel: AVERAGEIFS, SUMPRODUCT, INDEX/MATCH, CORREL, EDATE, PivotTables, charts

## Files

- [CPI_Inflation_Analysis_Case_Study.xlsx](CPI_Inflation_Analysis_Case_Study.xlsx): the full workbook (README, dashboard, data quality log, cleaned data and five analyses)
- [CPI_Inflation_Analysis_Excel_Case_Study.pdf](CPI_Inflation_Analysis_Excel_Case_Study.pdf): the presentation
