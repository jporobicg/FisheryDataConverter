#' Expand length information from aggregated data
#'
#' This function takes aggregated length information and expands it into a detailed dataframe,
#' processing both raw and raised frequency data.
#'
#' @param length_info A dataframe containing aggregated length information with columns:
#'   link, IdSPP, freq_raw, and freq_rise.
#'
#' @return A dataframe with expanded length information, including raw and raised
#'   frequencies for each length class.
#'
#' @export
#'
#' @importFrom dplyr %>% rename slice bind_cols filter
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @importFrom rlang .data
#' @importFrom dplyr %>% rename slice bind_cols filter
#' @importFrom utils setTxtProgressBar txtProgressBar
expand_length_info <- function(length_info) {
    new_df <- data.frame()
    tot <- nrow(length_info)
    pb <- txtProgressBar(min = 0, max = tot, style = 3)
    
    for(dp in 1:tot){
        setTxtProgressBar(pb, dp)        
        if(is.na(length_info[dp,]$freq_raw)){
            temp_df <- cbind(length_info[dp,], NA, NA, NA, NA)
            names(temp_df) <- c('link', 'IdSPP', 'freq_raw', 'freq_rise', 'raw_length', 'raw_frequency', 'raised_length', 'raised_frequency')
        } else {
            raw_freq <- get_freq_values(length_info[dp,]$freq_raw) %>% 
                rename(raw_frequency = .data$frequency, raw_length = .data$size)
            raised_freq <- get_freq_values(length_info[dp,]$freq_rise) %>% 
                rename(raised_frequency = .data$frequency, raised_length = .data$size)
            
            repeated_row <- length_info[dp, ] %>%
                slice(rep(1:nrow(.), each = nrow(raw_freq)))
            
            if(nrow(raw_freq) != nrow(raised_freq)) {
                warning(paste("Mismatch in raw and raised frequency rows at index", dp))
                next
            }            
            temp_df <- bind_cols(repeated_row, raw_freq, raised_freq)
        }
        new_df <- rbind(new_df, temp_df)
    }    
    close(pb)    
    new_df %>%
        filter(!is.na(.data$raw_frequency) & !is.na(.data$raised_frequency))
    return(new_df)
}

#' Transform frequency text into separate rows
#'
#' This function takes a string containing frequency data in a specific format and
#' transforms it into a data frame with size and frequency information.
#'
#' @param sample_freq A string containing frequency data in the format:
#'   "width,min_length,freq1,freq2,...(size,freq)..."
#'
#' @return A data frame with two columns:
#'   \itemize{
#'     \item size: numeric, representing the size class
#'     \item frequency: numeric, representing the frequency for each size class
#'   }
#'
#' @export
#'
#' @examples
#' get_freq_values("0.5,7.5,1,2,1")
#' get_freq_values("0.5,7.5,1,+10,2")
get_freq_values <- function(sample_freq) {
    sample_freq <- unlist(strsplit(sample_freq, ","))
    width <- as.numeric(sample_freq[1])
    min_length <- as.numeric(sample_freq[2])

    if (any(grepl("\\+", sample_freq))) {
        plus_indices <- which(grepl("\\+", sample_freq))
        max_size <- max(as.numeric(sub("\\+", "", sample_freq[plus_indices])))
        sizes <- seq(from = min_length, by = width, to = max_size)
        frequency <- numeric(length(sizes))
        
        for (i in seq_along(plus_indices)) {
            current_index <- plus_indices[i]
            increase_value <- as.numeric(sub("\\+", "", sample_freq[current_index]))
            if (i == 1 && current_index > 3) {
                first_frequency <- as.numeric(sample_freq[3:(current_index - 1)])
                frequency[1:length(first_frequency)] <- first_frequency
            }
            frequency[which(sizes == increase_value)] <- as.numeric(sample_freq[current_index + 1])
        }
    } else {
        frequency <- as.numeric(sample_freq[3:length(sample_freq)])
        sizes <- seq(from = min_length, by = width, length.out = length(frequency))
    }
    result <- data.frame(size = sizes, frequency = frequency)
    result <- result[result$frequency > 0, ]
    return(result)
}