# IBGE SIDRA Data Downloader

This repository provides R scripts for downloading agricultural data from **IBGE SIDRA API**, covering three datasets:  
1. **PAM (Produção Agrícola Municipal)** - Municipal Agricultural Production  
2. **PPM (Produção Pecuária Municipal)** - Municipal Livestock Production  
3. **PEVS (Pesquisa da Extração Vegetal e Silvicultura)** - Survey on Plant Extraction and Forestry  

Each dataset can be downloaded for multiple municipalities over a specified range of years. The scripts efficiently handle API limitations by splitting requests into manageable blocks and output the data in a clean format for further analysis.

---

## Features

- Supports downloading data from IBGE SIDRA API for PAM, PPM, and PEVS datasets.
- Handles multiple years of data (from 1998 onwards).
- Automatically splits requests into blocks to avoid API size limitations.
- Saves the output in `.rds` files for each dataset.
- Flexible and easy-to-use functions for bulk data retrieval.

---

## Getting Started

### Prerequisites

Before using these scripts, ensure that you have the following:
- **R** installed (version 4.0 or higher recommended).
- R libraries:
  - `httr`
  - `rjson`
  - `data.table`
- A pre-saved RDS file with municipality codes (`cd_mun`), named `br_cd_mun.rds`. This file must be located in the `data/` directory.

---

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ibge-sidra-data-downloader.git
   cd ibge-sidra-data-downloader
   ```

2. Open the R scripts (downloadPAMSidra.R, downloadPPMSidra.R, downloadPEVSSidra.R) in your preferred R environment.

3. Install the required R packages:
  ```bash
    install.packages(c("httr", "rjson", "data.table"))
   ```


---
###  Usage
Each function downloads data for a specific dataset. Examples for using these functions are provided below.

### 1. PAM: Municipal Agricultural Production
Download data for crop production by municipality:

  ```bash
     # Load the function
        source("downloadPAMSidra.R")

      # Download data for the years 2000 to 2023

      # Preview the first rows
      head(pam_data)

      # The data is saved automatically as 'PAM_data_crop_production.rds'
  ```

###  2. PPM: Municipal Livestock Production
Download data for livestock population by municipality:

  ```bash
      # Load the function
        source("downloadPPMSidra.R")
  
      # Download data for the years 2005 to 2023
        ppm_data <- downloadPPMSidra(2005, 2023)

      # Preview the first rows
        head(ppm_data)

      # The data is saved automatically as 'PPM_data_livestock.rds'
  ```

### 3. PEVS: Survey on Plant Extraction and Forestry
Download data for plant extraction and forestry production:

  ```bash
      # Load the function
        source("downloadPEVSSidra.R")

      # Download data for the years 1998 to 2022
        pevs_data <- downloadPEVSSidra(1998, 2022)

      # Preview the first rows
        head(pevs_data)

      # The data is saved automatically as 'PEVS_data_production.rds'
  ```
---
###  Outputs
Each function generates:

A combined dataset as an R data.table object.
A saved .rds file with the following naming conventions:
PAM: PAM_data_crop_production.rds
PPM: PPM_data_livestock.rds
PEVS: PEVS_data_production.rds
These files are saved in the working directory.

---
### Contact
For questions or feedback, reach out via:

Email: mascarabello@gmail.com
