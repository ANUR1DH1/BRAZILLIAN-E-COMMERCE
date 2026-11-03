# Brazilian E-Commerce Data Analytics – Olist

## Project Overview
This project analyzes the Brazilian Olist e-commerce dataset to understand business performance, delivery operations, customer satisfaction, revenue patterns, and payment behavior.

The main objective is to identify operational challenges and provide data-driven business recommendations.

## Business Problem
Are delivery delays affecting customer satisfaction, and what operational improvements should Olist prioritize?

## Tools and Technologies
- Python: Pandas, NumPy, Matplotlib, Seaborn, SciPy
- SQL: PostgreSQL
- Data Visualization: Power BI
- Environment: Google Colab / Jupyter Notebook

## Project Workflow
1. Business understanding and problem definition.
2. Data exploration and quality assessment.
3. Data cleaning and validation.
4. Data modeling using a star schema.
5. PostgreSQL database creation and SQL analysis.
6. Python analysis and statistical hypothesis testing.
7. Power BI dashboard development.
8. Business recommendations and conclusions.

## Key Findings
- Total orders analyzed: 99,441.
- Delivery completion rate: approximately 97.02%.
- Late delivered orders: 7,826.
- Late delivery rate: 8.11%.
- Average customer review score: 4.05 out of 5.
- Low review percentage: approximately 14.70%.

A Chi-square test of independence found a statistically significant association between delivery status and review rating (χ² = 13,249.786, df = 2, p < 0.001).

Among reviewed late deliveries, 54.02% received low ratings, compared with 9.19% of reviewed on-time deliveries. This indicates an association, not proof of causation.

## Business Recommendations
- Improve delivery reliability and reduce late deliveries.
- Monitor delivery performance across geographical regions.
- Evaluate seller-level delivery performance.
- Improve delivery estimates and customer communication.
- Monitor category and seller revenue and payment behavior.

## Repository Structure
- `notebooks/` – Python notebooks for exploration, cleaning, modeling, and analysis.
- `sql/` – PostgreSQL analysis queries.
- `powerbi/` – Interactive Power BI dashboard.
- `documentation/` – Executive summary, data model documentation, recommendations, and schema diagram.
- `python_outputs/` – Outputs generated during Python analysis.


## Dataset
The project uses the Olist Brazilian E-Commerce Public Dataset. The original data contains multiple related tables covering customers, orders, products, sellers, payments, reviews, and geographical information.

Dataset source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Please obtain the dataset from its original source and follow its applicable terms of use.

## How to Reproduce the Analysis
1. Obtain the dataset from the source listed above.
2. Set up the Python environment using `requirements.txt`.
3. Run the notebooks in numerical order.
4. Load the modeled CSV files into PostgreSQL using the documented database structure.
5. Execute the SQL queries in the `sql/` folder.
6. Open the Power BI report in Power BI Desktop.

## Project Outcome
This project demonstrates an end-to-end data analytics workflow, including data cleaning, relational data modeling, SQL querying, Python analysis, statistical testing, dashboard development, and business recommendations.