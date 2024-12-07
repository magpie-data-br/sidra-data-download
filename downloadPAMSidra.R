#' Download Agricultural Data from SIDRA API (PAM) for Multiple Municipalities
#'
#' This function downloads data related to agricultural production (area harvested, area planted, 
#' production, and average yield) for both permanent and temporary crops from IBGE's SIDRA API (PAM) 
#' for a predefined list of municipalities. The data covers the period from 1998 onwards.
#'
#' @param variable A string representing the SIDRA variable code. Possible values are 'planted_area', 'harvested_area', 'production', 'average_yield'.
#' @param year_list A vector of integers representing the years for which data will be retrieved (e.g., c(1998, 2000, 2005) or year_list <- seq(from = start_year, to = end_year, by = 1)). As of November 2024, the latest year with available PAM data is 2023.
#'
#' @return A data.table containing the agricultural data for all municipalities.
#' @examples
#' sidra_data <- downloadPAMSidra('planted_area', 1998)
#' sidra_data <- downloadPAMSidra('harvested_area',c(1998,2002))
#' yearlist <- seq(from = 2000, to = 2020, by = 5)
#' sidra_data <- downloadPAMSidra('production',yearlist) 
#' head(sidra_data)
#'

# Load the municipality codes from the RDS file
cd_mun <- readRDS("data/br_cd_mun.rds")

downloadPAMSidra <- function(variable, year_list) {
  
  # Define valid variables for PAM (Permanent and Temporary Crops)
  var_codes <- c(planted_area = '8331', harvested_area = '216', production = '214', average_yield = '112')
  
  # Check if the provided variable is valid
  if (!variable %in% names(var_codes)) {
    stop("Invalid variable. Please choose from: 'planted_area', 'harvested_area', 'production', 'average_yield'.")
  }
  
  # Get the variable code from the selected variable
  var_code <- var_codes[[variable]]
  
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
  
  # Initialize a list to store data.tables
  list_of_data <- list()
  
  #Set block size to download the data
  max_mun_per_block <- 100
  blocks <- split(cd_mun, ceiling(seq_along(cd_mun) / max_mun_per_block))
  
  # Iterate over the list of years
  for (year in year_list) {  
    print(year)
    
    # Initialize an empty list for the current year's data
    year_data_list <- list()
    
    # Download por blocos 
    for (block in blocks) {
      # Unlist the block to avoid issues with list notation in the URL
      block <- unlist(block)
      
      # Create the API URL
      api_url <- paste0(
        "https://apisidra.ibge.gov.br/values/t/5457/n6/",
        paste(block, collapse = ","), 
        "/v/", var_code, "/p/", year, "/c782/all"
      )

      # Make the GET request to the SIDRA API
      response <- httr::GET(api_url)
      
      # Check if the request was successful
      if (response$status_code != 200) {
        warning(paste("Failed to retrieve data for block of municipalities in year", year))
        next
      }
      
      # Parse the JSON response content
      data_content <- httr::content(response, as = "text")
      json_data <- rjson::fromJSON(data_content)
      
      # Convert the JSON data into a data.table if it is valid
      if (length(json_data) > 1) {
        data_df <- as.data.table(do.call("rbind", json_data))
        
        # Set the column names to the first row
        setnames(data_df, unlist(data_df[1, ]))
        
        # Remove the first row (header row)
        data_df <- data_df[-1, ]
        
        # Add a column for the year
        data_df[, year := year]
        
        # Append the data.table to the year's list
        year_data_list[[length(year_data_list) + 1]] <- data_df
      }
    }
    
    # Combine the year's data into a single data.table
    year_data <- rbindlist(year_data_list, use.names = TRUE, fill = TRUE)
    
    # Append the yearly data to the overall list of data
    list_of_data[[length(list_of_data) + 1]] <- year_data
  }
  
  # Combine all data.tables into a single data.table
  final_data <- rbindlist(list_of_data, use.names = TRUE, fill = TRUE)
  
  # Determine the file name based on the years provided
  if (length(year_list) == 1) {
    # Single year: include only the year in the file name
    rds_file_name_final <- paste0("PAM_data_", variable, "_", year_list, ".rds")
  } else {
    # Multiple years: include the range in the file name
    year_start <- min(year_list)
    year_end <- max(year_list)
    rds_file_name_final <- paste0("PAM_data_", variable, "_", year_start, "_to_", year_end, ".rds")
  }  
  
  saveRDS(final_data, file = rds_file_name_final)
  
  # Return the aggregated data
  return(final_data)
}
