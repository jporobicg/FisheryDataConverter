#' Read a sheet from an Excel file
#'
#' @param excel_file Path to the Excel file
#' @param sheet_name Name of the sheet to read
#' @param stat_data If TRUE, all columns are read as text. Default is FALSE.
#' @return A data frame containing the data from the specified Excel sheet
#' @export
#' @importFrom readxl read_excel
read_sheet <- function(excel_file, sheet_name, stat_data = FALSE) {
    if (stat_data) {
        sheet_data <- read_excel(excel_file, sheet = sheet_name, col_types = "text")
    } else {
        sheet_data <- read_excel(excel_file, sheet = sheet_name)
    }
    return(sheet_data)
}


# #' Thai-English Name Lookup Table
# #'
# #' A dataset containing translations between Thai and English names for fishery-related terms.
# #'
# #' @format A data frame with 2 columns and multiple rows:
# #' \describe{
# #'   \item{thai_name}{character. The term in Thai language.}
# #'   \item{english_name}{character. The corresponding English translation.}
# #' }
# #' @details This lookup table is used for translating column names and other 
# #'   fishery-related terms from Thai to English within the package functions.
# #' @note The number of rows in this dataset may change as more terms are added or updated.
# #' @source Compiled by the FisheryDataConverter package authors based on 
# #'   standard fishery terminology used in Thailand and international conventions.
# #' @export
# "thai_english_name_lookup.csv"



