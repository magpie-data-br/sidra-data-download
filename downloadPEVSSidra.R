#' Download Agricultural Data from SIDRA API (PEVS) for Multiple Municipalities
#'
#' This function retrieves agricultural production data from IBGE's SIDRA API (PEVS) 
#' for a specified list of municipalities over a given time period.
#'
#' @param year_list A vector of integers representing the years for which data will be retrieved (e.g., c(1998, 2000, 2005) or year_list <- seq(from = start_year, to = end_year, by = 1)). As of November 2024, the latest year with available PAM data is 2023.
#'
#' @return A data.table containing agricultural production data for the specified municipalities and years.
#' @examples
#' sidra_data <- downloadPEVSSidra(1998) 
#' sidra_data <- downloadPEVSSidra(c(1998,2002))
#' yearlist <- seq(from = 2000, to = 2020, by = 5)
#' sidra_data <- downloadPEVSSidra(yearlist) 
#' head(sidra_data)
#'
# Load municipality codes from a pre-saved RDS file
cd_mun <- readRDS("data/br_cd_mun.rds")

# Function to download PEVS data
downloadPEVSSidra <- function(year_list) {
  
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
  
  # List to store data for all years and municipalities
  list_of_data <- list()
  
  # Define the block size to split municipality requests
  max_mun_per_block <- 100
  blocks <- split(cd_mun, ceiling(seq_along(cd_mun) / max_mun_per_block))
  
  # Loop over each year
  for (year in year_list) {  
    print(year)  # Print the current year being processed
    
    # Initialize a list to store data for the current year
    year_data_list <- list()
    
    # Loop over each block of municipalities
    for (block in blocks) {
      # Flatten the block to a simple vector
      block <- unlist(block)
      
      # Construct the API URL
      api_url <- paste0(
        "https://apisidra.ibge.gov.br/values/t/291/n6/",
        paste(block, collapse = ","),  # List of municipality codes
        "/v/142",                      # Specific variable code for PEVS
        "/p/", year,                   # Year of interest
        "/c194/all"                    # Include all classifications
      )
      
      # Send GET request to the API
      response <- httr::GET(api_url)
      
      # Check if the request was successful
      if (response$status_code != 200) {
        warning(paste("Failed to retrieve data for block of municipalities in year", year))
        next
      }
      
      # Parse the JSON response
      data_content <- httr::content(response, as = "text")
      json_data <- rjson::fromJSON(data_content)
      
      # Convert valid JSON data into a data.table
      if (length(json_data) > 1) {
        data_df <- as.data.table(do.call("rbind", json_data))
        
        # Set column names from the first row
        setnames(data_df, unlist(data_df[1, ]))
        
        # Remove the first row (headers)
        data_df <- data_df[-1, ]
        
        # Add a year column to the data
        data_df[, year := year]
        
        # Append to the current year's data list
        year_data_list[[length(year_data_list) + 1]] <- data_df
      }
    }
    
    # Combine all data for the current year
    year_data <- rbindlist(year_data_list, use.names = TRUE, fill = TRUE)
    
    # Append yearly data to the overall list
    list_of_data[[length(list_of_data) + 1]] <- year_data
  }
  
  # Combine data for all years into a single data.table
  final_data <- rbindlist(list_of_data, use.names = TRUE, fill = TRUE)
  
  if (length(year_list) == 1) {
    # Single year: include only the year in the file name
    rds_file_name_final <- paste0("PEVS_data_", "production", "_", year_list, ".rds")
  } else {
    # Multiple years: include the range in the file name
    year_start <- min(year_list)
    year_end <- max(year_list)
    rds_file_name_final <- paste0("PEVS_data_", "production", "_", year_start, "_to_", year_end, ".rds")
  }   
  # Save the combined data as an RDS file
  saveRDS(final_data, file = rds_file_name_final)
  
  # Return the aggregated data
  return(final_data)
}
