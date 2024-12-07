# Example Script for Using the SIDRA Data Download Functions

# This script demonstrates how to use the data download functions available in the repository.
# It includes downloading data from the Municipal Agricultural Production (PAM), Municipal Livestock Production (PPM),
# and Forestry Production (PEVS) databases via IBGE's SIDRA API.

rm(list=ls())


# -----------------------------------
# Step 1: Install and Load Necessary Libraries
# -----------------------------------

# List of required packages
required_packages <- c("httr", "rjson", "data.table")

# Identify missing packages
missing_packages <- setdiff(required_packages, installed.packages()[, "Package"])

# Install missing packages
if (length(missing_packages) > 0) {
  message("Installing required packages...")
  install.packages(missing_packages)
} else {
  message("All required packages are already installed.")
}

# Load the required libraries
library(httr)
library(rjson)
library(data.table)


# -----------------------------------
# Step 2: Load the Download Functions
# -----------------------------------
source("downloadPAMSidra.R")
source("downloadPPMSidra.R")
source("downloadPEVSSidra.R")

# -----------------------------------
# Step 3: Define the Years for Data Retrieval
# -----------------------------------
yearList <- seq(from = 1998, to = 2023, by = 1)


# -----------------------------------
# Step 4: Download Data for PAM 
# -----------------------------------

# Example 1: Download data for planted area (PAM)
pam_data <- downloadPAMSidra('planted_area',yearList)

# Example 2: Download data for harvested area (PAM)
pam_data <- downloadPAMSidra('harvested_area',yearList)

# Example 3: Download data for production (PAM)
pam_data <- downloadPAMSidra('production',yearList)

# -----------------------------------
# Step 5: Download Data for PPM 
# -----------------------------------

# Download data for livestock
ppm_data <- downloadPPMSidra(yearList)

# -----------------------------------
# Step 6: Download Data for PEVS (Forestry)
# -----------------------------------

# Download data for PEVS
pevs_data <- downloadPEVSSidra(yearList)


# -----------------------------------
# Notes:
# - Each function automatically saves the downloaded data in .rds format in the current working directory.
# - The file names include the variable, start year, and end year (e.g., PAM_data_planted_area_1998_2023.rds).
# - Modify the variable or year list as needed for your specific use case.
# -----------------------------------
