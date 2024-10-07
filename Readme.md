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
harvest_excel_data_RV(
  input_directory = "path/to/input/folder",
  output_directory = "path/to/output/folder",
  file_name = "survey_data_2023"
)
```

### `process_catch_effort()`

This function processes catch and effort data from the harvested RV survey data.

#### Arguments

- `input_file`: Path to the input CSV file containing harvested RV data.
- `output_file`: Path where the processed catch and effort data will be saved.

#### Example

```R
process_catch_effort(
input_file = "path/to/output/folder/harvested_data.csv",
output_file = "path/to/output/folder/processed_catch_effort.csv"
)
```

## License
This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for more details.