# FisheryDataConverter

## Description

FisheryDataConverter is an R package designed to facilitate the harvesting and processing of fishery data from Excel files. It provides tools for data manipulation, tidying, and file operations, specifically tailored for Research Vessel (RV) survey data including catch and effort information.

## Installation

You can install the FisheryDataConverter package directly from GitHub using the `devtools` package:

```R
devtools::install_github("jporobicg/FisheryDataConverter")
```

## Usage

The package provides several functions to process and convert fishery data from Excel files. Here are some key functions:

### `harvest_excel_data_RV()`

This function is used to process Research Vessel (RV) data. It reads an Excel file containing RV survey data, performs necessary data tidying, and saves the processed data to CSV files.

#### Arguments

- `input_directory`: The directory containing the input Excel file.
- `output_directory`: The directory where processed CSV files will be saved.
- `file_name`: The name of the input Excel file (without extension).

#### Example

```R
# Set common directories
base_directory <- "path/to/base/directory"
input_directory <- base_directory
output_directory <- file.path(base_directory, "processed_data")

# Process Research Vessel (RV) data
rv_file_name <- "rv_survey_data.xlsx"
harvest_excel_data_RV(input_directory, output_directory, rv_file_name)
```

### `process_catch_effort()`

This function processes catch and effort data from the harvested RV survey data.

#### Arguments

- `input_file`: Path to the input CSV file containing harvested RV data.
- `output_file`: Path where the processed catch and effort data will be saved.

#### Example

```R
# Process catch and effort data
stat_file_name <- "database_catch_effort.xlsx"
harvest_excel_data_stat(input_directory, stat_file_name, output_directory)
```

## License
This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for more details.