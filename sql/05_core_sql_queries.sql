-- ============================================================
-- A. Coverage Trends
-- ============================================================

-- 1. All coverage data with country and vaccine names
SELECT c.year, co.name AS country_name, v.description AS vaccine_name, c.coverage_percent
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
ORDER BY c.year;

-- 2. Average coverage per country
SELECT co.name AS country_name, AVG(c.coverage_percent) AS avg_coverage
FROM coverage c
JOIN country co ON c.country_id = co.id
GROUP BY co.name
ORDER BY avg_coverage DESC;

-- 3. Average coverage per vaccine
SELECT v.description AS vaccine_name, AVG(c.coverage_percent) AS avg_coverage
FROM coverage c
JOIN vaccine v ON c.vaccine_id = v.id
GROUP BY v.description
ORDER BY avg_coverage DESC;

-- 4. Coverage trends over time for a specific country (India)
SELECT c.year, v.description AS vaccine_name, c.coverage_percent
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
WHERE co.name = 'India'
ORDER BY c.year;

-- 5. Top 5 vaccines by average coverage per country
SELECT v.description AS vaccine_name, co.name AS country_name, AVG(c.coverage_percent) AS avg_coverage
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
GROUP BY v.description, co.name
ORDER BY v.description, avg_coverage DESC
LIMIT 5;

-- ============================================================
-- B. Incidence Over Time
-- ============================================================

-- 6. Incidence trend per disease
SELECT d.description AS disease_name, i.year, SUM(i.{incidence_col}) AS total_incidence
FROM incidence i
JOIN disease d ON i.disease_id = d.id
GROUP BY d.description, i.year
ORDER BY d.description, i.year;

-- 7. Incidence trend for India
SELECT d.description AS disease_name, i.year, i.{incidence_col}
FROM incidence i
JOIN disease d ON i.disease_id = d.id
JOIN country co ON i.country_id = co.id
WHERE co.name = 'India'
ORDER BY i.year;

-- 8. Total incidence by country
SELECT co.name AS country_name, SUM(i.{incidence_col}) AS total_incidence
FROM incidence i
JOIN country co ON i.country_id = co.id
GROUP BY co.name
ORDER BY total_incidence DESC;

-- ============================================================
-- C. Reported Cases
-- ============================================================

-- 9. Total reported cases by country
SELECT co.name AS country_name, SUM(rc.{reported_cases_col}) AS total_cases
FROM reported_cases rc
JOIN country co ON rc.country_id = co.id
GROUP BY co.name
ORDER BY total_cases DESC;

-- 10. Total reported cases by disease
SELECT d.description AS disease_name, SUM(rc.{reported_cases_col}) AS total_cases
FROM reported_cases rc
JOIN disease d ON rc.disease_id = d.id
GROUP BY d.description
ORDER BY total_cases DESC;

-- 11. Reported cases by country and disease
SELECT co.name AS country_name, d.description AS disease_name, SUM(rc.{reported_cases_col}) AS total_cases
FROM reported_cases rc
JOIN country co ON rc.country_id = co.id
JOIN disease d ON rc.disease_id = d.id
GROUP BY co.name, d.description
ORDER BY co.name, total_cases DESC;

-- 12. Coverage vs incidence for India
SELECT co.name AS country_name, v.description AS vaccine_name, c.coverage_percent, i.{incidence_col}
FROM coverage c
JOIN vaccine v ON c.vaccine_id = v.id
JOIN country co ON c.country_id = co.id
LEFT JOIN incidence i ON co.id = i.country_id
WHERE co.name = 'India';

-- 13. Average coverage and total incidence per country
SELECT co.name AS country_name, AVG(c.coverage_percent) AS avg_coverage, SUM(i.{incidence_col}) AS total_incidence
FROM coverage c
JOIN country co ON c.country_id = co.id
LEFT JOIN incidence i ON co.id = i.country_id
GROUP BY co.name
ORDER BY avg_coverage DESC;

-- 14. Coverage missing country_id or vaccine_id
SELECT * FROM coverage WHERE country_id IS NULL OR vaccine_id IS NULL;

-- 15. Incidence missing country_id or disease_id
SELECT * FROM incidence WHERE country_id IS NULL OR disease_id IS NULL;

-- 16. Vaccines with lowest average coverage
SELECT v.description AS vaccine_name, AVG(c.coverage_percent) AS avg_coverage
FROM coverage c
JOIN vaccine v ON c.vaccine_id = v.id
GROUP BY v.description
ORDER BY avg_coverage ASC;

-- 17. Diseases with highest incidence
SELECT d.description AS disease_name, SUM(i.{incidence_col}) AS total_incidence
FROM incidence i
JOIN disease d ON i.disease_id = d.id
GROUP BY d.description
ORDER BY total_incidence DESC;

-- 18. Measles reported cases by country
SELECT co.name AS country_name, SUM(rc.{reported_cases_col}) AS total_cases
FROM reported_cases rc
JOIN country co ON rc.country_id = co.id
JOIN disease d ON rc.disease_id = d.id
WHERE d.description = 'Measles'
GROUP BY co.name
ORDER BY total_cases DESC;

-- 19. Average coverage per year
SELECT c.year, AVG(c.coverage_percent) AS avg_coverage
FROM coverage c
GROUP BY c.year
ORDER BY c.year;

-- 20. Total incidence per year
SELECT i.year, SUM(i.{incidence_col}) AS total_incidence
FROM incidence i
GROUP BY i.year
ORDER BY i.year;

-- 21. Coverage-to-incidence ratio per country and vaccine
SELECT co.name AS country_name, v.description AS vaccine_name, AVG(c.coverage_percent) AS avg_coverage,
       SUM(i.{incidence_col}) AS total_incidence,
       (AVG(c.coverage_percent) / NULLIF(SUM(i.{incidence_col}),0)) AS coverage_to_incidence_ratio
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
LEFT JOIN incidence i ON co.id = i.country_id
GROUP BY co.name, v.description
ORDER BY coverage_to_incidence_ratio DESC;

-- 22. Coverage growth over years per country and vaccine
SELECT co.name AS country_name, v.description AS vaccine_name, c.year, AVG(c.coverage_percent) AS avg_coverage,
       (AVG(c.coverage_percent) - LAG(AVG(c.coverage_percent)) OVER (PARTITION BY co.name, v.description ORDER BY c.year)) AS coverage_growth
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
GROUP BY co.name, v.description, c.year
ORDER BY co.name, v.description, c.year;

-- 23. Average coverage and total reported cases per country and vaccine
SELECT co.name AS country_name, v.description AS vaccine_name, AVG(c.coverage_percent) AS avg_coverage,
       SUM(rc.{reported_cases_col}) AS total_cases
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
LEFT JOIN reported_cases rc ON co.id = rc.country_id
GROUP BY co.name, v.description
ORDER BY avg_coverage DESC;

-- 24. Missing coverage data count per country and vaccine
SELECT co.name AS country_name, v.description AS vaccine_name, COUNT(*) AS missing_data_count
FROM coverage c
JOIN country co ON c.country_id = co.id
JOIN vaccine v ON c.vaccine_id = v.id
WHERE c.coverage_percent IS NULL
GROUP BY co.name, v.description
ORDER BY missing_data_count DESC;

-- 25. Vaccine introduction timeline per country and vaccine
SELECT co.name AS country_name, v.description AS vaccine_name, MIN(vi.year) AS first_introduction,
       MAX(vi.year) AS last_introduction
FROM vaccine_introduction vi
JOIN country co ON vi.country_id = co.id
JOIN vaccine v ON vi.vaccine_id = v.id
GROUP BY co.name, v.description
ORDER BY first_introduction;
