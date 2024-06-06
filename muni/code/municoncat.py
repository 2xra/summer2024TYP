import pandas as pd
import os

# Folder containing Excel files
input_folder = r"C:\Users\rra3\Desktop\summer2024TYP\muni\data\bonds\sources\\"
# New location to save the combined Excel file
output_folder = r'C:\Users\rra3\Desktop\summer2024TYP\muni\data\bonds\\'
# Name of the combined Excel file
output_filename = "combined_file.xlsx"

# Function to process each file
def process_excel_file(file_path, skip_rows):
    # Read Excel file
    df = pd.read_excel(file_path)
    # Drop rows
    df = df.iloc[skip_rows:]
    return df

# Get list of all Excel files in the input folder
excel_files = [f for f in os.listdir(input_folder) if f.endswith('.xlsx')]

# Read and process the first file
first_file = os.path.join(input_folder, excel_files[0])
first_df = process_excel_file(first_file, 1) # skip first two rows

# Process and append other files
for file in excel_files[1:]:
    file_path = os.path.join(input_folder, file)
    df = process_excel_file(file_path, 2) # skip first three rows
    first_df = first_df._append(df, ignore_index=True) # Use _append instead of append

# Save the combined file to the output folder
output_path = os.path.join(output_folder, output_filename)
first_df.to_excel(output_path, index=False)

print("Combined Excel file saved to:", output_path)
print("remember to remove the first row")