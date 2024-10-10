#' Harvest Excel data from Research Vessel (RV) surveys and save as CSV files
#'
#' This function processes an Excel file containing Research Vessel (RV) survey data,
#' including catch and effort information. It reads the data, processes it, and saves
#' the results as CSV files.
#'
#' @param input_directory Character string. Directory containing the input Excel file.
#' @param file_name Character string. Name of the Excel file to process.
#' @param output_directory Character string. Directory where CSV files will be saved.
#'
#' @details
#' The function assumes the Excel file has two worksheets:
#' 1. "catch": Contains catch data
#' 2. "effort": Contains effort data
#'
#' It processes these worksheets and creates the following CSV files:
#' - length_info.csv: Expanded length information
#' - species_info.csv: Species information
#' - RV_catch_info.csv: Catch information
#' - rv_effort_info.csv: Effort information
#' - rv_info.csv: Research vessel information
#'
#' @export
#'
#' @importFrom readxl read_excel
#' @importFrom dplyr %>% rename select mutate rename_with slice full_join
#' @importFrom readr type_convert
#' @importFrom utils write.csv
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' harvest_excel_data_RV("path/to/input", "rv_data.xlsx", "path/to/output")
#' }
harvest_excel_data_RV <- function(input_directory, file_name, output_directory) {
    excel_file <- file.path(input_directory, file_name)
    if (!file.exists(excel_file)) {
        stop(paste("File not found:", excel_file))
    }

    # Process catch data
    rv_catch <- read_sheet(excel_file, "catch", stat_data = TRUE) %>%
        suppressMessages(type_convert()) %>%
        rename(freq_raw = .data$`Freqtext(raw)`, freq_rise = .data$`Freqtext(raise)`)

    species_info <- rv_catch %>%
        select(.data$IdSPP, .data$codename) %>%
        unique() %>%
        rename(species_id = .data$IdSPP, species_name = .data$codename)

    sampling_info <- rv_catch %>%
        select(.data$link, .data$Station, .data$IdSPP, .data$Size, .data$sex, .data$Number, .data$SamW, .data$Tot_Weight) %>%
        rename(sample_id = .data$link, station = .data$Station, species_id = .data$IdSPP,
               cod_cover = .data$Size, sex = .data$sex, sample_weight = .data$SamW, total_weight = .data$Tot_Weight)

    length_info <- rv_catch %>%
        select(.data$link, .data$IdSPP, .data$freq_raw, .data$freq_rise)

    # get the number of batch to run 
    size_batch <- 1000
    total_row <- nrow(length_info)
    n_batch <- ceiling(total_row / size_batch)
    temp_dir <- tempdir()

    pb_length <- txtProgressBar(min = 0, max = n_batch, style = 3)
    for(i in seq_len(n_batch)) {
        setTxtProgressBar(pb_length, i)
        start_row <- (i - 1) * size_batch + 1
        end_row <- min(i * size_batch, total_row)
        expanded_batch <- expand_length_info(length_info[start_row:end_row, ]) %>%
            rename(sample_id = .data$link, species_id = .data$IdSPP, 
                   original_raw_frequency = .data$freq_raw,
                   original_raised_frequency = .data$freq_rise)
        
        # Save each batch to a temporary CSV file
        temp_file <- file.path(temp_dir, paste0("batch_", i, ".csv"))
        write.csv(expanded_batch, temp_file, row.names = FALSE)
    }
    close(pb_length)
      # Combine all batches
    temp_files <- list.files(temp_dir, pattern = "^batch_.*\\.csv$", full.names = TRUE)
    expanded_length_info <- data.table::rbindlist(lapply(temp_files, data.table::fread))

    # Write catch-related CSVs
    write.csv(expanded_length_info, file.path(output_directory, "length_info.csv"), row.names = FALSE)
    write.csv(species_info, file.path(output_directory, "species_info.csv"), row.names = FALSE)
    write.csv(sampling_info, file.path(output_directory, "RV_catch_info.csv"), row.names = FALSE)

    # Clear catch-related objects from memory
    rm(rv_catch, species_info, sampling_info, length_info, expanded_length_info)
    gc()
    cat("Harvesting of catch data completed.\n")

    # Process effort data
    rv_effort <- read_sheet(excel_file, "effort", stat_data = TRUE) %>%
        suppressMessages(type_convert())

    rv_effort_info <- rv_effort %>%
        select(-.data$Zone, -.data$VesselName) %>%
        rename(sample_id = .data$link, center_id = .data$office, rv_area_id = .data$Area, time_deply = .data$Time, towing_time = .data$Tow) %>%
        rename_with(tolower)

    rv_info <- rv_effort %>%
        select(.data$office, .data$VesselName) %>%
        rename(center_id = .data$office, rv_name = .data$VesselName) %>%
        unique()

    # Write effort-related CSVs
    write.csv(rv_effort_info, file.path(output_directory, "rv_effort_info.csv"), row.names = FALSE)
    write.csv(rv_info, file.path(output_directory, "rv_info.csv"), row.names = FALSE)

    cat("Harvesting of effort data completed.\n")
}


#' Harvest Excel data from statistical catch and effort sheets and save as CSV files
#'
#' @param input_directory Directory containing the input Excel file
#' @param file_name Name of the Excel file to process
#' @param output_directory Directory where CSV files will be saved
#'
#' @details
#' This function processes an Excel file containing statistical catch and effort data.
#' It assumes the Excel file has two worksheets: 'catch' and 'effort'.
#' The function reads these worksheets, processes the data, and saves the results as CSV files.
#'
#' @return None. The function saves processed data as CSV files in the output directory.
#'
#' @export
#' @importFrom rlang .data %||%
#' @importFrom dplyr row_number rename_with everything
#' @importFrom utils read.csv
#' @importFrom stats setNames
harvest_excel_data_stat <- function(input_directory, file_name, output_directory) {
    # Load the column translation lookup table from the package
    lookup_file <- system.file("extdata", "thai_english_name_lookup.csv", package = "FisheryDataConverter")
    column_translations <- read.csv(lookup_file, stringsAsFactors = FALSE, fill = TRUE)
    
    # Create a named vector for easy lookup
    translation_lookup <- setNames(column_translations$english_name, column_translations$thai_name)
    reverse_lookup     <- setNames(column_translations$thai_name, column_translations$english_name)
    
    excel_file <- file.path(input_directory, file_name)
    if (!file.exists(excel_file)) {
        stop(paste("File not found:", excel_file))
    }

    # Process catch data
    stat_catch <- read_sheet(excel_file, "catch", stat_data = TRUE) %>%
        suppressMessages(type_convert())

    # tolower the names and then rename columns using the translation lookup
    stat_catch <- stat_catch %>%
    rename_with(tolower) %>%
    rename_with(~ ifelse(is.na(translation_lookup[.x]), .x, translation_lookup[.x]), .cols = everything())

    species_info <- stat_catch %>% 
        rename(Species_group = .data$group_species)
        
    names(stat_catch)
    stat_info_catch <- stat_catch %>% 
        select(.data$yearAD, .data$yearBE, .data$month, .data$month_thai, .data$gear_group_thai2, .data$gear_group_eng, .data$vessel_size_thai, .data$vessel_class, .data$stat_area, .data$fishing_sector) %>% 
        unique() %>%
        mutate(stat_record_ids = seq_len(nrow(.)))

    df_combined_catch <- suppressMessages(full_join(stat_info_catch, stat_catch))

    catch_info <- df_combined_catch %>%
        select(.data$stat_record_ids, .data$stat_name_code, .data$stat_yield_t)

    write.csv(species_info, file.path(output_directory, "stat_species_info.csv"), row.names = FALSE)
    write.csv(catch_info, file.path(output_directory, "stat_catch_info.csv"), row.names = FALSE)

    rm(stat_catch, species_info, df_combined_catch, catch_info)
    gc()
    cat("Harvesting of Catch data completed\n")

    # Process effort data
    stat_effort <- read_sheet(excel_file, "effort", stat_data = TRUE) %>%
        suppressMessages(type_convert())

    stat_effort <- stat_effort %>%
        rename_with(tolower) %>%
        rename_with(~ ifelse(is.na(translation_lookup[.x]), .x, translation_lookup[.x]), .cols = everything())
 
    stat_area_info <- stat_effort %>% 
        select(.data$stat_area, .data$area_gotand, .data$in_out) %>% 
        unique()


    stat_info_effort <- stat_effort %>% 
        select(.data$yearAD, .data$yearBE, .data$month, .data$month_thai, .data$gear_group_thai2, .data$gear_group_eng, .data$vessel_size_thai, .data$vessel_class, .data$stat_area, .data$fishing_sector) %>% 
        unique()

    stat_info <- suppressMessages(full_join(stat_info_catch, stat_info_effort) %>%
                                  mutate(stat_record_ids = row_number()))

    df_combined_effort <- suppressMessages(full_join(stat_info, stat_effort))

    effort_info <- df_combined_effort %>%
        select(.data$stat_record_ids, .data$effort_trip, .data$effort_day, .data$effort_haulset, .data$effort_hour) %>%
        filter(!is.na(.data$effort_trip) | !is.na(.data$effort_day) | !is.na(.data$effort_haulset) | !is.na(.data$effort_hour))

    stat_info <- stat_info %>%
        rename_with(~ ifelse(is.na(reverse_lookup[.x]), .x, reverse_lookup[.x]), .cols = everything())

    write.csv(stat_area_info, file.path(output_directory, "stat_area_info.csv"), row.names = FALSE)
    write.csv(stat_info, file.path(output_directory, "stat_info.csv"), row.names = FALSE)
    write.csv(effort_info, file.path(output_directory, "stat_effort_info.csv"), row.names = FALSE)

    cat("Harvesting of Effort data completed\n")
}
