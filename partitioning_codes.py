import pandas as pd
df = pd.read_parquet(r"C:\Users\User\OneDrive\Desktop\Assignment\team_3.parquet")
print(df.head(5))
print(df.describe())
x=df['year']
print(x.unique())
print(df.info())


# Assuming your loaded DataFrame is named 'df'

# Save the DataFrame to a folder named 'output_data', partitioned by year and month
df.to_parquet(
    'output_data', 
    engine='pyarrow', 
    partition_cols=['year', 'month'],
    index=False # Drops the RangeIndex to save space since it's just sequential numbers
)
# Point read_parquet directly to the main folder
df_all = pd.read_parquet('output_data')

print(df_all.head(5))