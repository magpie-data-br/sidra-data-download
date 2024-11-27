#' Download Agricultural Data from SIDRA API (PPM) for Multiple Municipalities
#'
#' This function downloads data related to livestock inventory from IBGE's SIDRA API (PPM) 
#' for a predefined list of municipalities. The data covers the period from 1998 onwards.
#'
#' @param start_year An integer representing the start year for the data retrieval.
#' @param end_year An integer representing the end year for the data retrieval. As of November 2024, the latest year with available PPM data is 2023.
#'
#' @return A data.table containing the livestock data for all municipalities.
#' @examples
#' sidra_data <- downloadPPMSidra(1998, 2022)
#' head(sidra_data)
#'

# Load the municipality codes from an RDS file
# Ensure this file contains valid municipality codes for the analysis
cd_mun <- readRDS("data/br_cd_mun.rds")

downloadPPMSidra <- function(start_year, end_year) {
  
  # Create a list of years from start_year to end_year
  year_list <- seq(from = start_year, to = end_year, by = 1)
  
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
  
  # Define the filename for saving the data
  rds_file_name_final <- paste0("PPM_data_", "livestock",  ".rds")
  
  # Save the final aggregated data to an RDS file
  saveRDS(final_data, file = rds_file_name_final)
  
  # Return the final data.table
  return(final_data)
}
