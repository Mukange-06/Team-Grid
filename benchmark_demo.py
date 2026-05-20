import pandas as pd
import time

# =========================================================
# LOAD CLEANED DATA
# =========================================================
# Using raw string for the file path to prevent escape sequence issues
data = pd.read_parquet(r"C:\Users\USER\Desktop\TEAM GRID\cleaned_air_quality.parquet")

# Ensure timestamps are uniform Datetime objects globally right at the start
data['timestamp'] = pd.to_datetime(data['timestamp'], utc=True)

# =========================================================
# CREATE STAR SCHEMA
# =========================================================

# ---------------- DIMENSION TABLES ----------------

dim_station = data[
    ['station_id', 'state', 'city', 'station_name']
].drop_duplicates().reset_index(drop=True)

dim_station['station_key'] = dim_station.index + 1

# --------------------------------------------------

# ---------------- DATE DIMENSION ------------------

dim_date = pd.DataFrame({
    'timestamp': data['timestamp']
})

dim_date['date'] = dim_date['timestamp'].dt.date
dim_date['year'] = dim_date['timestamp'].dt.year
dim_date['month'] = dim_date['timestamp'].dt.month
dim_date['day'] = dim_date['timestamp'].dt.day

dim_date = dim_date.drop_duplicates().reset_index(drop=True)

dim_date['date_key'] = dim_date.index + 1

# --------------------------------------------------

# ---------------- FACT TABLE ----------------------

fact_air_quality = data.merge(
    dim_station,
    on=['station_id', 'state', 'city', 'station_name'],
    how='left'
).merge(
    dim_date[['timestamp', 'date_key']],
    on='timestamp',
    how='left'
)

fact_air_quality = fact_air_quality[[
    'station_key',
    'date_key',
    'pollutant',
    'value',
    'at_c',
    'rh_percent',
    'ws_m_s',
    'rf_mm',
    'bp_mmhg'
]]

# =========================================================
# CREATE WIDE TABLE FOR COMPARISON (Denormalized Long Table)
# =========================================================
# To keep row counts equal, the wide table retains its long shape
# but keeps all descriptive metadata inline without indexing or pivoting.
wide_df = data.copy()


# =========================================================
# BENCHMARK FUNCTION
# =========================================================

def benchmark(label, func):
    start = time.time()
    result = func()
    end = time.time()

    duration = (end - start) * 1000

    if hasattr(result, '__len__'):
        rows = len(result)
    else:
        rows = "N/A"

    print(f"{label:<55} {duration:>10.2f} ms   {rows:>10}")
    return result

# =========================================================
# BENCHMARK TESTS
# =========================================================

print("\n")
print("=" * 90)
print(f"{'QUERY':<55} {'TIME':>10}   {'ROWS':>10}")
print("=" * 90)

# =========================================================
# QUERY 1 — FILTER BY CITY
# =========================================================

city = 'Delhi'

benchmark(
    "[STAR] Filter by city using dimension join",
    lambda: fact_air_quality.merge(
        dim_station[['station_key', 'city']],
        on='station_key'
    ).query("city == @city")
)

benchmark(
    "[WIDE] Filter by city",
    lambda: wide_df[wide_df['city'] == city]
)

print()

# =========================================================
# QUERY 2 — FILTER BY MONTH
# =========================================================

month = 6

benchmark(
    "[STAR] Filter by month using dim_date",
    lambda: fact_air_quality.merge(
        dim_date[['date_key', 'month']],
        on='date_key'
    ).query("month == @month")
)

benchmark(
    "[WIDE] Filter by month",
    lambda: wide_df[wide_df['timestamp'].dt.month == month]
)

print()

# =========================================================
# QUERY 3 — AVG TEMPERATURE PER CITY
# =========================================================

benchmark(
    "[STAR] Average temperature per city",
    lambda: fact_air_quality.merge(
        dim_station[['station_key', 'city']],
        on='station_key'
    ).groupby('city')['at_c'].mean()
)

benchmark(
    "[WIDE] Average temperature per city",
    lambda: wide_df.groupby('city')['at_c'].mean()
)

print()

# =========================================================
# QUERY 4 — PM25 ANALYSIS
# =========================================================

benchmark(
    "[STAR] PM2.5 pollutant lookup",
    lambda: fact_air_quality[
        fact_air_quality['pollutant'] == 'pm25'
    ]
)

benchmark(
    "[WIDE] PM2.5 lookup",
    lambda: wide_df[wide_df['pollutant'] == 'pm25']
)

print()

# =========================================================
# QUERY 5 — YEARLY AGGREGATION
# =========================================================

benchmark(
    "[STAR] Average pollution by year",
    lambda: fact_air_quality.merge(
        dim_date[['date_key', 'year']],
        on='date_key'
    ).groupby('year')['value'].mean()
)

benchmark(
    "[WIDE] Average pollution by year",
    lambda: wide_df.groupby(
        wide_df['timestamp'].dt.year
    )['value'].mean()
)

print()
print("=" * 90)

# =========================================================
# STORAGE / REDUNDANCY ANALYSIS
# =========================================================

print("\n")
print("=" * 90)
print("STORAGE AND REDUNDANCY ANALYSIS")
print("=" * 90)

# ---------------------------------------------------------
# MEMORY USAGE
# ---------------------------------------------------------

star_memory = (
    dim_station.memory_usage(deep=True).sum() +
    dim_date.memory_usage(deep=True).sum() +
    fact_air_quality.memory_usage(deep=True).sum()
)

wide_memory = wide_df.memory_usage(deep=True).sum()

print(f"\nStar Schema Total Memory Usage : {star_memory / (1024**2):.2f} MB")
print(f"Wide Table Memory Usage        : {wide_memory / (1024**2):.2f} MB")

# ---------------------------------------------------------
# REDUNDANCY ANALYSIS
# ---------------------------------------------------------

print("\n")
print("-" * 90)

station_duplicates_wide = wide_df[
    ['station_id', 'state', 'city', 'station_name']
].duplicated().sum()

station_duplicates_star = dim_station[
    ['station_id', 'state', 'city', 'station_name']
].duplicated().sum()

print(f"Repeated station metadata in Wide Table : {station_duplicates_wide}")
print(f"Repeated station metadata in Star Schema: {station_duplicates_star}")

# ---------------------------------------------------------
# UNIQUE DIMENSION COUNTS
# ---------------------------------------------------------

print("\n")
print("-" * 90)

print(f"Unique Stations : {len(dim_station)}")
print(f"Unique Dates    : {len(dim_date)}")
print(f"Fact Records    : {len(fact_air_quality)}")

# ---------------------------------------------------------
# COLUMN COUNT COMPARISON
# ---------------------------------------------------------

print("\n")
print("-" * 90)

print(f"Wide Table Columns : {len(wide_df.columns)}")
print(f"Fact Table Columns : {len(fact_air_quality.columns)}")

# ---------------------------------------------------------
# DATA ORGANIZATION SUMMARY
# ---------------------------------------------------------

print("\n")
print("-" * 90)

print("Star Schema Structure:")
print("  - Fact table stores measurements")
print("  - Dimension tables store descriptive attributes")
print("  - Reduces repeated metadata")
print("  - Improves maintainability")

print("\nWide Table Structure:")
print("  - All data stored together")
print("  - Faster simple reads")
print("  - Higher metadata repetition")
print("  - Less scalable for enterprise warehousing")

print("\n")
print("=" * 90)