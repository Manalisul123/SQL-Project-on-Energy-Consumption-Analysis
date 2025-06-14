CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country_3 (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM country_3;


-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);

SELECT * FROM emission_3;


-- 3. population table
CREATE TABLE population_3 (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country_3(Country)
);

SELECT * FROM population_3;

-- 4. production table
CREATE TABLE production_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);


SELECT * FROM production_3;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country_3(Country)
);

SELECT * FROM gdp_3;

-- 6. consumption table
CREATE TABLE consum_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country_3(Country)
);

SELECT * FROM consum_3;

-- Q1 What is the total emission per country for the most recent year available?
SELECT country,sum(emission) as total_emission
from emission_3
WHERE year=
(SELECT max(year)as recent_year 
from emission_3)
group by country
order by total_emission desc;

-- Q2 What are the top 5 countries by GDP in the most recent year?
SELECT country, value, year
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
ORDER BY value DESC
LIMIT 5;

-- Q3.Compare energy production and consumption by country and year. 
SELECT
  p.country,
  p.year,
  p.energy,
  c.consumption,
  p.production
FROM production_3 AS p
JOIN consum_3     AS c 
  ON p.country = c.country
  AND p.year    = c.year
  AND p.energy  = c.energy
ORDER BY p.production DESC;

-- Q4.Which energy types contribute most to emissions across all countries?
SELECT
`energy type`, sum(emission) AS total_emission
FROM emission_3
GROUP BY `energy type`
ORDER by total_emission DESC;

-- Q5.Trend Analysis Over Time 
-- How have global emissions changed year over year?
SELECT
year, sum(emission) AS total_emission
FROM emission_3
GROUP BY year
ORDER BY year DESC;

-- Q6.What is the trend in GDP for each country over the given years?
SELECT
country, year, value AS gdp
FROM gdp_3
ORDER BY gdp desc,year;

-- Quries related to emission
-- Q7.How has population growth affected total emissions in each country?
SELECT
p.countries,
p.year,
sum(e.emission) AS total_emission,
p.value AS population
FROM population_3 p
JOIN emission_3 e
ON p.countries = e.country
AND p.year = e.year
GROUP BY p.countries, p.year, p.value
ORDER BY countries,year;

-- Q8.Has energy consumption increased or decreased over the years for major economies?
SELECT
  me.country,
  c.year,
  SUM(c.consumption) AS total_consumption
FROM consum_3 AS c
JOIN (SELECT
country,SUM(value) AS total_gdp
  FROM gdp_3
  GROUP BY country
  ORDER BY total_gdp DESC
  LIMIT 5
) AS me
  ON c.country = me.country
GROUP BY c.year,me.country
ORDER BY c.year DESC,me.country;

-- Q9.What is the average yearly change in emissions per capita for each country?
WITH emissionchanges AS (
  SELECT country,year,`per capita emission`,
 LAG(`per capita emission`) OVER (PARTITION BY country ORDER BY year) AS pre_year_emission
  FROM emission_3
)
SELECT country,ROUND(AVG(`per capita emission` - pre_year_emission), 2) AS avg_year_percapita_change
FROM emissionchanges
WHERE pre_year_emission IS NOT NULL
GROUP BY country
ORDER BY avg_year_percapita_change DESC;

-- Q9.Ratio & Per Capita Analysis
-- What is the emission-to-GDP ratio for each country by year?
SELECT e.country, e.year,
round((sum(e.emission)/sum(g.value)), 4) AS emission_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g
ON e.country = g.country
AND e.year = g.year
group by country, year
order by country,year;

-- Q10.What is the energy consumption per capita for each country over the last decade?
with recent_years AS (
 SELECT max(year) AS max_year FROM consum_3),
 consumption_data AS (
 SELECT c.country, c.year,c.consumption, p.value AS population
 FROM consum_3 c
 JOIN population_3 p
 ON c.country = p.countries AND c.year = p.year
 WHERE c.year >= (SELECT max_year - 9 FROM recent_years)
 )SELECT country,year,
 ROUND(sum(consumption)/sum(population), 4) AS consumption_per_capita
 FROM consumption_data
 GROUP BY country,year
 ORDER BY consumption_per_capita desc;
 
 select * from population_3;
 
 -- Q11.How does energy production per capita vary across countries?
 SELECT
  p.countries,
  ROUND(SUM(p1.production) / SUM(p.value), 4) 
  AS production_percapita
FROM population_3 AS p
JOIN production_3 AS p1
  ON p.countries = p1.country
  AND p.year    = p1.year
GROUP BY p.countries
ORDER BY production_percapita DESC;

-- Q12.Which countries have the highest energy consumption relative to GDP?
SELECT
c.country,
ROUND(sum(consumption)/sum(g.value),4) AS relative_consumption_for_gdp
FROM consum_3 c
JOIN gdp_3 g
ON c.country = g.country
AND c.year = g.year
GROUP BY country
ORDER BY relative_consumption_for_gdp desc;


-- Q13.Global Comparisons
-- Q What are the top 10 countries by population and how do their emissions compare?
SELECT 
p.countries,
sum(p.value) AS total_population,
sum(e.emission) AS total_emission
FROM population_3 p
JOIN emission_3 e
ON p.countries = e.country
AND p.year = e.year
GROUP BY p.countries
ORDER BY total_population desc
limit 10;

-- Q14. How Have Global Emissions Changed Year Over Year?
SELECT
year, sum(emission) AS total_emission
FROM emission_3
GROUP BY year
order by year desc;

-- Q15.What is the global share (%) of emissions by country?
with total_emission_percountry as (
select country,sum(emission) AS total_emission
FROM emission_3 group by country)
SELECT country,round(total_emission*100/(select sum(emission)from emission_3),5)AS share
from total_emission_percountry
order by share desc;

-- Q16.What is the global average GDP, emission, and population by year?
SELECT
e.year,
ROUND(AVG(g.value), 5) AS avg_gdp,
ROUND(AVG(e.emission), 5) AS avg_emission,
ROUND(AVG(p.value), 5) AS avg_population
FROM emission_3 e
JOIN gdp_3 g ON e.country = g.country
AND e.year = g.year
JOIN population_3 p ON p.countries = e.country
AND p.year = e.year
GROUP BY e.year
ORDER BY e.year;
