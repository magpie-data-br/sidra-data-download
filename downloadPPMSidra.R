#' Download Agricultural Data from SIDRA API (PPM) for Multiple Municipalities
#'
#' This function downloads data related to livestock inventory from IBGE's SIDRA API (PPM) 
#' for a predefined list of municipalities. The data covers the period from 1998 onwards.
#'
#' @param year_list A vector of integers representing the years for which data will be retrieved (e.g., c(1998, 2000, 2005) or year_list <- seq(from = start_year, to = end_year, by = 1)). As of November 2024, the latest year with available PAM data is 2023.
#'
#' @return A data.table containing the livestock data for all municipalities.
#' @examples
#' #' sidra_data <- downloadPPMSidra(1998) 
#' sidra_data <- downloadPPMSidra(c(1998,2002))
#' yearlist <- seq(from = 2000, to = 2020, by = 5)
#' sidra_data <- downloadPPMSidra(yearlist) 
#' head(sidra_data)
#'

# Load the municipality codes from an RDS file
# Ensure this file contains valid municipality codes for the analysis
cd_mun <- readRDS("data/br_cd_mun.rds")

downloadPPMSidra <- function(year_list) {
  
  # Validate if 'year_list' is a numeric vector of integers
  if (!is.numeric(year_list) || any(year_list != as.integer(year_list))) {
    stop("The 'year_list' parameter must be a numeric vector of integers.")
  }
  
  # Validate the range of years
  valid_years <- 1998:2023
  if (any(!year_list %in% valid_years)) {
    stop("All years in 'year_list' must be within the range 1998 to 2023.")
  }
  
  # Remove duplicates and issue a warning, if necessary
  if (length(year_list) != length(unique(year_list))) {
    warning("Duplicate years were removed from 'year_list'.")
    year_list <- unique(year_list)
  }
  
  # Check if the year list is not empty
  if (length(year_list) == 0) {
    stop("'year_list' cannot be empty. Please provide at least one valid year.")
  }
  
  # Initialize a list to store data.tables for all years
  list_of_data <- list()
  
  # Define the maximum number of municipalities per API request
  max_mun_per_block <- 100
  
  # Split the municipalities into blocks of size max_mun_per_block
  blocks <- split(cd_mun, ceiling(seq_along(cd_mun) / max_mun_per_block))
  
  # Iterate over the years in the specified range
  for (year in year_list) {  
    print(year) # Log the current year being processed
    
    # Initialize an empty list for the current year's data
    year_data_list <- list()
    
    # Iterate over blocks of municipalities
    for (block in blocks) {
      # Flatten the block list to a vector
      block <- unlist(block)
      
      # Construct the API URL for the current block and year
      api_url <- paste0(
        "https://apisidra.ibge.gov.br/values/t/3939/n6/",  # Endpoint for PPM data
        paste(block, collapse = ","),                     # Municipality codes
        "/v/all",                                         # Request all variables
        "/p/", year,                                      # Specify the year
        "/c79/all"                                        # Include all classifications (e.g., species)
      )
      
      # Make the GET request to the SIDRA API
      response <- httr::GET(api_url)
      
      # Check if the API request was successful
      if (response$status_code != 200) {
        warning(paste("Failed to retrieve data for block of municipalities in year", year))
        next
      }
      
      # Parse the JSON response content
      data_content <- httr::content(response, as = "text")
      json_data <- rjson::fromJSON(data_content)
      
      # Convert the JSON response to a data.table if it contains valid data
      if (length(json_data) > 1) {  # Check if the JSON has rows of data
        data_df <- as.data.table(do.call("rbind", json_data))
        
        # Use the first row as column names
        setnames(data_df, unlist(data_df[1, ]))
        
        # Remove the first row (header row)
        data_df <- data_df[-1, ]
        
        # Add a column for the year
        data_df[, year := year]
        
        # Add the current block's data to the year's list
        year_data_list[[length(year_data_list) + 1]] <- data_df
      }
    }
    
    # Combine all data.tables for the current year
    year_data <- rbindlist(year_data_list, use.names = TRUE, fill = TRUE)
    
    # Add the year's data to the overall list
    list_of_data[[length(list_of_data) + 1]] <- year_data
  }
  
  # Combine all yearly data into a single data.table
  final_data <- rbindlist(list_of_data, use.names = TRUE, fill = TRUE)
  
  # Determine the file name based on the years provided
  if (length(year_list) == 1) {
    # Single year: include only the year in the file name
    rds_file_name_final <- paste0("PPM_data_", "livestock", "_", year_list, ".rds")
  } else {
    # Multiple years: include the range in the file name
    year_start <- min(year_list)
    year_end <- max(year_list)
    rds_file_name_final <- paste0("PPM_data_", "livestock", "_", year_start, "_to_", year_end, ".rds")
  } 
  
  # Save the final aggregated data to an RDS file
  saveRDS(final_data, file = rds_file_name_final)
  
  # Return the final data.table
  return(final_data)
}
