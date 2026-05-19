import pandas as pd

# =========================================================
# PROJECT DATA PATH
# =========================================================
# CHANGE ONLY THIS PATH IF YOUR DATASET LOCATION CHANGES
# =========================================================

DATA_PATH = r"C:\Users\USER\Desktop\TEAM GRID\team_3.parquet"

# =========================================================
# LOAD DATASET
# =========================================================
# Reads the parquet dataset into a pandas DataFrame
# =========================================================

df = pd.read_parquet(DATA_PATH)

# =========================================================
# PREVIEW FIRST 5 ROWS
# =========================================================
# Helps us inspect the dataset structure and contents
# =========================================================

print(df.head())

# =========================================================
# DISPLAY DATASET INFORMATION
# =========================================================
# Shows:
# - number of rows and columns
# - datatype of each column
# - memory usage
# - non-null values
# =========================================================

print(df.info())

# =========================================================
# CHECK MISSING VALUES
# =========================================================
# Counts null/missing values in each column
# =========================================================

print(df.isnull().sum())

# =========================================================
# CHECK DUPLICATE ROWS
# =========================================================
# Identifies repeated rows in the dataset
# =========================================================

print(df.duplicated().sum())

# =========================================================
# REMOVE DUPLICATE ROWS
# =========================================================
# Keeps only unique records
# =========================================================

df = df.drop_duplicates()

# =========================================================
# CONVERT DATETIME COLUMN
# =========================================================
# Ensures datetime column is stored in proper datetime format
# Useful for:
# - filtering
# - time-series analysis
# - partitioning
# =========================================================

df['datetime'] = pd.to_datetime(df['datetime'])

# =========================================================
# STANDARDIZE TEXT COLUMNS
# =========================================================
# Removes unnecessary spaces and converts text to lowercase
# Helps maintain consistency in queries and analysis
# =========================================================

df['city'] = df['city'].str.strip().str.lower()
df['state'] = df['state'].str.strip().str.lower()
df['pollutant'] = df['pollutant'].str.strip().str.lower()

# =========================================================
# HANDLE MISSING NUMERIC VALUES
# =========================================================
# Selects numeric columns and fills missing values
# using the median of each column
#
# Median is preferred because environmental data
# may contain outliers
# =========================================================

numeric_cols = df.select_dtypes(include=['float64']).columns

df[numeric_cols] = df[numeric_cols].fillna(
    df[numeric_cols].median()
)

# =========================================================
# VERIFY REMAINING MISSING VALUES
# =========================================================
# Confirms whether cleaning was successful
# =========================================================

print(df.isnull().sum())

# =========================================================
# DISPLAY UNIQUE POLLUTANTS
# =========================================================
# Helps identify pollutant categories and detect inconsistencies
# =========================================================

print(df['pollutant'].unique())

# =========================================================
# SAVE CLEANED DATASET
# =========================================================
# Stores the cleaned dataset as a parquet file
# =========================================================

df.to_parquet(
    "cleaned_air_quality.parquet",
    engine="pyarrow"
)

# =========================================================
# PARTITION DATASET
# =========================================================
# Organizes data into folders based on:
# - year
# - month
#
# Example structure:
#
# partitioned_output/
#    year=2024/
#       month=1/
#
# Partitioning improves query and retrieval performance
# =========================================================

df.to_parquet(
    "partitioned_output",
    engine="pyarrow",
    partition_cols=['year', 'month']
)

# =========================================================
# SUCCESS MESSAGE
# =========================================================

print("Data cleaning and partitioning completed successfully!")