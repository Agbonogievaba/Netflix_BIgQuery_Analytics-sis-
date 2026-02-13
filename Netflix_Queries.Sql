#Create cleaned table with dates and years:

CREATE OR REPLACE TABLE `ablding-cedar-482106-k9.Netflix_Data.netflix_titles_clean` AS
SELECT 
  show_id,
  type,
  title,
  director,
  `cast`,
  country,
  date_added,
  SAFE.PARSE_DATE('%B %e, %Y', TRIM(date_added)) AS date_added_clean,
  release_year,
  CAST(release_year AS INT64) AS release_year_clean,
  rating,
  duration,
  listed_in,
  description
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_tityles`

# Verify the cleaning worked:

SELECT 
  show_id,
  title,
  date_added,
  date_added_clean,
  release_year,
  release_year_clean,
  country
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_tityles_clean`
WHERE date_added_clean IS NOT NULL
LIMIT 20

#CLEANING PHASE (Tuesday)
#Explore country field:
SELECT 
  country,
  COUNT(*) as count
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_tityles_clean`
GROUP BY country
ORDER BY count DESC
LIMIT 30

# Split countries and get real counts:

SELECT 
  TRIM(country_individual) AS country,
  COUNT(*) as title_count
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_titles_clean`,
  UNNEST(SPLIT(country, ',')) AS country_individual
WHERE country IS NOT NULL
GROUP BY country
ORDER BY title_count DESC
LIMIT 30

# Create summary table for analysis:
CREATE OR REPLACE TABLE `ablding-cedar-482106-k9.Netflix_Data.netflix_country_summary` AS
SELECT 
  TRIM(country_individual) AS country,
  type,
  EXTRACT(YEAR FROM date_added_clean) AS year_added,
  COUNT(*) as title_count
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_titles_clean`,
  UNNEST(SPLIT(country, ',')) AS country_individual
WHERE country IS NOT NULL 
  AND date_added_clean IS NOT NULL
GROUP BY country, type, year_added
ORDER BY country, year_added

# ANALYSIS PHASE (Wednesday)
# Top 15 countries overall:

SELECT 
  country,
  SUM(title_count) as total_titles
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_country_summary`
WHERE country IS NOT NULL AND country != ''
GROUP BY country
ORDER BY total_titles DESC
LIMIT 15

# US vs International content over time:

SELECT 
  year_added,
  SUM(CASE WHEN country = 'United States' THEN title_count ELSE 0 END) as us_titles,
  SUM(CASE WHEN country != 'United States' THEN title_count ELSE 0 END) as international_titles,
  SUM(title_count) as total_titles,
  ROUND(SUM(CASE WHEN country != 'United States' THEN title_count ELSE 0 END) * 100.0 / SUM(title_count), 1) as pct_international
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_country_summary`
WHERE country IS NOT NULL AND country != ''
  AND year_added BETWEEN 2015 AND 2021
GROUP BY year_added
ORDER BY year_added

# Country growth analysis (early vs recent period):

SELECT 
  country,
  SUM(CASE WHEN year_added BETWEEN 2015 AND 2017 THEN title_count ELSE 0 END) as early_period_2015_2017,
  SUM(CASE WHEN year_added BETWEEN 2019 AND 2021 THEN title_count ELSE 0 END) as recent_period_2019_2021,
  SUM(CASE WHEN year_added BETWEEN 2019 AND 2021 THEN title_count ELSE 0 END) - 
  SUM(CASE WHEN year_added BETWEEN 2015 AND 2017 THEN title_count ELSE 0 END) as growth
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_country_summary`
WHERE country IS NOT NULL AND country != ''
  AND country != 'United States'
  AND year_added BETWEEN 2015 AND 2021
GROUP BY country
HAVING early_period_2015_2017 > 0
ORDER BY growth DESC
LIMIT 15

# Movies vs TV Shows by country:

SELECT 
  country,
  SUM(CASE WHEN type = 'Movie' THEN title_count ELSE 0 END) as movies,
  SUM(CASE WHEN type = 'TV Show' THEN title_count ELSE 0 END) as tv_shows,
  SUM(title_count) as total,
  ROUND(SUM(CASE WHEN type = 'Movie' THEN title_count ELSE 0 END) * 100.0 / SUM(title_count), 1) as pct_movies
FROM `ablding-cedar-482106-k9.Netflix_Data.netflix_country_summary`
WHERE country IS NOT NULL AND country != ''
GROUP BY country
ORDER BY total DESC
LIMIT 15
