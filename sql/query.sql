-- =====================================================
-- query.sql
-- PostgreSQL / pgvector compatible analytical queries
-- Project: Air Quality Analytics
-- =====================================================

-- =====================================================
-- 1. VIEW ALL TABLES
-- =====================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';


-- =====================================================
-- 2. CHECK TOTAL RECORDS
-- =====================================================

SELECT COUNT(*) AS total_measurements
FROM fact_air_quality;


-- =====================================================
-- 3. PREVIEW DATA
-- =====================================================

SELECT *
FROM fact_air_quality
LIMIT 10;


-- =====================================================
-- 4. JOIN FACT + DIMENSIONS
-- =====================================================

SELECT
    f.measurement_id,
    s.station_name,
    s.city,
    s.state,
    d.datetime,
    f.pollutant,
    f.value
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
JOIN dim_date d
    ON f.date_key = d.date_key
LIMIT 50;


-- =====================================================
-- 5. AVERAGE POLLUTION BY CITY
-- =====================================================

SELECT
    s.city,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.city
ORDER BY avg_pollution DESC;


-- =====================================================
-- 6. AVERAGE POLLUTION BY POLLUTANT
-- =====================================================

SELECT
    pollutant,
    AVG(value) AS avg_value
FROM fact_air_quality
GROUP BY pollutant
ORDER BY avg_value DESC;


-- =====================================================
-- 7. TOP 10 MOST POLLUTED STATIONS
-- =====================================================

SELECT
    s.station_name,
    s.city,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.station_name, s.city
ORDER BY avg_pollution DESC
LIMIT 10;


-- =====================================================
-- 8. POLLUTION TREND OVER TIME
-- =====================================================

SELECT
    d.year,
    d.month,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


-- =====================================================
-- 9. HOURLY POLLUTION ANALYSIS
-- =====================================================

SELECT
    d.hour,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.hour
ORDER BY d.hour;


-- =====================================================
-- 10. WEATHER VS AIR QUALITY
-- =====================================================

SELECT
    pollutant,
    AVG(at_c) AS avg_temperature,
    AVG(rh_percent) AS avg_humidity,
    AVG(ws_m_s) AS avg_wind_speed,
    AVG(value) AS avg_pollution
FROM fact_air_quality
GROUP BY pollutant
ORDER BY avg_pollution DESC;


-- =====================================================
-- 11. DAYS WITH HIGHEST POLLUTION
-- =====================================================

SELECT
    d.datetime,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.datetime
ORDER BY avg_pollution DESC
LIMIT 20;


-- =====================================================
-- 12. NULL VALUE CHECK
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE value IS NULL) AS null_value,
    COUNT(*) FILTER (WHERE pollutant IS NULL) AS null_pollutant,
    COUNT(*) FILTER (WHERE station_key IS NULL) AS null_station,
    COUNT(*) FILTER (WHERE date_key IS NULL) AS null_date
FROM fact_air_quality;


-- =====================================================
-- 13. FILTER SPECIFIC POLLUTANT
-- =====================================================

SELECT
    s.station_name,
    d.datetime,
    f.value
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
JOIN dim_date d
    ON f.date_key = d.date_key
WHERE f.pollutant = 'PM2.5'
ORDER BY f.value DESC
LIMIT 100;


-- =====================================================
-- 14. CREATE PERFORMANCE INDEXES
-- =====================================================

CREATE INDEX idx_fact_station
ON fact_air_quality(station_key);

CREATE INDEX idx_fact_date
ON fact_air_quality(date_key);

CREATE INDEX idx_fact_pollutant
ON fact_air_quality(pollutant);

CREATE INDEX idx_dim_city
ON dim_station(city);


-- =====================================================
-- 15. MATERIALIZED VIEW FOR FAST ANALYTICS
-- =====================================================

CREATE MATERIALIZED VIEW mv_city_pollution AS
SELECT
    s.city,
    f.pollutant,
    AVG(f.value) AS avg_pollution,
    COUNT(*) AS total_measurements
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.city, f.pollutant;


-- =====================================================
-- 16. QUERY MATERIALIZED VIEW
-- =====================================================

SELECT *
FROM mv_city_pollution
ORDER BY avg_pollution DESC;


-- =====================================================
-- 17. REFRESH MATERIALIZED VIEW
-- =====================================================

REFRESH MATERIALIZED VIEW mv_city_pollution;


-- =====================================================
-- 18. EXTREME WEATHER CONDITIONS
-- =====================================================

SELECT
    measurement_id,
    pollutant,
    value,
    at_c,
    rh_percent,
    ws_m_s
FROM fact_air_quality
WHERE at_c > 40
   OR ws_m_s > 20
   OR rh_percent > 95
ORDER BY value DESC;


-- =====================================================
-- 19. MONTHLY POLLUTION BY STATE
-- =====================================================

SELECT
    s.state,
    d.year,
    d.month,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY s.state, d.year, d.month
ORDER BY s.state, d.year, d.month;


-- =====================================================
-- 20. TOP POLLUTION SPIKES
-- =====================================================

SELECT
    s.station_name,
    d.datetime,
    f.pollutant,
    f.value
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
JOIN dim_date d
    ON f.date_key = d.date_key
ORDER BY f.value DESC
LIMIT 50;

-- =====================================================
-- ADVANCED ANALYTICS QUERIES
-- =====================================================


-- =====================================================
-- 21. DAILY AIR QUALITY INDEX TREND
-- =====================================================

SELECT
    DATE(d.datetime) AS day,
    AVG(f.value) AS avg_aqi
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY DATE(d.datetime)
ORDER BY day;


-- =====================================================
-- 22. WORST POLLUTANT PER CITY
-- =====================================================

SELECT DISTINCT ON (s.city)
    s.city,
    f.pollutant,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.city, f.pollutant
ORDER BY s.city, avg_pollution DESC;


-- =====================================================
-- 23. TOP CLEANEST STATIONS
-- =====================================================

SELECT
    s.station_name,
    s.city,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.station_name, s.city
ORDER BY avg_pollution ASC
LIMIT 10;


-- =====================================================
-- 24. POLLUTION VARIANCE ANALYSIS
-- =====================================================

SELECT
    pollutant,
    MIN(value) AS min_value,
    MAX(value) AS max_value,
    AVG(value) AS avg_value,
    STDDEV(value) AS std_dev
FROM fact_air_quality
GROUP BY pollutant
ORDER BY std_dev DESC;


-- =====================================================
-- 25. WEEKDAY VS WEEKEND ANALYSIS
-- =====================================================

SELECT
    CASE
        WHEN EXTRACT(DOW FROM d.datetime) IN (0,6)
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY day_type;


-- =====================================================
-- 26. RANK STATIONS BY POLLUTION
-- =====================================================

SELECT
    s.station_name,
    s.city,
    AVG(f.value) AS avg_pollution,
    RANK() OVER (
        ORDER BY AVG(f.value) DESC
    ) AS pollution_rank
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.station_name, s.city;


-- =====================================================
-- 27. MOVING AVERAGE POLLUTION
-- =====================================================

SELECT
    d.datetime,
    f.pollutant,
    AVG(f.value) OVER (
        PARTITION BY f.pollutant
        ORDER BY d.datetime
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
ORDER BY d.datetime;


-- =====================================================
-- 28. DETECT POLLUTION SPIKES
-- =====================================================

SELECT
    *
FROM (
    SELECT
        d.datetime,
        s.station_name,
        f.pollutant,
        f.value,
        AVG(f.value) OVER (
            PARTITION BY f.pollutant
        ) AS avg_pollution
    FROM fact_air_quality f
    JOIN dim_station s
        ON f.station_key = s.station_key
    JOIN dim_date d
        ON f.date_key = d.date_key
) t
WHERE value > avg_pollution * 2
ORDER BY value DESC;


-- =====================================================
-- 29. MOST ACTIVE STATIONS
-- =====================================================

SELECT
    s.station_name,
    COUNT(*) AS total_measurements
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.station_name
ORDER BY total_measurements DESC;


-- =====================================================
-- 30. YEARLY POLLUTION COMPARISON
-- =====================================================

SELECT
    d.year,
    pollutant,
    AVG(value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.year, pollutant
ORDER BY d.year, avg_pollution DESC;


-- =====================================================
-- 31. FIND MISSING DATE GAPS
-- =====================================================

SELECT
    d1.datetime AS current_date,
    d2.datetime AS next_date,
    d2.datetime - d1.datetime AS gap
FROM dim_date d1
JOIN dim_date d2
    ON d2.date_key = d1.date_key + 1
WHERE d2.datetime - d1.datetime > INTERVAL '1 day';


-- =====================================================
-- 32. CORRELATION BETWEEN WEATHER & POLLUTION
-- =====================================================

SELECT
    pollutant,
    CORR(value, at_c) AS temp_corr,
    CORR(value, rh_percent) AS humidity_corr,
    CORR(value, ws_m_s) AS wind_corr
FROM fact_air_quality
GROUP BY pollutant;


-- =====================================================
-- 33. PERCENTILE ANALYSIS
-- =====================================================

SELECT
    pollutant,
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY value) AS p25,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY value) AS median,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY value) AS p75,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY value) AS p95
FROM fact_air_quality
GROUP BY pollutant;


-- =====================================================
-- 34. HIGHEST POLLUTION MONTH PER YEAR
-- =====================================================

SELECT DISTINCT ON (d.year)
    d.year,
    d.month,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, avg_pollution DESC;


-- =====================================================
-- 35. STATION HEALTH SCORE
-- =====================================================

SELECT
    s.station_name,
    CASE
        WHEN AVG(f.value) <= 50 THEN 'Good'
        WHEN AVG(f.value) <= 100 THEN 'Moderate'
        WHEN AVG(f.value) <= 150 THEN 'Unhealthy for Sensitive Groups'
        WHEN AVG(f.value) <= 200 THEN 'Unhealthy'
        ELSE 'Hazardous'
    END AS health_status,
    AVG(f.value) AS avg_pollution
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.station_name
ORDER BY avg_pollution DESC;


-- =====================================================
-- 36. FIND DUPLICATE RECORDS
-- =====================================================

SELECT
    station_key,
    date_key,
    pollutant,
    COUNT(*) AS duplicate_count
FROM fact_air_quality
GROUP BY
    station_key,
    date_key,
    pollutant
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- =====================================================
-- 37. PARTITIONING STRATEGY
-- =====================================================

-- Useful for VERY LARGE datasets
-- Monthly partition example

CREATE TABLE fact_air_quality_2026_01
PARTITION OF fact_air_quality
FOR VALUES FROM ('2026-01-01')
TO ('2026-02-01');


-- =====================================================
-- 38. VECTOR SEARCH (pgvector)
-- =====================================================

-- Assuming embedding column exists:
-- embedding VECTOR(384)

SELECT
    measurement_id,
    pollutant,
    value
FROM fact_air_quality
ORDER BY embedding <-> '[0.12, 0.55, 0.91, 0.33]'
LIMIT 5;


-- =====================================================
-- 39. CREATE VECTOR INDEX
-- =====================================================

CREATE INDEX idx_embedding_vector
ON fact_air_quality
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);


-- =====================================================
-- 40. HYBRID FILTER + VECTOR SEARCH
-- =====================================================

SELECT
    measurement_id,
    pollutant,
    value
FROM fact_air_quality
WHERE pollutant = 'PM2.5'
ORDER BY embedding <-> '[0.12, 0.55, 0.91, 0.33]'
LIMIT 10;


-- =====================================================
-- 41. FULL TEXT SEARCH
-- =====================================================

ALTER TABLE fact_air_quality
ADD COLUMN search_vector tsvector;

UPDATE fact_air_quality
SET search_vector =
    to_tsvector(
        COALESCE(pollutant, '') || ' ' ||
        COALESCE(CAST(value AS TEXT), '')
    );

CREATE INDEX idx_search_vector
ON fact_air_quality
USING GIN(search_vector);


-- =====================================================
-- 42. TEXT SEARCH QUERY
-- =====================================================

SELECT
    measurement_id,
    pollutant,
    value
FROM fact_air_quality
WHERE search_vector @@ plainto_tsquery('PM2.5');


-- =====================================================
-- 43. CACHE HOT QUERIES
-- =====================================================

CREATE MATERIALIZED VIEW mv_monthly_summary AS
SELECT
    d.year,
    d.month,
    pollutant,
    AVG(value) AS avg_pollution,
    MAX(value) AS max_pollution,
    MIN(value) AS min_pollution
FROM fact_air_quality f
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY d.year, d.month, pollutant;


-- =====================================================
-- 44. REFRESH CACHE
-- =====================================================

REFRESH MATERIALIZED VIEW mv_monthly_summary;


-- =====================================================
-- 45. SYSTEM PERFORMANCE CHECK
-- =====================================================

EXPLAIN ANALYZE
SELECT
    s.city,
    AVG(f.value)
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
GROUP BY s.city;


-- =====================================================
-- 46. TABLE SIZE ANALYSIS
-- =====================================================

SELECT
    pg_size_pretty(
        pg_total_relation_size('fact_air_quality')
    ) AS total_size;


-- =====================================================
-- 47. INDEX USAGE STATS
-- =====================================================

SELECT
    relname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;


-- =====================================================
-- 48. VACUUM & ANALYZE
-- =====================================================

VACUUM ANALYZE fact_air_quality;


-- =====================================================
-- 49. FIND OUTLIERS USING Z-SCORE
-- =====================================================

WITH stats AS (
    SELECT
        AVG(value) AS mean,
        STDDEV(value) AS stddev
    FROM fact_air_quality
)
SELECT
    f.measurement_id,
    f.pollutant,
    f.value
FROM fact_air_quality f,
     stats s
WHERE ABS((f.value - s.mean) / s.stddev) > 3
ORDER BY value DESC;


-- =====================================================
-- 50. REAL-TIME DASHBOARD QUERY
-- =====================================================

SELECT
    s.city,
    f.pollutant,
    AVG(f.value) AS avg_pollution,
    MAX(f.value) AS peak_pollution,
    COUNT(*) AS readings
FROM fact_air_quality f
JOIN dim_station s
    ON f.station_key = s.station_key
JOIN dim_date d
    ON f.date_key = d.date_key
WHERE d.datetime >= NOW() - INTERVAL '24 hours'
GROUP BY s.city, f.pollutant
ORDER BY avg_pollution DESC;