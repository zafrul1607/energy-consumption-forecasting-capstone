# Energy Consumption Forecasting for Business Cost Planning

## Project Overview

This capstone project focuses on forecasting monthly commercial electricity consumption for business cost planning. Energy is a major operating cost for businesses, cities, and public organizations, and demand can change based on seasonality, state-level activity, electricity price, customer count, and economic conditions.

The project uses SQL for data preparation and Python for forecasting, model evaluation, and visual analysis.

## Business Problem

Businesses and public planners need better ways to estimate future electricity demand so they can plan budgets, prepare for high-demand months, and make more informed energy cost decisions. Looking at electricity price alone is not enough because commercial energy demand is also affected by customer count, state size, prior usage, and seasonal patterns.

## Data Sources

This project uses three public datasets:

1. EIA monthly electricity sales, revenue, customers, and price data
2. U.S. Census ACS DP03 Selected Economic Characteristics
3. U.S. Census ACS DP05 Demographic and Housing Estimates

The final dataset was prepared at the state-month level.

## Tools Used

- PostgreSQL / pgAdmin 4
- SQL
- Python
- Google Colab
- pandas
- NumPy
- scikit-learn
- matplotlib

## Workflow

1. Imported EIA and Census CSV files into PostgreSQL
2. Cleaned numeric fields and standardized state names
3. Joined EIA electricity data with Census economic and demographic data
4. Created a state-month modeling dataset with 8,568 records
5. Engineered 13 features including lag, seasonality, price, poverty, customer, and interaction variables
6. Built Linear Regression and Random Forest models in Python
7. Evaluated model performance using MAE, RMSE, MAPE, and R²
8. Created charts and business recommendations

## Model Results

| Model | MAE | RMSE | MAPE | R² |
|---|---:|---:|---:|---:|
| Linear Regression | 98,228.44 | 161,590.14 | 5.33% | 0.9961 |
| Random Forest | 73,004.62 | 123,449.17 | 3.33% | 0.9977 |

The Random Forest model performed better, achieving 3.33% MAPE.

## Main Findings

- Commercial electricity sales showed strong seasonal patterns.
- July and August had the highest average commercial electricity demand.
- Texas, California, Florida, and New York had the highest average monthly commercial electricity sales.
- Electricity price alone did not explain demand because customer count, state size, and historical usage were also important.
- Previous-month sales and previous-year sales were the strongest forecasting features.

## Recommendations

Businesses and planners should forecast energy demand using historical demand, customer counts, seasonality, and price-related indicators together. The model can support budget planning by identifying high-demand months before they occur.


