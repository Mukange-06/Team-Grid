import pandas as pd

# Load dataset
df = pd.read_parquet(r"C:\Users\USER\Desktop\TEAM GRID\team_3.parquet")

# Preview data
print(df.head())

# Dataset information
print(df.info())

# Missing values
print(df.isnull().sum())

# Duplicate rows
print(df.duplicated().sum())

# Remove duplicates
df = df.drop_duplicates()

# Convert datetime
df['datetime'] = pd.to_datetime(df['datetime'])

# Standardize text
df['city'] = df['city'].str.strip().str.lower()
df['state'] = df['state'].str.strip().str.lower()
df['pollutant'] = df['pollutant'].str.strip().str.lower()

# Fill missing numeric values
numeric_cols = df.select_dtypes(include=['float64']).columns

df[numeric_cols] = df[numeric_cols].fillna(
    df[numeric_cols].median()
)

# Check remaining nulls
print(df.isnull().sum())

# Unique pollutants
print(df['pollutant'].unique())

# Save cleaned dataset
df.to_parquet(
    r"C:\Users\USER\Desktop\TEAM GRID\cleaned_air_quality.parquet",
    engine="pyarrow"
)

# Partition dataset
df.to_parquet(
    r"C:\Users\USER\Desktop\TEAM GRID\partitioned_output",
    engine="pyarrow",
    partition_cols=['year', 'month']
)

print("Data cleaning and partitioning completed successfully!")